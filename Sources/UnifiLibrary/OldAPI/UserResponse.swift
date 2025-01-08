//
//  UserResponse.swift
//

public struct UserResponse: Sendable, Hashable, Equatable
{
    public let meta: Meta
    public let devices: [Device]
}

extension UserResponse: Codable
{
    public enum CodingKeys: String, CodingKey
    {
        case meta
        case devices = "data"
    }
}
