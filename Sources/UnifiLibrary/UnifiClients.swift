//
//  UnifiClients.swift
//

import Foundation

public struct UnifiClientResponse: Codable, Sendable, Hashable, Equatable
{
    let offset: Int
    let limit: Int
    let count: Int
    let totalCount: Int
    let data: [UnifiClient]
}

public struct UnifiClient: Codable, Sendable, Hashable, Equatable
{
    let type: UnifiClientType
    let id: String
    let name: String
    let connectedAt: Date
    let ipAddress: String?
    let macAddress: String
//    let uplinkDeviceId: String
//    let isGuest: Bool
}

public enum UnifiClientType: String, Codable, Sendable
{
    case wired = "WIRED"
    case wireless = "WIRELESS"
    case vpn = "VPN"
    case teleport = "TELEPORT"
}
