import XCTest
@testable import UnifiLibrary
import JLog

final class IPv6AddressHelpersTests: XCTestCase {
    
    func testTOnlineHostnameConversion() {
        // Valid T-Online hostname
        let validHostname = "p200300c587250f005893916ab88c40e2.dip0.t-ipconnect.de"
        
        if let ipv6 = IPv6.Address.fromTOnlineHostname(validHostname) {
            // Verify the address components rather than the exact string representation
            XCTAssertEqual(ipv6.highBits, 0x200300c587250f00, "High bits should match expected value")
            XCTAssertEqual(ipv6.lowBits, 0x5893916ab88c40e2, "Low bits should match expected value")
            
            // For debug purposes - this lets us see the actual format
            print("Converted T-Online hostname produced IPv6: \(ipv6.description)")
        } else {
            XCTFail("Should successfully extract IPv6 from valid T-Online hostname")
        }
        
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