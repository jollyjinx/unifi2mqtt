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
        guard hostname.hasPrefix("p"), hostname.hasSuffix(".dip0.t-ipconnect.de") else { 
            return nil 
        }
        
        // match the ipv6 address from the name
        let regex = /^p([\da-fA-F]{4})([\da-fA-F]{4})([\da-fA-F]{4})([\da-fA-F]{4})([\da-fA-F]{4})([\da-fA-F]{4})([\da-fA-F]{4})([\da-fA-F]{4})\.dip0.t-ipconnect.de$/
        do {
            let match = try regex.wholeMatch(in: hostname)
            if let match {
                let ipv6Address = "\(String(match.1)):\(String(match.2)):\(String(match.3)):\(String(match.4)):\(String(match.5)):\(String(match.6)):\(String(match.7)):\(String(match.8))"
                if let ipv6 = IPv6.Address(ipv6Address) {
                    JLog.debug("Converted hostname \(hostname) to IPv6 address \(ipv6)")
                    return ipv6
                }
            }
        } catch {
            JLog.error("Error matching T-Online hostname pattern: \(error)")
        }
        
        return nil
    }
} 