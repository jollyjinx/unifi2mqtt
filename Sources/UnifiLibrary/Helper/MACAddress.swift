//
//  MACAddress.swift
//

import Foundation
import RegexBuilder

public struct MACAddress: Hashable, Sendable
{
    public let address: String

    public enum InvalidMACAddressError: Error
    {
        case invalidFormat
    }

    public init(_ address: String) throws
    {
        let regex = /^([:hexdigit:]{2}[:-]){5}([:hexdigit:]{2})$/

        guard let _ = try regex.firstMatch(in: address)
        else
        {
            throw InvalidMACAddressError.invalidFormat
        }
        self.address = address.lowercased()
    }
}

extension MACAddress: CustomStringConvertible
{
    public var description: String
    {
        return address
    }
}

extension MACAddress: Codable
{
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let address = try container.decode(String.self)
        try self.init(address)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        try container.encode(address)
    }
}
