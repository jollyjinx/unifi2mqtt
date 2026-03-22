import ArgumentParser
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HetznerDynDNS
import JLog
import MQTTNIO
import NIOPosix

extension JLog.Level: @retroactive ExpressibleByArgument {}
#if DEBUG
    let defaultLoglevel: JLog.Level = .debug
#else
    let defaultLoglevel: JLog.Level = .notice
#endif

@main
@MainActor
struct unifimqtt2dns: AsyncParsableCommand
{
    @Option(help: "Set the log level.") var logLevel: JLog.Level = defaultLoglevel

    @Option(name: .long, help: "MQTT Server hostname") var mqttHostname: String = "mqtt"
    @Option(name: .long, help: "MQTT Server port") var mqttPort: UInt16 = 1883
    @Option(name: .long, help: "MQTT Server username") var mqttUsername: String = "mqtt"
    @Option(name: .long, help: "MQTT Server password") var mqttPassword: String = ""

    #if DEBUG
        @Option(name: .long, help: "MQTT topic filter to subscribe to.") var mqttTopicFilter: String = "example/unifi/hostsbynetwork/+/+"
    #else
        @Option(name: .long, help: "MQTT topic filter to subscribe to.") var mqttTopicFilter: String = "unifi/hostsbynetwork/+/+"
    #endif

    @Option(name: .long, help: "Hetzner DNS zone name or zone id. This can also be provided via the HETZNER_ZONE_IDENTIFIER environment variable.") var hetznerZoneIdentifier: String = ProcessInfo.processInfo.environment["HETZNER_ZONE_IDENTIFIER"] ?? ""
    @Option(name: .long, help: "Hetzner API token. This can also be provided via the HETZNER_API_TOKEN environment variable.") var hetznerAPIToken: String = ProcessInfo.processInfo.environment["HETZNER_API_TOKEN"] ?? ""
    @Option(name: .long, help: "Optional zone name used to normalize FQDN MQTT hostnames before the TTL lookup.") var hetznerZoneName: String = ""

    @Option(name: .long, help: "Minimum seconds between Hetzner update attempts for the same hostname.") var hostUpdateCooldown: TimeInterval = 600
    @Option(name: .long, help: "How long TTL=60 eligibility is cached per hostname.") var hetznerRecordRefreshInterval: TimeInterval = 86_400
    @Option(name: .long, help: "Regular expression for the client IPv4 addresses that are allowed to update DNS.") var allowedIPRegex: String = #"^(?:192\.168\.(?:1|2)|10\.(?:98|112)\.\d+|172\.16\.(?:98|112))\.1\d\d$"#

    func run() async throws
    {
        JLog.loglevel = logLevel

        guard !hetznerZoneIdentifier.isEmpty else
        {
            throw ValidationError("Hetzner zone identifier not set.\n\n\(Self.helpMessage())")
        }

        guard !hetznerAPIToken.isEmpty else
        {
            throw ValidationError("Hetzner API token not set.\n\n\(Self.helpMessage())")
        }

        let service = try DNSUpdaterService(zoneIdentifier: hetznerZoneIdentifier,
                                            apiToken: hetznerAPIToken,
                                            zoneName: hetznerZoneName,
                                            allowedIPRegex: allowedIPRegex,
                                            updateCooldown: hostUpdateCooldown,
                                            rrsetRefreshInterval: hetznerRecordRefreshInterval)

        while !Task.isCancelled
        {
            let client = MQTTClient(host: mqttHostname,
                                    port: Int(mqttPort),
                                    identifier: ProcessInfo.processInfo.processName,
                                    eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
                                    configuration: .init(userName: mqttUsername, password: mqttPassword))

            do
            {
                try await runClient(client, service: service)
            }
            catch
            {
                JLog.error("MQTT loop failed: \(error)")
            }

            try? await client.shutdown()
            try? await Task.sleep(for: .seconds(5))
        }
    }

    private func runClient(_ client: MQTTClient, service: DNSUpdaterService) async throws
    {
        let listenerName = "\(ProcessInfo.processInfo.processName)-\(UUID().uuidString)"

        client.addPublishListener(named: listenerName)
        { result in
            Task
            {
                await service.handlePublish(result)
            }
        }

        defer
        {
            client.removePublishListener(named: listenerName)
            client.removeCloseListener(named: listenerName)
        }

        _ = try await client.connect()
        JLog.notice("Connected to mqtt://\(mqttHostname):\(mqttPort)")

        let subscriptions = [MQTTSubscribeInfo(topicFilter: mqttTopicFilter, qos: .atMostOnce)]
        _ = try await client.subscribe(to: subscriptions)
        JLog.notice("Subscribed to \(mqttTopicFilter)")

        try await withCheckedThrowingContinuation
        {
            (continuation: CheckedContinuation<Void, Error>) in
            client.addCloseListener(named: listenerName)
            { result in
                switch result
                {
                    case .success:
                        continuation.resume()
                    case let .failure(error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
}

private actor DNSUpdaterService
{
    struct MQTTClientUpdate: Decodable
    {
        let name: String
        let ipAddress: String?
    }

    struct CacheEntry: Sendable
    {
        let isTTL60Record: Bool
        let expiresAt: Date
    }

    struct RRSetEnvelope: Decodable
    {
        let rrset: RRSet
    }

    struct RRSet: Decodable
    {
        let ttl: Int?
    }

    enum RRSetLookupError: Error
    {
        case invalidURL(String)
        case unexpectedResponse
        case httpFailure(Int, String)
    }

    private let zoneIdentifier: String
    private let apiToken: String
    private let zoneName: String?
    private let allowedIPPattern: String
    private let updateCooldown: TimeInterval
    private let rrsetRefreshInterval: TimeInterval
    private let handler = DynDNSHandler()
    private let decoder = JSONDecoder()
    private let apiBaseURL: String

    private var cachedTTL60Eligibility: [String: CacheEntry] = [:]
    private var recentHostIPs: [String: [String: [Date]]] = [:]
    private var hostCooldownUntil: [String: Date] = [:]

    init(zoneIdentifier: String,
         apiToken: String,
         zoneName: String,
         allowedIPRegex: String,
         updateCooldown: TimeInterval,
         rrsetRefreshInterval: TimeInterval) throws
    {
        _ = try NSRegularExpression(pattern: allowedIPRegex)

        self.zoneIdentifier = zoneIdentifier
        self.apiToken = apiToken
        self.zoneName = zoneName.isEmpty ? nil : zoneName.lowercased()
        self.allowedIPPattern = allowedIPRegex
        self.updateCooldown = updateCooldown
        self.rrsetRefreshInterval = rrsetRefreshInterval
        self.apiBaseURL = ProcessInfo.processInfo.environment["HETZNER_API_BASE_URL"] ?? "https://api.hetzner.cloud/v1"
    }

    func handlePublish(_ result: Result<MQTTPublishInfo, Error>) async
    {
        switch result
        {
            case let .failure(error):
                JLog.error("MQTT publish listener failed: \(error)")

            case let .success(message):
                guard let payload = message.payload.getString(at: message.payload.readerIndex, length: message.payload.readableBytes)
                else
                {
                    JLog.error("Could not read mqtt payload from topic \(message.topicName)")
                    return
                }

                await handlePayload(payload, topicName: message.topicName)
        }
    }

    private func handlePayload(_ payload: String, topicName: String) async
    {
        let update: MQTTClientUpdate
        do
        {
            update = try decoder.decode(MQTTClientUpdate.self, from: Data(payload.utf8))
        }
        catch
        {
            JLog.debug("Skipping topic \(topicName): payload is not a unifi client update (\(error))")
            return
        }

        guard let ipAddress = update.ipAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
              !ipAddress.isEmpty
        else
        {
            JLog.debug("Skipping topic \(topicName): missing ipAddress")
            return
        }

        guard isAllowedIPAddress(ipAddress) else
        {
            JLog.trace("Skipping \(update.name): ipAddress \(ipAddress) did not match \(allowedIPPattern)")
            return
        }

        guard let recordName = normalizedRecordName(for: update.name) else
        {
            JLog.trace("Skipping \(update.name): hostname did not match the old Hetzner updater rules")
            return
        }

        do
        {
            guard try await isTTL60Record(recordName) else
            {
                JLog.trace("Skipping \(recordName): Hetzner rrset is not a TTL 60 A record")
                return
            }
        }
        catch
        {
            JLog.error("Could not read Hetzner rrset for \(recordName): \(error)")
            return
        }

        let now = Date()
        remember(ipAddress: ipAddress, for: recordName, now: now)

        let activeIPs = activeIPAddresses(for: recordName, now: now)
        guard activeIPs.count == 1, activeIPs.first == ipAddress else
        {
            JLog.debug("Skipping \(recordName): multiple recent IPs seen (\(activeIPs.sorted().joined(separator: ", ")))")
            return
        }

        if let cooldownUntil = hostCooldownUntil[recordName], cooldownUntil > now
        {
            JLog.trace("Skipping \(recordName): cooldown active until \(cooldownUntil)")
            return
        }
        hostCooldownUntil[recordName] = now.addingTimeInterval(updateCooldown)

        let response = await handler.handle(DynDNSRequest(zoneIdentifier: zoneIdentifier,
                                                          apiToken: apiToken,
                                                          hostname: recordName,
                                                          ipAddress: ipAddress))

        switch response.status
        {
            case .ok:
                JLog.notice("Hetzner update \(recordName): \(response.body)")
            case .notFound:
                cachedTTL60Eligibility[recordName] = CacheEntry(isTTL60Record: false,
                                                                expiresAt: now.addingTimeInterval(rrsetRefreshInterval))
                JLog.error("Hetzner update \(recordName) failed: \(response.body)")
            case .badRequest, .unauthorized, .internalServerError:
                JLog.error("Hetzner update \(recordName) failed: \(response.body)")
        }
    }

    private func isAllowedIPAddress(_ ipAddress: String) -> Bool
    {
        ipAddress.range(of: allowedIPPattern, options: .regularExpression) != nil
    }

    private func normalizedRecordName(for hostname: String) -> String?
    {
        var normalized = hostname
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))

        if let zoneName
        {
            if normalized == zoneName
            {
                normalized = "@"
            }
            else
            {
                let zoneSuffix = ".\(zoneName)"
                if normalized.hasSuffix(zoneSuffix)
                {
                    normalized.removeLast(zoneSuffix.count)
                }
            }
        }

        guard normalized.range(of: #"^[a-z\d-]{3,}$"#, options: .regularExpression) != nil else { return nil }
        return normalized
    }

    private func remember(ipAddress: String, for hostname: String, now: Date)
    {
        pruneHistory(for: hostname, now: now)
        recentHostIPs[hostname, default: [:]][ipAddress, default: []].append(now)
    }

    private func activeIPAddresses(for hostname: String, now: Date) -> [String]
    {
        pruneHistory(for: hostname, now: now)
        return recentHostIPs[hostname, default: [:]]
            .filter { !$0.value.isEmpty }
            .map(\.key)
    }

    private func pruneHistory(for hostname: String, now: Date)
    {
        let discardBefore = now.addingTimeInterval(-3600)
        var hostEntries = recentHostIPs[hostname, default: [:]]

        for (ipAddress, timestamps) in hostEntries
        {
            let retained = timestamps.filter { $0 >= discardBefore }
            if retained.isEmpty
            {
                hostEntries.removeValue(forKey: ipAddress)
            }
            else
            {
                hostEntries[ipAddress] = retained
            }
        }

        if hostEntries.isEmpty
        {
            recentHostIPs.removeValue(forKey: hostname)
        }
        else
        {
            recentHostIPs[hostname] = hostEntries
        }
    }

    private func isTTL60Record(_ hostname: String) async throws -> Bool
    {
        let now = Date()
        if let cachedEntry = cachedTTL60Eligibility[hostname], cachedEntry.expiresAt > now
        {
            return cachedEntry.isTTL60Record
        }

        let rrset = try await fetchRRSet(hostname: hostname)
        let isEligible = rrset?.ttl == 60
        cachedTTL60Eligibility[hostname] = CacheEntry(isTTL60Record: isEligible,
                                                      expiresAt: now.addingTimeInterval(rrsetRefreshInterval))
        return isEligible
    }

    private func fetchRRSet(hostname: String) async throws -> RRSet?
    {
        let urlString = "\(apiBaseURL)/zones/\(encodePathComponent(zoneIdentifier))/rrsets/\(encodePathComponent(hostname))/A"
        guard let url = URL(string: urlString) else
        {
            throw RRSetLookupError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("unifimqtt2dns/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let responseData: Data
        let response: URLResponse
        do
        {
            (responseData, response) = try await URLSession(configuration: .ephemeral).data(for: request)
        }
        catch
        {
            throw RRSetLookupError.httpFailure(-1, error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else
        {
            throw RRSetLookupError.unexpectedResponse
        }

        if httpResponse.statusCode == 404
        {
            return nil
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else
        {
            let body = String(data: responseData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw RRSetLookupError.httpFailure(httpResponse.statusCode, body)
        }

        return try decoder.decode(RRSetEnvelope.self, from: responseData).rrset
    }

    private func encodePathComponent(_ value: String) -> String
    {
        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }
}
