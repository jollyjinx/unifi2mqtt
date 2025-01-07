//
//  PublishingOptions.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 07.01.25.
//
import ArgumentParser
import Foundation

struct PublishingOptions: CustomStringConvertible
{
    var options: Set<PublishingOption>

    var description: String
    {
        options.sorted(by: <).map { $0.description }.joined(separator: ", ")
    }

    static var allCases: [PublishingOption] { PublishingOption.allCases }
    static var defaultValueDescription: String { allCases.map { $0.description }.joined(separator: ",") }
}

enum PublishingOption : String, CaseIterable, CustomStringConvertible
{
    case hostsbyip
    case hostsbyname
    case hostsbymac
    case hostsbynetwork

    var description: String { rawValue }
    var help: String {
        switch self
        {
            case .hostsbyip:        return "Publish hosts by IP address"
            case .hostsbyname:      return "Publish hosts by name"
            case .hostsbymac:       return "Publish hosts by MAC address"
            case .hostsbynetwork:   return "Publish hosts by network"
        }
    }
}
extension PublishingOption : Comparable
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
        }
        self = options
    }
}
