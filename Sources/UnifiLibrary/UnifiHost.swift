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
    let hostRetriever: UnifiHostRetriever
    let requestInterval: TimeInterval
    let refreshInterval: TimeInterval

    lazy var staleTime: TimeInterval = max(refreshInterval - (requestInterval * 1.1), 0.0)
    var staleDate: Date { Date().addingTimeInterval(-staleTime) }

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

    private var clientCache: [String: ClientCacheEntry] = [:]

    struct DeviceCacheEntry: Sendable, Hashable, Equatable
    {
        let device: UnifiDevice
        let lastUpdate: Date
    }

    private var deviceCache: [String: DeviceCacheEntry] = [:]

    public var lastUpdateOldDevices: Date = .distantPast
    public var lastUpdateDeviceDetails: Date = .distantPast

    public var shouldRefreshOldDevices: Bool { lastUpdateOldDevices < Date() - refreshInterval }
    public var shouldRefreshDevicedetails: Bool { lastUpdateDeviceDetails < Date() - refreshInterval }

    public init(host: String, apiKey: String, siteId: String?, requestInterval: TimeInterval = 60.0, refreshInterval: TimeInterval = 120.0, limit: Int = 100_000, timeout: TimeAmount = .seconds(5)) async throws
    {
        hostRetriever = try await UnifiHostRetriever(host: host, apiKey: apiKey, siteId: siteId, limit: limit, httpTimeout: timeout)
        self.requestInterval = requestInterval
        self.refreshInterval = refreshInterval
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
                        group.addTask { try? await Task.sleep(nanoseconds: UInt64(self.requestInterval * Double(NSEC_PER_SEC))) }
                    }
                })
            JLog.debug("Refreshed:\(Date()) requestInterval:\(requestInterval)")
        }
    }

    public var networks: Set<IPv4Network>
    {
        Set(oldDevices.compactMap(\.networks).joined())
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
    func updateOldDevices() async throws
    {
        let retrievedDevices = try await hostRetriever.oldDevices()

        if retrievedDevices != oldDevices || shouldRefreshOldDevices
        {
            oldDevices = retrievedDevices
            lastUpdateOldDevices = Date()
        }
    }

    func updateClients() async throws
    {
        let retrievedClients = try await hostRetriever.clients()

        var newClientSet = Set<UnifiClient>()
        var knownCounter = 0

        for client in retrievedClients
        {
            if let cacheEntry = clientCache[client.macAddress]
            {
                knownCounter += 1
                guard cacheEntry.lastUpdate < staleDate else { continue }
                guard !cacheEntry.client.isEqual(to: client) else { continue }
            }
            newClientSet.insert(client)
            clientCache[client.macAddress] = ClientCacheEntry(client: client, lastUpdate: Date())
        }
        clientCache = clientCache.filter { $0.value.lastUpdate > staleDate }

        JLog.debug("Refresh got clients:\(retrievedClients.count) cache:\(clientCache.count) newClientSet:\(newClientSet.count) old clients:\(clients.count) known:\(knownCounter)")
        JLog.debug("new clients \(newClientSet.map(\.name).sorted().joined(separator: ","))")

        if !newClientSet.isEmpty
        {
            clients = newClientSet
        }
    }

    func updateDevices() async throws
    {
        let retrievedDevices = try await hostRetriever.devices()

        var newDevicesSet = Set<UnifiDevice>()
        var knownCounter = 0

        for device in retrievedDevices
        {
            if let cacheEntry = deviceCache[device.macAddress]
            {
                knownCounter += 1
                guard cacheEntry.lastUpdate < staleDate else { continue }
                guard !cacheEntry.device.isEqual(to: device) else { continue }
            }
            newDevicesSet.insert(device)
            deviceCache[device.macAddress] = DeviceCacheEntry(device: device, lastUpdate: Date())
        }
        deviceCache = deviceCache.filter { $0.value.lastUpdate > staleDate }
        JLog.debug("Refresh got devices:\(retrievedDevices.count) cache:\(deviceCache.count) newDeviceSet:\(newDevicesSet.count) old devices:\(devices.count) known:\(knownCounter)")
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
                let retrievedDetails = try await hostRetriever.deviceDetails(for: device)
                newDeviceDetails.insert(retrievedDetails)
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
