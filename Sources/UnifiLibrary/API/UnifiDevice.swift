//
//  UnifiDevice.swift
//

import Foundation

public struct UnifiDevice: Sendable, Codable
{
    public let id: String
    public let name: String
    public let model: String
    public let macAddress: String
    public let ipAddress: String?
    public let state: UnifiDeviceState
    public let features: Set<UnfiDeviceFeatures>
    public let interfaces: Set<UnifiDeviceInterfaceType>
}
extension UnifiDevice: Hashable, Equatable
{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(macAddress)
    }

    public static func == (lhs: UnifiDevice, rhs: UnifiDevice) -> Bool {
        return lhs.macAddress == rhs.macAddress
    }
}

struct OptionalUnifiDevice: Decodable, Sendable
{
    public let unifiDevice: UnifiDevice?

    public init(from decoder: Decoder) throws {
        do {
            self.unifiDevice = try UnifiDevice(from: decoder)
        } catch {
            self.unifiDevice = nil
            print("Error decoding UnifiDevice: \(error)")
        }
    }
}


