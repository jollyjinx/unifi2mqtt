//
//  Network.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 08.01.25.
//
import Foundation
import RegexBuilder

import Foundation

public struct IPv4Network : Hashable
{
    public let name: String
    private let networkAddress: UInt32
    private let subnetMask: Mask

    struct Mask : Hashable
    {
        let bits: UInt32
        let number: UInt8
    }

    public init?(_ cidr: String)
    {
        guard let (address, mask) = IPv4Network.networkStringToUAddress(cidr) else { return nil }
        self.networkAddress = address
        self.subnetMask = mask
        self.name = IPv4Network.addressToString(address & mask.bits) + "/" + String(mask.number)
    }

    public func contains(ip address: String) -> Bool
    {
        guard let address = IPv4Network.stringToUAddress(address) else { return false }
        return ( address & subnetMask.bits) == networkAddress
    }
}
extension IPv4Network
{
    static func networkStringToUAddress(_ cidr: String) -> (address: UInt32, mask: Mask)?
    {
        let components = cidr.split(separator: "/")
        guard components.count == 2 else { return nil }

        guard let address = IPv4Network.stringToUAddress( String(components[0]) ),
              let mask = IPv4Network.stringToMask( String(components[1]) )
        else { return nil }

        return (address: address & mask.bits, mask: mask)
    }

    static func stringToMask(_ mask: String) -> Mask?
    {
        guard let prefixLength = UInt(mask), prefixLength > 8 else { return nil }
        let mask = (prefixLength == 0 ? 0 : ~UInt32(0) << (32 - prefixLength))
        return Mask(bits:mask, number:UInt8(prefixLength))
    }

     static func stringToUAddress(_ ip: String) -> UInt32?
     {
        let components = ip.split(separator: ".").map { UInt8($0) ?? 0 }
        guard components.count == 4 else { return nil }
        let value = components.reduce( 0, { (sum, component) in ( UInt32(sum) << 8 | UInt32(component) ) })

        return value
    }
    static func addressToString(_ hostValue: UInt32) -> String
    {
        let byte1 = (hostValue >> 24) & 0xFF
        let byte2 = (hostValue >> 16) & 0xFF
        let byte3 = (hostValue >> 8) & 0xFF
        let byte4 = hostValue & 0xFF

        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }

}
