//
//  UnifiDevice.swift
//

import Foundation

public struct UnifiDevice: Sendable, Codable
{
    public let id: String
    public let name: String
    public let model: String
    public let macAddress: String
    public let ipAddress: String?
    public let state: UnifiDeviceState
    public let features: Set<UnfiDeviceFeatures>
    public let interfaces: Set<UnifiDeviceInterfaceType>
}
extension UnifiDevice: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(macAddress)
    }

    public static func == (lhs: UnifiDevice, rhs: UnifiDevice) -> Bool {
        return lhs.macAddress == rhs.macAddress
    }
}

public enum UnifiDeviceState: String, Codable, Sendable
{
    case online = "ONLINE"
    case offline = "OFFLINE"
    case pendingAdoption = "PENDING_ADOPTION"
    case updating = "UPDATING"
    case gettingReady = "GETTING_READY"
    case adopting = "ADOPTING"
    case deleting = "DELETING"
    case connectionInterrupted = "CONNECTION_INTERRUPTED"
    case isolated = "ISOLATED"
}

public enum UnfiDeviceFeatures: String, Codable, Sendable
{
    case accesspoint = "accessPoint"
    case switching
}

public enum UnifiDeviceInterfaceType: String, Codable, Sendable
{
    case radios
    case ports
    case gateway
}
