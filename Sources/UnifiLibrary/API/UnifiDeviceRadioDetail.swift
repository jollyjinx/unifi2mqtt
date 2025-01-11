//
//  UnifiDeviceRadioDetail.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 11.01.25.
//


public struct UnifiDeviceRadioDetail: Sendable, Codable, Hashable, Equatable
{
    public let wlanStandard: String
    public let frequencyGHz: Double
    public let channelWidthMHz: Int
    public let channel: Int
}
