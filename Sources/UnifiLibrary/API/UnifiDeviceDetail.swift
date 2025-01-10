//
//  UnifiDeviceDetail.swift
//

import Foundation

public struct UnifiDeviceDetail: Sendable, Codable
{
    public let id: String
    public let name: String
    public let model: String
    public let macAddress: String
    public let ipAddress: String?
    public let state: UnifiDeviceState
    public let firmwareVersion: String
    public let firmwareUpdatable: Bool
    public let provisionedAt: Date
    public let configurationId: String
    public let uplink: [String: String]?
    public let features: [String: [String: String]]
    public let interfaces: UnifiDeviceInterfaceDetails
}

extension UnifiDeviceDetail: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(macAddress)
    }

    public static func == (lhs: UnifiDeviceDetail, rhs: UnifiDeviceDetail) -> Bool {
        return lhs.macAddress == rhs.macAddress
    }
}

public struct UnifiDeviceInterfaceDetails: Sendable, Codable, Hashable, Equatable
{
    public let radios: [UnifiDeviceRadioDetail]?
    public let ports: [UnifiDevicePortDetail]?
}

public struct UnifiDeviceRadioDetail: Sendable, Codable, Hashable, Equatable
{
    public let wlanStandard: String
    public let frequencyGHz: Double
    public let channelWidthMHz: Int
    public let channel: Int
}

public struct UnifiDevicePortDetail: Sendable, Codable, Hashable, Equatable
{
    public let idx: Int
    public let state: String
    public let connector: String
    public let maxSpeedMbps: Int
    public let speedMbps: Int?
}
