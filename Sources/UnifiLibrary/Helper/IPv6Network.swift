//
//  IPv6Network.swift
//

import Foundation
import JLog

public enum IPv6
{
    public struct Netmask: Sendable, Hashable, CustomStringConvertible
    {
        public let prefixlength: UInt8

        public var description: String { String(prefixlength) }

        init(prefixlength: UInt8)
        {
            self.prefixlength = min(128, prefixlength)
        }
    }

    public struct Address: Sendable, Hashable, CustomStringConvertible
    {
        // 128-bit address represented as two UInt64s
        public let highBits: UInt64
        public let lowBits: UInt64

        public var description: String { IPv6.addressToString(highBits, lowBits) }

        init(highBits: UInt64, lowBits: UInt64)
        {
            self.highBits = highBits
            self.lowBits = lowBits
        }
    }

    public struct Network: Sendable, Hashable, CustomStringConvertible
    {
        public let address: Address
        public let netmask: Netmask

        public var gateway: Address { address }
        public var network: Network
        {
            let (highMask, lowMask) = netmask.bits
            let networkHigh = address.highBits & highMask
            let networkLow = address.lowBits & lowMask
            return Network(address: Address(highBits: networkHigh, lowBits: networkLow), netmask: netmask)
        }

        public var description: String { "\(address)/\(netmask)" }
    }
}

public extension IPv6.Netmask
{
    init?(_ string: String)
    {
        guard let number = UInt8(string), number <= 128 else { return nil }
        self.init(prefixlength: number)
    }

    var bits: (UInt64, UInt64)
    {
        if prefixlength == 0
        {
            return (0, 0)
        }
        else if prefixlength <= 64
        {
            let highMask: UInt64 = prefixlength == 64 ? .max : ~UInt64(0) << (64 - prefixlength)
            return (highMask, 0)
        }
        else
        {
            let lowMask: UInt64 = ~UInt64(0) << (128 - prefixlength)
            return (.max, lowMask)
        }
    }
}

public extension IPv6.Address
{
    init?(_ string: String)
    {
        guard let (high, low) = IPv6.addressStringToInts(string) else { return nil }
        self.init(highBits: high, lowBits: low)
    }
}

public extension IPv6.Network
{
    init?(_ cidrString: String)
    {
        let components = cidrString.split(separator: "/")
        guard components.count == 2 else { return nil }

        guard let address = IPv6.Address(String(components[0])),
              let netmask = IPv6.Netmask(String(components[1]))
        else { return nil }

        self.address = address
        self.netmask = netmask
    }

    func contains(_ testAddress: IPv6.Address) -> Bool
    {
        let (highMask, lowMask) = netmask.bits
        let returnValue = testAddress.highBits & highMask == address.highBits & highMask && testAddress.lowBits & lowMask == address.lowBits & lowMask

        JLog.trace("Network: \(self) contains:\(testAddress) = \(returnValue)")
        return returnValue
    }
}

public extension IPv6
{
    static func addressStringToInts(_ addressString: String) -> (UInt64, UInt64)?
    {
        let parts = addressString.split(separator: "::")
        if parts.count < 1 || parts.count > 2 { return nil }

        let highparts = parts.first!.split(separator: ":")
        let lowparts = parts.last?.split(separator: ":") ?? []

        if highparts.count + lowparts.count > 8 { return nil }

        let missingparts = 8 - highparts.count - lowparts.count
        let expandedParts = highparts + Array(repeating: "0", count: missingparts) + lowparts

        if expandedParts.count != 8 { return nil }

        var highBits: UInt64 = 0
        var lowBits: UInt64 = 0

        for i in 0 ..< 4
        {
            guard let value = UInt16(expandedParts[i], radix: 16) else { return nil }
            highBits = (highBits << 16) | UInt64(value)
        }

        // Process last 4 groups (low 64 bits)
        for i in 4 ..< 8
        {
            guard let value = UInt16(expandedParts[i], radix: 16) else { return nil }
            lowBits = (lowBits << 16) | UInt64(value)
        }

        return (highBits, lowBits)
    }

    static func addressToString(_ highBits: UInt64, _ lowBits: UInt64) -> String
    {
        var segments: [String] = []

        // Process high 64 bits
        for i in (0 ..< 4).reversed()
        {
            let shift = i * 16
            let segment = (highBits >> shift) & 0xFFFF
            segments.append(String(format: "%x", segment))
        }

        // Process low 64 bits
        for i in (0 ..< 4).reversed()
        {
            let shift = i * 16
            let segment = (lowBits >> shift) & 0xFFFF
            segments.append(String(format: "%x", segment))
        }

        // Convert to standard IPv6 notation
        let uncompressedAddress = segments.joined(separator: ":")

        // Compress address
        let compressedAddress = uncompressedAddress.replacingOccurrences(of: "(^|:)0{1,4}(:|$)", with: "::", options: .regularExpression).replacingOccurrences(of: "::0::", with: "::")

        return compressedAddress
    }
}

extension IPv6.Network: Codable
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
        guard let network = IPv6.Network(cidr)
        else
        {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid IPv6 network address \(cidr)")
        }
        self = network
    }
}

extension IPv6.Address: Codable
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
        guard let address = IPv6.Address(value)
        else
        {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid IPv6 address \(value)")
        }
        self = address
    }
}
