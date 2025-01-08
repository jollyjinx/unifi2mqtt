//
//  UnifiHost.swift
//

import Foundation
import JLog

import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat
import NIOHTTP1

@Observable
@MainActor
public final class UnifiHost
{
    private let host: String
    private let apiKey: String
    private let siteId: String
    private let refreshInterval: TimeInterval

    private let clientRequest: HTTPClientRequest
    private let deviceRequest: HTTPClientRequest
    private let oldDeviceRequest: HTTPClientRequest

    private let httpTimeout: TimeAmount

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

    public init(host: String, apiKey: String, siteId: String?, refreshInterval: TimeInterval = 60.0, limit: Int = 100_000, timeout: TimeAmount = .seconds(5)) async throws
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
            await update()
            try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
        }
    }

    public var clients: Set<UnifiClient> = []
    public var devices: Set<UnifiDevice> = []
    public var deviceDetails: Set<UnifiDeviceDetail> = []
    public var networks: Set<IPv4Network> = []

    public var lastUpdate: Date = .distantPast
    public var maximumRefreshInterval: TimeInterval = 30.0

    var shouldRefresh: Bool { lastUpdate < Date() - maximumRefreshInterval }
}

extension UnifiHost
{
    public enum Error: Swift.Error
    {
        case invalidURL
        case invalidResponse
    }

    func update() async
    {
        do
        {
            try await updateNetworks()
        }
        catch
        {
            JLog.error("Error: \(error)")
        }

        do
        {
            try await updateClients()
        }
        catch
        {
            JLog.error("Error: \(error)")
        }
        do
        {
            try await updateDevices()
        }
        catch
        {
            JLog.error("Error: \(error)")
        }
        do
        {
            try await updateDevicesDetails()
        }
        catch
        {
            JLog.error("Error: \(error)")
        }
    }

    func updateNetworks() async throws
    {
        // update from old device request
        let response = try await HTTPClientProvider.sharedHttpClient.execute(oldDeviceRequest, timeout: httpTimeout)
        guard response.status == .ok else { throw Error.invalidResponse }
        var bodyData = Data()
        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        let deviceResponse = try jsonDecoder.decode(DeviceResponse.self, from: bodyData)

        var newNetworks: Set<IPv4Network> = []

        for device in deviceResponse.devices
        {
            guard let networks = device.reported_networks else { continue }
            for network in networks
            {
                if let address = network.address,
                   let network = IPv4Network(address)
                {
                    newNetworks.insert(network)
                }
            }
        }

        if newNetworks != networks || shouldRefresh
        {
            networks = newNetworks
            lastUpdate = Date()
        }
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

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        let unifiClients = try jsonDecoder.decode(UnifiClientsResponse.self, from: bodyData)

        let newClientSet = Set(unifiClients.data)

        if newClientSet != clients || shouldRefresh
        {
            clients = newClientSet
            lastUpdate = Date()
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

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        let unifiDevices = try jsonDecoder.decode(UnifiDevicesResponse.self, from: bodyData)

        let newDeviceSet = Set(unifiDevices.data)
        if newDeviceSet != devices || shouldRefresh
        {
            devices = newDeviceSet
            lastUpdate = Date()
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
        if newDeviceDetails != deviceDetails || shouldRefresh
        {
            deviceDetails = newDeviceDetails
            lastUpdate = Date()
        }
    }
}
