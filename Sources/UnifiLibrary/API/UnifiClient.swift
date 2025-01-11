//
//  UnifiClient.swift
//

import Foundation
import JLog

public struct UnifiClient: Sendable
{
    public let type: UnifiClientType
    public let id: String
    public let name: String
    public let connectedAt: Date
    public let ipAddress: String?
    public let macAddress: String

    public let lastSeen: Date? // currently not in json so it will be generated on the fly
}

extension UnifiClient: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(macAddress)
    }

    public static func == (lhs: UnifiClient, rhs: UnifiClient) -> Bool {
        return lhs.macAddress == rhs.macAddress
    }
}

public struct OptionalUnifiClient: Decodable, Sendable
{
    public let unifiClient: UnifiClient?

    public init(from decoder: Decoder) throws {
        do {
            self.unifiClient = try UnifiClient(from: decoder)
        } catch {
            self.unifiClient = nil
            // Log the decoding error
            print("Error decoding UnifiClient: \(error)")
        }
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
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            connectedAt = try container.decode(Date.self, forKey: .connectedAt)
            ipAddress = try? container.decode(String.self, forKey: .ipAddress)
            macAddress = try container.decode(String.self, forKey: .macAddress)

            lastSeen = (try? container.decode(Date.self, forKey: .lastSeen)) ?? Date()
        }
        catch
        {
            JLog.error("Error decoding UnifiClient: \( error)")
            throw error
        }
    }
}

// public extension UnifiClient
// {
//    var network: String?
//    {
//        if let ipAddress
//        {
//            return IPv4Network(ipAddress)?.name
//        }
//        else { return nil }
//    }
// }

public enum UnifiClientType: String, Codable, Sendable
{
    case wired = "WIRED"
    case wireless = "WIRELESS"
    case vpn = "VPN"
    case teleport = "TELEPORT"
}
