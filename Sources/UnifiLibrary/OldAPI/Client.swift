//
//  Client.swift
//

import Foundation

public struct Client: Codable, Sendable, Hashable, Equatable
{
    public let last_ip: String
    public let first_seen: Date
    public let last_seen: Date
    public let mac: String
    public let network_id: String
    public let hostname: String
    public let oui: String
    public let name: String
}
