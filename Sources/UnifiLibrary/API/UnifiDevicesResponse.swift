//
//  UnifiDevicesResponse.swift
//

import Foundation

public struct UnifiDevicesResponse: Sendable, Hashable, Equatable
{
    public let offset: Int
    public let limit: Int
    public let count: Int
    public let totalCount: Int
    public let data: [UnifiDevice]
}


extension UnifiDevicesResponse: Codable
{
    public enum CodingKeys: CodingKey {
        case offset
        case limit
        case count
        case totalCount
        case data
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.offset = try container.decode(Int.self, forKey: .offset)
        self.limit = try container.decode(Int.self, forKey: .limit)
        self.count = try container.decode(Int.self, forKey: .count)
        self.totalCount = try container.decode(Int.self, forKey: .totalCount)

        let rawData = try container.decode([OptionalUnifiDevice].self, forKey: .data)
        self.data = rawData.compactMap { $0.unifiDevice }
    }
}
