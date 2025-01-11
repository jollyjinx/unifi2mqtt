//
//  UnifiClientsResponse.swift
//

import Foundation
import JLog

public struct UnifiClientsResponse: Sendable, Hashable, Equatable
{
    public let offset: Int
    public let limit: Int
    public let count: Int
    public let totalCount: Int
    public let data: [UnifiClient]
}

extension UnifiClientsResponse: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case offset
        case limit
        case count
        case totalCount
        case data
    }

    public init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        offset = try container.decode(Int.self, forKey: .offset)
        limit = try container.decode(Int.self, forKey: .limit)
        count = try container.decode(Int.self, forKey: .count)
        totalCount = try container.decode(Int.self, forKey: .totalCount)

        let rawData = try container.decode([OptionalUnifiClient].self, forKey: .data)
        data = rawData.compactMap(\.unifiClient) // Filter out nil clients
    }
}

private struct OptionalUnifiClient: Decodable, Sendable
{
    public let unifiClient: UnifiClient?

    public init(from decoder: Decoder) throws
    {
        do
        {
            unifiClient = try UnifiClient(from: decoder)
        }
        catch
        {
            unifiClient = nil

            if let debugData = try? JSONSerialization.data(withJSONObject: decoder.userInfo, options: .prettyPrinted),
               let jsonString = String(data: debugData, encoding: .utf8)
            {
                JLog.error("Error decoding UnifiClient. Decoding context: \(jsonString)")
            }
            else
            {
                JLog.error("Error decoding UnifiClient: \(error)")
            }
        }
    }
}
