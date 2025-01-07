//
//  UnifiClient.swift
//

import Foundation

public struct UnifiClient: Sendable, Hashable, Equatable
{
    public let type: UnifiClientType
//    public let id: String
    public let name: String
    public let connectedAt: Date
    public let ipAddress: String?
    public let macAddress: String
//    let uplinkDeviceId: String

    public let lastSeen: Date? // currently not in json so it will be generated on the fly
}

extension UnifiClient: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case type
//        case id
        case name
        case connectedAt
        case ipAddress
        case macAddress

        case lastSeen
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(UnifiClientType.self, forKey: .type)
//        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        connectedAt = try container.decode(Date.self, forKey: .connectedAt)
        ipAddress = try? container.decode(String.self, forKey: .ipAddress)
        macAddress = try container.decode(String.self, forKey: .macAddress)

        lastSeen = (try? container.decode(Date.self, forKey: .lastSeen)) ?? Date()
    }
}

public extension UnifiClient
{
    var network: String?
    {
        if let components = ipAddress?.components(separatedBy: "."), components.count == 4
        {
            return components.dropLast().joined(separator: ".").appending(".0")
        }
        else { return nil }
    }
}

public enum UnifiClientType: String, Codable, Sendable
{
    case wired = "WIRED"
    case wireless = "WIRELESS"
    case vpn = "VPN"
    case teleport = "TELEPORT"
}
