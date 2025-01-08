//
//  OldDeviceTableDevice.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 08.01.25.
//
import Foundation

public struct Device : Codable, Sendable, Hashable, Equatable
{
    public let model: String
    public let name: String
    public let mac: String

    public let reported_networks: [ReportedNetwork]?
}

public struct ReportedNetwork : Codable, Sendable, Hashable, Equatable
{
    public let name: String
    public let address: String?
}
