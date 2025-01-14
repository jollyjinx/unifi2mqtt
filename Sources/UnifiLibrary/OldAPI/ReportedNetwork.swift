//
//  ReportedNetwork.swift
//

import Foundation

public struct ReportedNetwork: Sendable, Hashable, Equatable
{
    public let name: String
    public let address: IPv4.Network?
}

public extension ReportedNetwork
{
    var gateway: IPv4.Address? { address?.gateway }
    var network: IPv4.Network? { address?.network }
}

extension ReportedNetwork: Codable
{
    enum DeCodingKeys: String, CodingKey
    {
        case name
        case address
    }

    enum EncodingKeys: String, CodingKey
    {
        case name
        case address
        case gateway // own addition
        case network // own addition
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: DeCodingKeys.self)
        name = try container.decode(String.self, forKey: DeCodingKeys.name)
        address = try? container.decode(IPv4.Network.self, forKey: DeCodingKeys.address)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(name, forKey: EncodingKeys.name)

        try container.encode(address, forKey: EncodingKeys.address)
        try container.encode(gateway, forKey: EncodingKeys.gateway)
        try container.encode(network, forKey: EncodingKeys.network)
    }
}
