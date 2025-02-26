//
//  UnifiClient.swift
//

import Foundation
import JLog

public struct UnifiClient: Sendable
{
    public let type: UnifiClientType
    public let id: UUID
    public let name: String
    public let connectedAt: Date
    public let ipAddress: IPv4.Address?
    public let macAddress: MACAddress

    public let lastSeen: Date? // currently not in json so it will be generated on the fly
}

public extension UnifiClient
{
    func isEqual(to other: UnifiClient) -> Bool
    {
        if type == other.type
            && ipAddress == other.ipAddress
            && id == other.id
            && name == other.name
            && connectedAt == other.connectedAt
            && macAddress == other.macAddress
        {
            return true
        }
        return false
    }
}

extension UnifiClient: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(macAddress)
    }

    public static func == (lhs: UnifiClient, rhs: UnifiClient) -> Bool
    {
        return lhs.macAddress == rhs.macAddress
    }
}

extension UnifiClient: Codable
{
    public init(from decoder: Decoder) throws
    {
        do
        {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            type = try container.decode(UnifiClientType.self, forKey: .type)
            id = try container.decode(UUID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            connectedAt = try container.decode(Date.self, forKey: .connectedAt)
            ipAddress = try? container.decode(IPv4.Address.self, forKey: .ipAddress)
            macAddress = try container.decode(MACAddress.self, forKey: .macAddress)

            lastSeen = (try? container.decode(Date.self, forKey: .lastSeen)) ?? Date()
        }
        catch
        {
            JLog.error("Error decoding UnifiClient: \(error)")
            throw error
        }
    }
}
