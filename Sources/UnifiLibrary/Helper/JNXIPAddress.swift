//
//  JNXIPAddress.swift
//

import Foundation

public enum JNXIPAddress: Sendable, Codable
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
            case let .ipv4(address): return address.description
            case let .ipv6(address): return address.description
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
            case let .ipv4(address): try container.encode(address)
            case let .ipv6(address): try container.encode(address)
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
            case let (.ipv4(l), .ipv4(r)): return l == r
            case let (.ipv6(l), .ipv6(r)): return l == r
            default: return false
        }
    }
}
