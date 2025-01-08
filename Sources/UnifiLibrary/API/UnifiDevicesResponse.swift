//
//  UnifiDevicesResponse.swift
//

import Foundation

public struct UnifiDevicesResponse: Codable, Sendable, Hashable, Equatable
{
    public let offset: Int
    public let limit: Int
    public let count: Int
    public let totalCount: Int
    public let data: [UnifiDevice]
}
