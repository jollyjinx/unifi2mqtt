//
//  UnifiClientType.swift
//

public enum UnifiClientType: Sendable, Equatable
{
    case wired
    case wireless
    case vpn
    case teleport
    case unknownKey(String)
}

extension UnifiClientType: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
            case .wired: return CodingKeys.wired.rawValue
            case .wireless: return CodingKeys.wireless.rawValue
            case .vpn: return CodingKeys.vpn.rawValue
            case .teleport: return CodingKeys.teleport.rawValue
            case let .unknownKey(key): return key
        }
    }
}

extension UnifiClientType: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case wired = "WIRED"
        case wireless = "WIRELESS"
        case vpn = "VPN"
        case teleport = "TELEPORT"
        case unknownKey
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        switch value
        {
            case CodingKeys.wired.rawValue: self = .wired
            case CodingKeys.wireless.rawValue: self = .wireless
            case CodingKeys.vpn.rawValue: self = .vpn
            case CodingKeys.teleport.rawValue: self = .teleport
            default: self = .unknownKey(value)
        }
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        switch self
        {
            case .wired: try container.encode(CodingKeys.wired.rawValue)
            case .wireless: try container.encode(CodingKeys.wireless.rawValue)
            case .vpn: try container.encode(CodingKeys.vpn.rawValue)
            case .teleport: try container.encode(CodingKeys.teleport.rawValue)
            case let .unknownKey(key): try container.encode(key)
        }
    }
}
