//
//  UnifiDeviceDecodingTests.swift
//

//
//  ClientDecodingTests.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 11.01.25.
//
import Foundation
import Testing

@testable import UnifiLibrary

struct OldUnifiDeviceDecodingTests
{
    @Test
    func oldDeviceDecoding() throws
    {
        let unifiedClientsResponseURL = Bundle.module.url(forResource: "OldDevice.normal", withExtension: "json", subdirectory: "Resources")!
        let data = try Data(contentsOf: unifiedClientsResponseURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let device = try decoder.decode(Device.self, from: data)
        #expect(device.reported_networks?.count ?? 0 == 2)
    }

}
