//
//  UnifiDevicePortDetail.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 11.01.25.
//


public struct UnifiDevicePortDetail: Sendable, Codable, Hashable, Equatable
{
    public let idx: Int
    public let state: String
    public let connector: String
    public let maxSpeedMbps: Int
    public let speedMbps: Int?
}
