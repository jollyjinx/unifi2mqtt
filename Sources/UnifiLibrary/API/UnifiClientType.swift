//
//  UnifiClientType.swift
//

public enum UnifiClientType: String, Codable, Sendable
{
    case wired = "WIRED"
    case wireless = "WIRELESS"
    case vpn = "VPN"
    case teleport = "TELEPORT"
}
