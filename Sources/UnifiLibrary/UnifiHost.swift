//
//  UnifiHost.swift
//

import Foundation
import JLog

import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat
import NIOHTTP1

@MainActor
public final class UnifiHost
{
    private let host: String
    private let apiKey: String
    private let siteId: String

    private let requestInterval: TimeInterval
    private let refreshInterval: TimeInterval
    private lazy var staleTime : TimeInterval = { max(refreshInterval - ( requestInterval * 1.1 ), 0.0) }()
    private var staleDate : Date { Date().addingTimeInterval(-staleTime) }

    private let httpTimeout: TimeAmount

    private let clientRequest: HTTPClientRequest
    private let deviceRequest: HTTPClientRequest
    private let oldDeviceRequest: HTTPClientRequest

    private let oldDevicesObservable = Observable<Set<Device>>()
    private let clientsObservable = Observable<Set<UnifiClient>>()
    private let devicesObservable = Observable<Set<UnifiDevice>>()
    private let deviceDetailsObservable = Observable<Set<UnifiDeviceDetail>>()

    public var oldDevices: Set<Device> = []
    {
        didSet { oldDevicesObservable.emit(oldDevices) }
    }

    public var clients: Set<UnifiClient> = []
    {
        didSet { clientsObservable.emit(clients) }
    }

    public var devices: Set<UnifiDevice> = []
    {
        didSet { devicesObservable.emit(devices) }
    }

    public var deviceDetails: Set<UnifiDeviceDetail> = []
    {
        didSet { deviceDetailsObservable.emit(deviceDetails) }
    }

    struct ClientCacheEntry: Sendable, Hashable, Equatable
    {
        let client: UnifiClient
        let lastUpdate: Date
    }
    private var clientCache: [String:ClientCacheEntry] = [:]

    struct DeviceCacheEntry: Sendable, Hashable, Equatable
    {
        let device: UnifiDevice
        let lastUpdate: Date
    }

    private var deviceCache: [String:DeviceCacheEntry] = [:]

    public var lastUpdateOldDevices: Date = .distantPast
    public var lastUpdateDeviceDetails: Date = .distantPast


    public var shouldRefreshOldDevices: Bool { lastUpdateOldDevices < Date() - refreshInterval }
    public var shouldRefreshDevicedetails: Bool { lastUpdateDeviceDetails < Date() - refreshInterval }

    static func findOutDefaultSiteId(host: String, apiKey: String, timeout: TimeAmount = .seconds(5)) async throws -> String
    {
        JLog.debug("Finding default site id")

        var request = HTTPClientRequest(url: "https://\(host)/proxy/network/integrations/v1/sites")
        request.headers.add(name: "X-API-Key", value: apiKey)
        request.headers.add(name: "Accept", value: "application/json")

        let response = try await HTTPClientProvider.sharedHttpClient.execute(request, timeout: timeout)

        guard response.status == .ok else { throw Error.invalidResponse }

        var bodyData = Data()

        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        let siteResponse = try jsonDecoder.decode(UnifiSitesResponse.self, from: bodyData)

        guard let site = siteResponse.data.first(where: { $0.name.lowercased() == "default" }) ?? siteResponse.data.first
        else
        {
            throw Error.invalidResponse
        }
        JLog.debug("Default site id found: \(site.id)")
        return site.id
    }

    public init(host: String, apiKey: String, siteId: String?, requestInterval: TimeInterval = 60.0, refreshInterval: TimeInterval = 120.0, limit: Int = 100_000, timeout: TimeAmount = .seconds(5)) async throws
    {
        if let siteId, !siteId.isEmpty
        {
            self.siteId = siteId
        }
        else
        {
            self.siteId = try await UnifiHost.findOutDefaultSiteId(host: host, apiKey: apiKey, timeout: timeout)
        }

        self.host = host
        self.apiKey = apiKey

        self.requestInterval = requestInterval
        self.refreshInterval = refreshInterval

        httpTimeout = timeout
        var clientRequest = HTTPClientRequest(url: "https://\(host)/proxy/network/integrations/v1/sites/\(self.siteId)/clients?limit=\(limit)")
        clientRequest.headers.add(name: "X-API-Key", value: apiKey)
        clientRequest.headers.add(name: "Accept", value: "application/json")
        self.clientRequest = clientRequest

        var deviceRequest = HTTPClientRequest(url: "https://\(host)/proxy/network/integrations/v1/sites/\(self.siteId)/devices?limit=\(limit)")
        deviceRequest.headers.add(name: "X-API-Key", value: apiKey)
        deviceRequest.headers.add(name: "Accept", value: "application/json")
        self.deviceRequest = deviceRequest

        var oldDeviceRequest = HTTPClientRequest(url: "https://\(host)/proxy/network/api/s/default/stat/device")
        oldDeviceRequest.headers.add(name: "X-API-Key", value: apiKey)
        oldDeviceRequest.headers.add(name: "Accept", value: "application/json")
        self.oldDeviceRequest = oldDeviceRequest
    }

    public func run() async
    {
        while !Task.isCancelled
        {
            try? await withThrowingTimeout(seconds: requestInterval, body:
                {
                    await withTaskGroup(of: Void.self)
                    { group in

                        group.addTask { do { try await self.updateOldDevices() } catch { JLog.error("Error: \(error)") } }

                        if !networks.isEmpty
                        {
                            group.addTask { do { try await self.updateClients() } catch { JLog.error("Error: \(error)") } }
                            group.addTask { do { try await self.updateDevices() } catch { JLog.error("Error: \(error)") } }
                            group.addTask { do { try await self.updateDevicesDetails() } catch { JLog.error("Error: \(error)") } }
                        }
                        group.addTask { try? await Task.sleep(nanoseconds: UInt64(self.requestInterval * 1_000_000_000)) }
                    }
                })
            JLog.debug("Refreshed:\(Date()) requestInterval:\(requestInterval)")
        }
    }

    public func observeOldDevices() -> AsyncStream<Set<Device>>
    {
        oldDevicesObservable.observe()
    }

    public func observeClients() -> AsyncStream<Set<UnifiClient>>
    {
        clientsObservable.observe()
    }

    public func observeDevices() -> AsyncStream<Set<UnifiDevice>>
    {
        devicesObservable.observe()
    }

    public func observeDeviceDetails() -> AsyncStream<Set<UnifiDeviceDetail>>
    {
        deviceDetailsObservable.observe()
    }
}

extension UnifiHost
{
    public enum Error: Swift.Error
    {
        case invalidURL
        case invalidResponse
    }

    func updateOldDevices() async throws
    {
        // update from old device request
        let response = try await HTTPClientProvider.sharedHttpClient.execute(oldDeviceRequest, timeout: httpTimeout)
        guard response.status == .ok else { throw Error.invalidResponse }
        var bodyData = Data()
        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }
        JLog.trace("Got Old Devices: \(String(data: bodyData, encoding: .utf8) ?? "nil")")

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        let deviceResponse = try jsonDecoder.decode(DeviceResponse.self, from: bodyData)

        let newDevicesResponse = Set(deviceResponse.devices)

        if newDevicesResponse != oldDevices || shouldRefreshOldDevices
        {
            oldDevices = newDevicesResponse
            lastUpdateOldDevices = Date()
        }
    }

    public var networks: Set<IPv4Network>
    {
        Set(oldDevices.compactMap(\.networks).joined())
    }


    func updateClients() async throws
    {
        let response = try await HTTPClientProvider.sharedHttpClient.execute(clientRequest, timeout: httpTimeout)
        guard response.status == .ok else { throw Error.invalidResponse }
        var bodyData = Data()
        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }
        JLog.trace("Got clients: \(String(data: bodyData, encoding: .utf8) ?? "nil")")

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        let unifiClientsArray = try jsonDecoder.decode(UnifiClientsResponse.self, from: bodyData).data
        var newClientSet = Set<UnifiClient>()


        var knownCounter = 0
        unifiClientsArray.forEach
        {
            client in

            if let cacheEntry = clientCache[client.macAddress]
            {
                knownCounter += 1
                guard cacheEntry.lastUpdate < staleDate else { return }
                guard !cacheEntry.client.isEqual(to:client) else { return }
            }
            newClientSet.insert(client)
            clientCache[client.macAddress] = ClientCacheEntry(client: client, lastUpdate: Date())
        }
        clientCache = clientCache.filter { $0.value.lastUpdate > staleDate }

        JLog.debug("Refresh got clients:\(unifiClientsArray.count) cache:\(clientCache.count) newClientSet:\(newClientSet.count) old clients:\(clients.count) known:\(knownCounter)")
        JLog.debug("new clients \(newClientSet.map(\.name).sorted().joined(separator: ","))")

        if !newClientSet.isEmpty
        {
            clients = newClientSet
        }
    }

    func updateDevices() async throws
    {
        let response = try await HTTPClientProvider.sharedHttpClient.execute(deviceRequest, timeout: httpTimeout)
        guard response.status == .ok else { throw Error.invalidResponse }
        var bodyData = Data()
        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }
        JLog.trace("Got Devices: \(String(data: bodyData, encoding: .utf8) ?? "nil")")

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        let unifiDevicesArray = try jsonDecoder.decode(UnifiDevicesResponse.self, from: bodyData).data

        var newDevicesSet = Set<UnifiDevice>()
            var knownCounter = 0

        unifiDevicesArray.forEach
        {
            device in

            if let cacheEntry = deviceCache[device.macAddress]
            {
                knownCounter += 1
                guard cacheEntry.lastUpdate < staleDate else { return }
                guard !cacheEntry.device.isEqual(to:device) else { return }
            }
            newDevicesSet.insert(device)
            deviceCache[device.macAddress] = DeviceCacheEntry(device: device, lastUpdate: Date())
        }
        deviceCache = deviceCache.filter { $0.value.lastUpdate > staleDate }
        JLog.debug("Refresh got devices:\(unifiDevicesArray.count) cache:\(deviceCache.count) newDeviceSet:\(newDevicesSet.count) old devices:\(devices.count) known:\(knownCounter)")
        JLog.debug("new devices \(newDevicesSet.map(\.name).sorted().joined(separator: ","))")

        if !newDevicesSet.isEmpty
        {
            devices = newDevicesSet
        }
    }

    func updateDevicesDetails() async throws
    {
        var newDeviceDetails: Set<UnifiDeviceDetail> = []

        for device in devices
        {
            do
            {
                var deviceDetailRequest = HTTPClientRequest(url: "https://\(host)/proxy/network/integrations/v1/sites/\(siteId)/devices/\(device.id)")
                deviceDetailRequest.headers.add(name: "X-API-Key", value: apiKey)
                deviceDetailRequest.headers.add(name: "Accept", value: "application/json")

                let response = try await HTTPClientProvider.sharedHttpClient.execute(deviceDetailRequest, timeout: httpTimeout)
                guard response.status == .ok else { throw Error.invalidResponse }
                var bodyData = Data()
                for try await buffer in response.body
                {
                    bodyData.append(Data(buffer: buffer))
                }
                JLog.trace("Got Devicedetails: \(String(data: bodyData, encoding: .utf8) ?? "nil")")

                let jsonDecoder = JSONDecoder()
                jsonDecoder.dateDecodingStrategy = .iso8601

                do
                {
                    let unifiDeviceDetail = try jsonDecoder.decode(UnifiDeviceDetail.self, from: bodyData)
                    newDeviceDetails.insert(unifiDeviceDetail)
                }
                catch
                {
                    JLog.error("Error: \(error) json: \(String(data: bodyData, encoding: .utf8) ?? "nil")")
                }
            }
            catch
            {
                JLog.error("Error: \(error)")
            }
        }
        if newDeviceDetails != deviceDetails || shouldRefreshDevicedetails
        {
            deviceDetails = newDeviceDetails
            lastUpdateDeviceDetails = Date()
        }
    }
}
