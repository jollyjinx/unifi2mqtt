//
//  Client.swift
//

import Foundation

public struct Client: Codable, Sendable{
    public let last_ip: String
    public let first_seen: Date
    public let last_seen: Date
    public let mac: String
    public let network_id: String
    public let hostname: String
    public let oui: String
    public let name: String
}

extension Client: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(mac)
    }

    public static func == (lhs: Client, rhs: Client) -> Bool {
        return lhs.mac == rhs.mac
    }
}
