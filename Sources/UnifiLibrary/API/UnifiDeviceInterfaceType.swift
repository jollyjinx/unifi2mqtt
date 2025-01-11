//
//  UnifiDeviceInterfaceType.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 11.01.25.
//


public enum UnifiDeviceInterfaceType: String, Codable, Sendable
{
    case radios
    case ports
    case gateway
}
