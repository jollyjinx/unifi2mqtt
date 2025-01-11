//
//  UnifiDeviceState.swift
//

import Foundation

public enum UnifiDeviceState:  Sendable, Hashable
{
    case online
    case offline
    case pendingAdoption
    case updating
    case gettingReady
    case adopting
    case deleting
    case connectionInterrupted
    case isolated
    case unknownKey(String)
}


extension UnifiDeviceState: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
            case .online: return "ONLINE"
            case .offline: return "OFFLINE"
            case .pendingAdoption: return "PENDING_ADOPTION"
            case .updating: return "UPDATING"
            case .gettingReady: return "GETTING_READY"
            case .adopting: return "ADOPTING"
            case .deleting: return "DELETING"
            case .connectionInterrupted: return "CONNECTION_INTERRUPTED"
            case .isolated: return "ISOLATED"
            case .unknownKey(let key): return key
        }
    }
}

extension UnifiDeviceState : Codable
{
    enum CodingKeys: String, CodingKey
    {
        case online = "ONLINE"
        case offline = "OFFLINE"
        case pendingAdoption = "PENDING_ADOPTION"
        case updating = "UPDATING"
        case gettingReady = "GETTING_READY"
        case adopting = "ADOPTING"
        case deleting = "DELETING"
        case connectionInterrupted = "CONNECTION_INTERRUPTED"
        case isolated = "ISOLATED"
        case unknownKey
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        switch self
        {
            case .online: try container.encode("ONLINE")
            case .offline: try container.encode("OFFLINE")
            case .pendingAdoption: try container.encode("PENDING_ADOPTION")
            case .updating: try container.encode("UPDATING")
            case .gettingReady: try container.encode("GETTING_READY")
            case .adopting: try container.encode("ADOPTING")
            case .deleting: try container.encode("DELETING")
            case .connectionInterrupted: try container.encode("CONNECTION_INTERRUPTED")
            case .isolated: try container.encode("ISOLATED")
            case .unknownKey(let key): try container.encode(key)
        }
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value
        {
            case "ONLINE": self = .online
            case "OFFLINE": self = .offline
            case "PENDING_ADOPTION": self = .pendingAdoption
            case "UPDATING": self = .updating
            case "GETTING_READY": self = .gettingReady
            case "ADOPTING": self = .adopting
            case "DELETING": self = .deleting
            case "CONNECTION_INTERRUPTED": self = .connectionInterrupted
            case "ISOLATED": self = .isolated
            default: self = .unknownKey(value)
        }
    }
}

