//
//  IPv6Network.swift
//

import Foundation

public enum IPv6 {
    public struct Netmask: Sendable, Hashable, CustomStringConvertible {
        public let prefixlength: UInt8
        
        public var description: String { String(prefixlength) }

        init(prefixlength: UInt8) {
        self.prefixlength = min(128, prefixlength)
        }

    }
    
    public struct Address: Sendable, Hashable, CustomStringConvertible {
        // 128-bit address represented as two UInt64s
        public let highBits: UInt64
        public let lowBits: UInt64
        
        public var description: String { IPv6.addressToString(highBits, lowBits) }

            init(highBits: UInt64, lowBits: UInt64) {
        self.highBits = highBits
        self.lowBits = lowBits
    }

    }
    
    public struct Network: Sendable, Hashable, CustomStringConvertible {
        public let address: Address
        public let netmask: Netmask
        
        public var gateway: Address { address }
        public var network: Network { 
            let (highMask, lowMask) = netmask.bits
            let networkHigh = address.highBits & highMask
            let networkLow = address.lowBits & lowMask
            return Network(address: Address(highBits: networkHigh, lowBits: networkLow), netmask: netmask)
        }
        public var description: String { "\(address)/\(netmask)" }
    }
}

public extension IPv6.Netmask {

    init?(_ string: String) {
        guard let number = UInt8(string), number <= 128 else { return nil }
        self.init(prefixlength: number)
    }
    
    var bits: (UInt64, UInt64) {
        if prefixlength == 0 {
            return (0, 0)
        } else if prefixlength <= 64 {
            let highMask: UInt64 = prefixlength == 64 ? .max : ~UInt64(0) << (64 - prefixlength)
            return (highMask, 0)
        } else {
            let lowMask: UInt64 = ~UInt64(0) << (128 - prefixlength)
            return (.max, lowMask)
        }
    }
}

public extension IPv6.Address {

    init?(_ string: String) {
        guard let (high, low) = IPv6.addressStringToInts(string) else { return nil }
        self.init(highBits: high, lowBits: low)
    }
}

public extension IPv6.Network {
    init?(_ cidrString: String) {
        let components = cidrString.split(separator: "/")
        guard components.count == 2 else { return nil }
        
        guard let address = IPv6.Address(String(components[0])),
              let netmask = IPv6.Netmask(String(components[1]))
        else { return nil }
        
        self.address = address
        self.netmask = netmask
    }
    
    func contains(_ testAddress: IPv6.Address) -> Bool {
        let (highMask, lowMask) = netmask.bits
        return testAddress.highBits & highMask == address.highBits & highMask &&
               testAddress.lowBits & lowMask == address.lowBits & lowMask
    }
}

public extension IPv6 {
    static func addressStringToInts(_ addressString: String) -> (UInt64, UInt64)? {
        // Handle shortened IPv6 addresses
        var parts = addressString.split(separator: ":")
        
        // Check for valid number of parts (including :: expansion)
        if parts.count > 8 { return nil }
        
        // Handle :: notation
        if addressString.contains("::") {
            let emptyIndex = parts.firstIndex(where: { $0.isEmpty }) ?? parts.endIndex
            let emptyCount = 8 - (parts.count - (addressString.hasPrefix(":") ? 0 : 1) - 
                                  (addressString.hasSuffix(":") ? 0 : 1))
            
            if emptyCount < 0 { return nil }
            
            var expandedParts: [Substring] = []
            expandedParts.append(contentsOf: parts[..<emptyIndex])
            expandedParts.append(contentsOf: repeatElement("0", count: emptyCount))
            
            if emptyIndex < parts.endIndex {
                expandedParts.append(contentsOf: parts[(emptyIndex + 1)...])
            }
            
            parts = expandedParts
        }
        
        // Ensure exactly 8 parts
        if parts.count != 8 { return nil }
        
        var highBits: UInt64 = 0
        var lowBits: UInt64 = 0
        
        // Process first 4 groups (high 64 bits)
        for i in 0..<4 {
            guard let value = UInt16(parts[i], radix: 16) else { return nil }
            highBits = (highBits << 16) | UInt64(value)
        }
        
        // Process last 4 groups (low 64 bits)
        for i in 4..<8 {
            guard let value = UInt16(parts[i], radix: 16) else { return nil }
            lowBits = (lowBits << 16) | UInt64(value)
        }
        
        return (highBits, lowBits)
    }
    
    static func addressToString(_ highBits: UInt64, _ lowBits: UInt64) -> String {
        var segments: [String] = []
        
        // Process high 64 bits
        for i in (0..<4).reversed() {
            let shift = i * 16
            let segment = (highBits >> shift) & 0xFFFF
            segments.append(String(format: "%x", segment))
        }
        
        // Process low 64 bits
        for i in (0..<4).reversed() {
            let shift = i * 16
            let segment = (lowBits >> shift) & 0xFFFF
            segments.append(String(format: "%x", segment))
        }
        
        // Convert to standard IPv6 notation
        var result = segments.joined(separator: ":")
        
        // TODO: Implement IPv6 compression of zero runs if needed
        
        return result
    }
}

extension IPv6.Network: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(address)/\(netmask)")
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let cidr = try container.decode(String.self)
        guard let network = IPv6.Network(cidr)
        else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid network address \(cidr)")
        }
        self = network
    }
}

extension IPv6.Address: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public init(from decoder: any Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let address = IPv6.Address(value)
        else
        {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid address \(value)")
        }
        self = address
    }
}
