//
//  UnifiDevice.swift
//

import Foundation
import JLog

public struct UnifiDevice: Sendable, Codable
{
    public let id: UUID
    public let name: String
    public let model: String
    public let macAddress: MACAddress
    public let ipAddress: String?
    public let state: UnifiDeviceState
    public let features: Set<UnfiDeviceFeatures>
    public let interfaces: Set<UnifiDeviceInterfaceType>
}

extension UnifiDevice: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(macAddress)
    }

    public static func == (lhs: UnifiDevice, rhs: UnifiDevice) -> Bool
    {
        return lhs.macAddress == rhs.macAddress
    }
}

public extension UnifiDevice
{
    func isEqual(to other: UnifiDevice) -> Bool
    {
        if id == other.id
            && name == other.name
            && model == other.model
            && macAddress == other.macAddress
            && ipAddress == other.ipAddress
            && state == other.state
            && features == other.features
            && interfaces == other.interfaces
        {
            return true
        }
        return false
    }
}
