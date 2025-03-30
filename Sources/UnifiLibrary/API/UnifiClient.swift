//
//  UnifiClient.swift
//

import Foundation
import JLog
import RegexBuilder

public struct UnifiClient: Sendable
{
    public let type: UnifiClientType
    public let id: UUID
    public let name: String
    public let connectedAt: Date
    public let ipAddress: JNXIPAddress?
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
            var optionalIpAddress = try? container.decode(JNXIPAddress.self, forKey: .ipAddress)
            macAddress = try container.decode(MACAddress.self, forKey: .macAddress)

            lastSeen = (try? container.decode(Date.self, forKey: .lastSeen)) ?? Date()

            // if no ipaddres but name in form : "p200300c587250f005893916ab88c40e2.dip0.t-ipconnect.de" get ip address from name
            // converts to 2003:00c5:8725:0f00:5893:916a:b88c:40e2
            if optionalIpAddress == nil {
                if let ipv6 = IPv6.Address.fromTOnlineHostname(name) {
                    let ip = JNXIPAddress.ipv6(ipv6)
                    JLog.debug("Converted T-Online hostname to IPv6 address: \(ip)")
                    optionalIpAddress = ip
                }
            }
            ipAddress = optionalIpAddress
        }
        catch
        {
            JLog.error("Error decoding UnifiClient: \(error)")
            throw error
        }
    }
}
