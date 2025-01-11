//
//  UnifiClientsResponse.swift
//

import Foundation

public struct UnifiClientsResponse: Sendable, Hashable, Equatable
{
    public let offset: Int
    public let limit: Int
    public let count: Int
    public let totalCount: Int
    public let data: [UnifiClient]
}


extension UnifiClientsResponse : Codable
{
    enum CodingKeys : String, CodingKey
    {
        case offset
        case limit
        case count
        case totalCount
        case data
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.offset = try container.decode(Int.self, forKey: .offset)
        self.limit = try container.decode(Int.self, forKey: .limit)
        self.count = try container.decode(Int.self, forKey: .count)
        self.totalCount = try container.decode(Int.self, forKey: .totalCount)

        let rawData = try container.decode([OptionalUnifiClient].self, forKey: .data)
        self.data = rawData.compactMap { $0.unifiClient } // Filter out nil clients
    }
}
