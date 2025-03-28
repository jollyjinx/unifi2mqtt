//
//  IPv4Network.swift
//

import Foundation

public enum IPv4
{
    public struct Netmask: Sendable, Hashable, CustomStringConvertible
    {
        public let prefixlength: UInt8

        public var description: String { String(prefixlength) }
    }

    public struct Address: Sendable, Hashable, CustomStringConvertible
    {
        public let bits: UInt32

        public var description: String { IPv4.addressIntToString(bits) }
    }

    public struct Network: Sendable, Hashable, CustomStringConvertible
    {
        public let address: Address
        public let netmask: Netmask

        public var gateway: Address { address }
        public var network: Network { Network(address: Address(bits: address.bits & netmask.bits), netmask: netmask) }
        public var description: String { "\(address)/\(netmask)" }
    }
}

public extension IPv4.Netmask
{
    init(bitmask: UInt32)
    {
        prefixlength = UInt8(32 - bitmask.leadingZeroBitCount)
    }

    init?(_ string: String)
    {
        if string.count > 2
        {
            guard let bitmask = IPv4.addressStringToInt(string) else { return nil }
            self.init(bitmask: bitmask)
        }
        else
        {
            guard let number = UInt8(string) else { return nil }
            self.init(prefixlength: number)
        }
    }

    var bits: UInt32 { ~UInt32(0) << (32 - prefixlength) }
}

public extension IPv4.Address
{
    init?(_ string: String)
    {
        guard let bits = IPv4.addressStringToInt(string) else { return nil }
        self.init(bits: bits)
    }
}

public extension IPv4.Network
{
    init?(_ cidrString: String)
    {
        let components = cidrString.split(separator: "/")
        guard components.count == 2 else { return nil }

        guard let address = IPv4.Address(String(components[0])),
              let netmask = IPv4.Netmask(String(components[1]))
        else { return nil }

        self.address = address
        self.netmask = netmask
    }

    func contains(_ testAddress: IPv4.Address) -> Bool
    {
        testAddress.bits & netmask.bits == address.bits & netmask.bits
    }
}

public extension IPv4
{
    static func addressStringToInt(_ addressString: String) -> UInt32?
    {
        let components = addressString.split(separator: ".").map { UInt8($0) ?? 0 }
        guard components.count == 4 else { return nil }
        let value = components.reduce(0) { sum, component in UInt32(sum) << 8 | UInt32(component) }

        return value
    }

    static func addressIntToString(_ addressInt32: UInt32) -> String
    {
        let byte1 = (addressInt32 >> 24) & 0xFF
        let byte2 = (addressInt32 >> 16) & 0xFF
        let byte3 = (addressInt32 >> 8) & 0xFF
        let byte4 = addressInt32 & 0xFF

        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }
}

extension IPv4.Network: Codable
{
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.singleValueContainer()

        try container.encode("\(address)/\(netmask)")
    }

    public init(from decoder: any Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let cidr = try container.decode(String.self)
        guard let network = IPv4.Network(cidr)
        else
        {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid IPv4 network address \(cidr)")
        }
        self = network
    }
}

extension IPv4.Address: Codable
{
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public init(from decoder: any Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let address = IPv4.Address(value)
        else
        {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid IPv4 address \(value)")
        }
        self = address
    }
}
