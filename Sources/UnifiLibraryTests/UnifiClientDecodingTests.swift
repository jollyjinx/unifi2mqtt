//
//  ClientDecodingTests.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 11.01.25.
//
import Foundation
import Testing

@testable import UnifiLibrary

struct UnifiClientDecodingTests {
    @Test
    func normalUnifiClientsResponse() throws
    {
        let unifiedClientsResponseURL = Bundle.module.url(forResource: "UnifiClientsResponse.normal", withExtension: "json", subdirectory:"Resources")!
        let data = try Data(contentsOf: unifiedClientsResponseURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let unifiClientsResponse = try decoder.decode(UnifiClientsResponse.self, from: data)
        #expect(unifiClientsResponse.data.count == 2)
    }

    @Test
    func brokenUnifiClientsResponse() throws
    {
        let unifiedClientsResponseURL = Bundle.module.url(forResource: "UnifiClientsResponse.broken", withExtension: "json", subdirectory:"Resources")!
        let data = try Data(contentsOf: unifiedClientsResponseURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let unifiClientsResponse = try decoder.decode(UnifiClientsResponse.self, from: data)
        #expect(unifiClientsResponse.data.count == 1)
    }
}
