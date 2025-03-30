//
//  IPv6AddressTests.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 30.03.25.
//


import XCTest
@testable import UnifiLibrary // Import your library module

final class IPv6AddressTests: XCTestCase {

    // MARK: - Valid IPv6 Address Tests

    func testValidFullIPv6Address() {
        let addressString = "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be a valid IPv6 address")
        XCTAssertEqual(address?.description, "2001:db8:85a3::8a2e:370:7334", "Description should match canonical form")
    }

    func testValidCompressedIPv6AddressLeadingZeros() {
        let addressString = "2001:db8:85a3::8a2e:370:7334"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be a valid compressed IPv6 address")
        XCTAssertEqual(address?.description, addressString, "Description should match input")
    }

    func testValidCompressedIPv6AddressMiddleZeros() {
        let addressString = "fe80::1ff:fe23:4567:890a"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be a valid compressed IPv6 address")
         XCTAssertEqual(address?.description, addressString, "Description should match input")
    }

     func testValidIPv6AddressWithAllZerosSegment() {
        let addressString = "2001:db8:0000:1:1:1:1:1"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be a valid IPv6 address with zero segment")
        XCTAssertEqual(address?.description, "2001:db8::1:1:1:1:1", "Description should match canonical form")
     }

    func testValidIPv6LoopbackAddress() {
        let addressString = "::1"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be the valid loopback address")
        XCTAssertEqual(address?.description, addressString, "Description should match input")
    }

    func testValidIPv6UnspecifiedAddress() {
        let addressString = "::"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be the valid unspecified address")
        XCTAssertEqual(address?.description, addressString, "Description should match input")
        XCTAssertEqual(address?.highBits, 0)
        XCTAssertEqual(address?.lowBits, 0)
    }

    func testValidIPv6AddressEndingInCompression() {
        let addressString = "2001:db8::"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be a valid address ending in ::")
        XCTAssertEqual(address?.description, addressString, "Description should match input")
    }

    func testValidIPv6AddressStartingInCompression() {
        let addressString = "::db8:1"
        let address = IPv6.Address(addressString)
        XCTAssertNotNil(address, "\(addressString) should be a valid address starting in ::")
         XCTAssertEqual(address?.description, addressString, "Description should match input")
    }


    // MARK: - Invalid IPv6 Address Tests

    func testInvalidIPv6AddressTooManyParts() {
        let addressString = "2001:0db8:85a3:0000:0000:8a2e:0370:7334:abcd" // 9 parts
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "\(addressString) should be an invalid IPv6 address (too many parts)")
    }

     func testInvalidIPv6AddressTooFewPartsWithoutCompression() {
        let addressString = "2001:0db8:85a3:0000:0000:8a2e:0370" // 7 parts
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "\(addressString) should be an invalid IPv6 address (too few parts)")
     }

    func testInvalidIPv6AddressInvalidCharacters() {
        let addressString = "2001:0db8:85a3:000g:0000:8a2e:0370:7334" // Contains 'g'
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "\(addressString) should be an invalid IPv6 address (invalid characters)")
    }

    func testInvalidIPv6AddressTooManyDigitsInPart() {
        let addressString = "2001:0db8:85a3:00000:0000:8a2e:0370:7334" // 5 digits in one part
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "\(addressString) should be an invalid IPv6 address (too many digits)")
    }

    func testInvalidIPv6AddressMultipleCompressions() {
        let addressString = "2001::85a3::8a2e" // Multiple '::'
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "\(addressString) should be an invalid IPv6 address (multiple compressions)")
    }

    func testInvalidIPv6AddressCompressionWithTooManyParts() {
        let addressString = "2001:db8:1:2:3:4:5::" // 8 parts before compression
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "\(addressString) should be an invalid IPv6 address (compression with too many parts)")
    }

    func testEmptyString() {
        let addressString = ""
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "Empty string should be an invalid IPv6 address")
    }

    func testJustColons() {
        let addressString = ":::::"
        let address = IPv6.Address(addressString)
        XCTAssertNil(address, "String with only colons should be invalid")
    }

    func testIPv4Address() {
         let addressString = "192.168.1.1"
         let address = IPv6.Address(addressString)
         XCTAssertNil(address, "IPv4 address string should be invalid for IPv6 initializer")
     }

     func testRandomString() {
         let addressString = "this is not an ip address"
         let address = IPv6.Address(addressString)
         XCTAssertNil(address, "Random string should be invalid")
     }
}
