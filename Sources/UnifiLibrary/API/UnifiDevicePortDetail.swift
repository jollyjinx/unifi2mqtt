//
//  UnifiDevicePortDetail.swift
//

public struct UnifiDevicePortDetail: Sendable, Codable, Hashable, Equatable
{
    public let idx: Int
    public let state: String
    public let connector: String
    public let maxSpeedMbps: Int
    public let speedMbps: Int?
}
