//
//  UnifiClient.swift
//

import Foundation

public struct UnifiDevice: Sendable, Codable, Hashable, Equatable
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

public enum UnifiDeviceState: String, Codable, Sendable
{
    case online = "ONLINE"
    case offline = "OFFLINE"
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
}
