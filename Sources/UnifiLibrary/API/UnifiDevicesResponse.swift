//
//  UnifiDevicesResponse.swift
//

import Foundation
import JLog

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
    public enum CodingKeys: CodingKey
    {
        case offset
        case limit
        case count
        case totalCount
        case data
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        offset = try container.decode(Int.self, forKey: .offset)
        limit = try container.decode(Int.self, forKey: .limit)
        count = try container.decode(Int.self, forKey: .count)
        totalCount = try container.decode(Int.self, forKey: .totalCount)

        let rawData = try container.decode([OptionalUnifiDevice].self, forKey: .data)
        data = rawData.compactMap(\.unifiDevice)
    }
}

private struct OptionalUnifiDevice: Decodable, Sendable
{
    public let unifiDevice: UnifiDevice?

    public init(from decoder: Decoder) throws
    {
        do
        {
            unifiDevice = try UnifiDevice(from: decoder)
        }
        catch
        {
            unifiDevice = nil

            if let debugData = try? JSONSerialization.data(withJSONObject: decoder.userInfo, options: .prettyPrinted),
               let jsonString = String(data: debugData, encoding: .utf8)
            {
                JLog.error("Error decoding UnifiDevice. Decoding context: \(jsonString)")
            }
            else
            {
                JLog.error("Error decoding UnifiDevice: \(error)")
            }
        }
    }
}
