//
//  DeviceResponse.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 08.01.25.
//

public struct DeviceResponse : Sendable, Hashable, Equatable
{
    public let meta : Meta
    public let devices : [Device]
}

extension DeviceResponse: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case meta
        case devices = "data"
    }
}

public struct Meta : Codable, Sendable, Hashable, Equatable
{
   public let rc : OldRCString
}

public enum OldRCString : Sendable, Hashable, Equatable
{
    case ok
    case unknown(String)
}

extension OldRCString: Codable
{
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        switch self
        {
            case .ok: try container.encode("ok")
            case .unknown(let value): try container.encode(value)
        }
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value
        {
            case "ok": self = .ok
            default: self = .unknown(value)
        }
    }
}

