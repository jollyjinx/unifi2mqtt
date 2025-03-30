import XCTest
@testable import UnifiLibrary
import JLog

final class IPv6AddressHelpersTests: XCTestCase {
    
    func testTOnlineHostnameConversion() {
        // Valid T-Online hostname
        let validHostname = "p200300c587250f005893916ab88c40e2.dip0.t-ipconnect.de"
        
        // Add debug prints
        print("Testing T-Online hostname: \(validHostname)")
        
        // Test basic conditions
        XCTAssertTrue(validHostname.hasPrefix("p"), "Hostname should start with 'p'")
        XCTAssertTrue(validHostname.hasSuffix(".dip0.t-ipconnect.de"), "Hostname should have correct suffix")
        
        let startIndex = validHostname.index(after: validHostname.startIndex)
        let endIndex = validHostname.index(validHostname.endIndex, offsetBy: -(".dip0.t-ipconnect.de".count))
        
        let hexPart = validHostname[startIndex..<endIndex]
        print("Extracted hex part: \(hexPart)")
        print("Hex part length: \(hexPart.count)")
        print("All hex digits? \(hexPart.allSatisfy { $0.isHexDigit })")
        
        // Test the conversion
        if let ipv6 = IPv6.Address.fromTOnlineHostname(validHostname) {
            print("Successfully parsed IPv6: \(ipv6)")
            print("High bits: \(String(format: "0x%016llX", ipv6.highBits))")
            print("Low bits: \(String(format: "0x%016llX", ipv6.lowBits))")
            
            // Verify the binary representation (which is more stable than the string format)
            XCTAssertEqual(ipv6.highBits, 0x200300c587250f00, "High bits should match expected value")
            XCTAssertEqual(ipv6.lowBits, 0x5893916ab88c40e2, "Low bits should match expected value")
            
            // Output for debugging
            print("Converted T-Online hostname produced IPv6: \(ipv6.description)")
            
            // Now test a manual construction to make sure internal ipv6 parsing works consistently
            let directAddress = IPv6.Address(highBits: 0x200300c587250f00, lowBits: 0x5893916ab88c40e2)
            XCTAssertEqual(ipv6.description, directAddress.description, "Both methods should produce the same string representation")
        } else {
            XCTFail("Should successfully extract IPv6 from valid T-Online hostname")
        }
        
        // Test a sample from the real world to make sure conversion works
        // Using a properly formatted 32-character example
        let realWorldHostname = "p2a029cc4d42887a6a50fd47cd3fb5a84.dip0.t-ipconnect.de" 
        print("Testing real-world hostname: \(realWorldHostname)")
        if let ipv6 = IPv6.Address.fromTOnlineHostname(realWorldHostname) {
            print("Successfully parsed real-world IPv6: \(ipv6)")
        } else {
            print("Failed to parse real-world hostname")
        }
        XCTAssertNotNil(IPv6.Address.fromTOnlineHostname(realWorldHostname), "Should handle real-world hostname")
        
        // Invalid hostnames
        let notTOnlineDomain = "p200300c587250f005893916ab88c40e2.example.com"
        XCTAssertNil(IPv6.Address.fromTOnlineHostname(notTOnlineDomain), "Should return nil for non-T-Online domain")
        
        let wrongPrefix = "x200300c587250f005893916ab88c40e2.dip0.t-ipconnect.de"
        XCTAssertNil(IPv6.Address.fromTOnlineHostname(wrongPrefix), "Should return nil for wrong prefix")
        
        let invalidHexSegment = "pzzz300c587250f005893916ab88c40e2.dip0.t-ipconnect.de"
        XCTAssertNil(IPv6.Address.fromTOnlineHostname(invalidHexSegment), "Should return nil for invalid hex")
        
        let tooShort = "p200300c587250f00.dip0.t-ipconnect.de"
        XCTAssertNil(IPv6.Address.fromTOnlineHostname(tooShort), "Should return nil for too short hostname")
    }
} 