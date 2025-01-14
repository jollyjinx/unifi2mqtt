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

    public let ip: IPv4.Address
    public let startup_timestamp: Date?
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
