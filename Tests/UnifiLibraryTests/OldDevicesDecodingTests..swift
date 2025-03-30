//
//  OldDevicesDecodingTests..swift
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
