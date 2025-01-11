//
//  PublishingOptions.swift
//

import ArgumentParser
import Foundation

struct PublishingOptions: CustomStringConvertible
{
    var options: Set<PublishingOption>

    var description: String
    {
        options.sorted(by: <).map(\.description).joined(separator: ", ")
    }

    static var allCases: [PublishingOption] { PublishingOption.allCases }
    static var defaultValueDescription: String { allCases.map(\.description).joined(separator: ",") }
}

enum PublishingOption: String, CaseIterable, CustomStringConvertible
{
    case hostsbyid
    case hostsbyip
    case hostsbyname
    case hostsbymac
    case hostsbynetwork

    case devicesbyid
    case devicesbyip
    case devicesbyname
    case devicesbymac

    case devicedetailsbyid
    case devicedetailsbyip
    case devicedetailsbyname
    case devicedetailsbymac

    case olddevicesbytype

    var description: String { rawValue }
    var help: String
    {
        switch self
        {
            case .hostsbyid: return "Publish hosts by their unifi id"
            case .hostsbyip: return "Publish hosts by IP address"
            case .hostsbyname: return "Publish hosts by name"
            case .hostsbymac: return "Publish hosts by MAC address"
            case .hostsbynetwork: return "Publish hosts by network"
            case .devicesbyid: return "Publish unifi devices by their unifi id"
            case .devicesbyip: return "Publish unifi devices by IP address"
            case .devicesbyname: return "Publish unifi devices by name"
            case .devicesbymac: return "Publish unifi devices by MAC address"
            case .devicedetailsbyid: return "Publish unifi device details by their unifi id"
            case .devicedetailsbyip: return "Publish unifi device details by IP address"
            case .devicedetailsbyname: return "Publish unifi device details by name"
            case .devicedetailsbymac: return "Publish unifi device details by MAC address"
            case .olddevicesbytype: return "Publish old unifi device details by type"
        }
    }
}

extension PublishingOption: Comparable
{
    static func < (lhs: PublishingOption, rhs: PublishingOption) -> Bool
    {
        lhs.rawValue < rhs.rawValue
    }
}

extension PublishingOptions: ExpressibleByArgument
{
    init?(argument: String)
    {
        var options = PublishingOptions(options: [])
        let components = argument.split(separator: ",")
        for component in components
        {
            let optionName = component.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let option = PublishingOption(rawValue: optionName)
            {
                options.options.insert(option)
            }
            else { return nil }
        }
        self = options
    }
}
