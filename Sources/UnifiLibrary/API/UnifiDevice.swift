//
//  UnifiDevice.swift
//

import Foundation
import JLog

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
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(macAddress)
    }

    public static func == (lhs: UnifiDevice, rhs: UnifiDevice) -> Bool
    {
        return lhs.macAddress == rhs.macAddress
    }
}
