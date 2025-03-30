//
//  IPv6AddressHelpers.swift
//

import Foundation
import JLog

public extension IPv6.Address {
    
    /// Attempts to extract an IPv6 address from a T-Online hostname
    /// - Parameter hostname: T-Online hostname in format pXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.dip0.t-ipconnect.de
    /// - Returns: An IPv6.Address if the hostname matches the expected pattern, nil otherwise
    static func fromTOnlineHostname(_ hostname: String) -> IPv6.Address? {
        let prefix = "p"
        let suffix = ".dip0.t-ipconnect.de"
        
        // Basic validation
        guard hostname.hasPrefix(prefix), hostname.hasSuffix(suffix) else { 
            return nil 
        }
        
        // Extract the hex part - in Swift, this is safer than using the prior approach
        let startPos = hostname.index(hostname.startIndex, offsetBy: prefix.count)
        let endPos = hostname.index(hostname.endIndex, offsetBy: -suffix.count)
        
        // Bounds check
        guard startPos < endPos else { return nil }
        
        let hexString = String(hostname[startPos..<endPos])
        
        // Validate we have exactly 32 hex characters
        guard hexString.count == 32, hexString.allSatisfy({ $0.isHexDigit }) else {
            JLog.debug("Invalid T-Online hostname format: hexString=\(hexString), length=\(hexString.count)")
            return nil
        }
        
        // Format into IPv6 with colons
        var ipv6String = ""
        for i in stride(from: 0, to: hexString.count, by: 4) {
            if i > 0 {
                ipv6String.append(":")
            }
            let startIdx = hexString.index(hexString.startIndex, offsetBy: i)
            let endIdx = hexString.index(startIdx, offsetBy: 4, limitedBy: hexString.endIndex) ?? hexString.endIndex
            ipv6String.append(String(hexString[startIdx..<endIdx]))
        }
        
        JLog.debug("Converted T-Online hostname \(hostname) to IPv6 string: \(ipv6String)")
        
        // Direct binary construction
        let highBits: UInt64 = (UInt64(hexString.prefix(16), radix: 16) ?? 0)
        let lowBits: UInt64 = (UInt64(hexString.suffix(16), radix: 16) ?? 0)
        
        JLog.debug("High bits: \(String(format:"0x%016llX", highBits)), Low bits: \(String(format:"0x%016llX", lowBits))")
        
        return IPv6.Address(highBits: highBits, lowBits: lowBits)
    }
} 