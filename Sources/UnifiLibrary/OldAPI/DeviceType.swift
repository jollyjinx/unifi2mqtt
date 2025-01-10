//
//  DeviceType.swift
//
import Foundation
import JLog

public enum DeviceType: Sendable, Hashable, Equatable, CustomStringConvertible
{
    case udm
    case uap
    case usw
    case unknown(String)

    public var description: String
    {
        switch self
        {
            case .udm: return "udm"
            case .uap: return "uap"
            case .usw: return "usw"
            case let .unknown(value): return value
        }
    }
}

extension DeviceType: Codable
{
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        switch self
        {
            case .udm: try container.encode("udm")
            case .uap: try container.encode("uap")
            case .usw: try container.encode("usw")
            case let .unknown(value): try container.encode(value)
        }
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value
        {
            case "udm": self = .udm
            case "uap": self = .uap
            case "usw": self = .usw
            default: self = .unknown(value)
        }
    }
}
