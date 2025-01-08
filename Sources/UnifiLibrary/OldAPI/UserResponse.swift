//
//  OldDeviceTable.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 08.01.25.
//

public struct UserResponse : Sendable, Hashable, Equatable
{
    public let meta : Meta
    public let devices : [Device]
}

extension UserResponse: Codable
{
    public enum CodingKeys: String, CodingKey
    {
        case meta
        case devices = "data"
    }
}
