//
//  NetworkTable.swift
//

import Foundation
import JLog

public struct NetworkTable: Sendable, Hashable, Equatable, Codable
{
    public let name: String
    public let ip_subnet: IPv4.Network?
    public let ipv6_subnets: [IPv6.Network]?
}

public extension NetworkTable
{
    func contains(ip: JNXIPAddress) -> Bool
    {
        JLog.trace("Checking if \(self) contains \(ip)")

        switch ip
        {
            case let .ipv4(ip4):
                return ip_subnet?.contains(ip4) ?? false
            case let .ipv6(ip6):
                return ipv6_subnets?.first(where: { $0.contains(ip6) }) != nil
        }
    }
}
