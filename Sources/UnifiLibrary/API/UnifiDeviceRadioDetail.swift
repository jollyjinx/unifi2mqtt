//
//  UnifiDeviceRadioDetail.swift
//

public struct UnifiDeviceRadioDetail: Sendable, Codable, Hashable, Equatable
{
    public let wlanStandard: String
    public let frequencyGHz: Double
    public let channelWidthMHz: Int
    public let channel: Int
}
