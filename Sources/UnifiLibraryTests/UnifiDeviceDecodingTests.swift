//
//  UnifiDeviceDecodingTests.swift
//

import Foundation
import Testing

@testable import UnifiLibrary

struct UnifiDeviceDecodingTests
{
    @Test
    func normalUnifiClientsResponse() throws
    {
        let unifiedClientsResponseURL = Bundle.module.url(forResource: "UnifiDevicesResponse.normal", withExtension: "json", subdirectory: "Resources")!
        let data = try Data(contentsOf: unifiedClientsResponseURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let unifiClientsResponse = try decoder.decode(UnifiDevicesResponse.self, from: data)
        #expect(unifiClientsResponse.data.count == 2)
    }

    @Test
    func brokenUnifiClientsResponse() throws
    {
        let unifiedClientsResponseURL = Bundle.module.url(forResource: "UnifiDevicesResponse.broken", withExtension: "json", subdirectory: "Resources")!
        let data = try Data(contentsOf: unifiedClientsResponseURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let unifiClientsResponse = try decoder.decode(UnifiDevicesResponse.self, from: data)
        #expect(unifiClientsResponse.data.count == 1)
    }
}
