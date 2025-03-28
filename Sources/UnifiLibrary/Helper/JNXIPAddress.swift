//
//  JNXIPAddress.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 28.03.25.
//


import Foundation

public enum JNXIPAddress : Sendable, Codable
{
    case ipv4(IPv4.Address)
    case ipv6(IPv6.Address)
}

// custom string convertible
extension JNXIPAddress: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .ipv4(let address): return address.description
        case .ipv6(let address): return address.description
        }
    }
}

// decodable
public extension JNXIPAddress
{
    init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        if let address = try? container.decode(IPv4.Address.self)
        {
            self = .ipv4(address)
        }
        else if let address = try? container.decode(IPv6.Address.self)
        {
            self = .ipv6(address)
        }
        else
        {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid IP address")
        }
    }
}

// encodable
public extension JNXIPAddress
{
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        switch self
        {
        case .ipv4(let address): try container.encode(address)
        case .ipv6(let address): try container.encode(address)
        }
    }
}


// equatable
extension JNXIPAddress: Equatable
{
    public static func == (lhs: JNXIPAddress, rhs: JNXIPAddress) -> Bool
    {
        switch (lhs, rhs)
        {
        case (.ipv4(let l), .ipv4(let r)): return l == r
        case (.ipv6(let l), .ipv6(let r)): return l == r
        default: return false
        }
    }
}
