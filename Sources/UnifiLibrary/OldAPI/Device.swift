//
//  Device.swift
//

import Foundation

public struct Device: Codable, Sendable
{
    public let model: String
    public let name: String
    public let mac: String
    public let type: DeviceType
    public let serial: String
    public let version: String

    public let ip: String
    public let startup_timestamp: Date
    public let reported_networks: [ReportedNetwork]?
}

extension Device: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(mac)
    }

    public static func == (lhs: Device, rhs: Device) -> Bool
    {
        return lhs.mac == rhs.mac
    }
}

extension Device
{
    var networks: Set<IPv4Network>
    {
        let networks: [IPv4Network] = reported_networks?.compactMap
        {
            guard let address = $0.address else { return nil }
            return IPv4Network(address)
        } ?? []
        return Set(networks)
    }
}

public struct ReportedNetwork: Codable, Sendable, Hashable, Equatable
{
    public let name: String
    public let address: String?
}
