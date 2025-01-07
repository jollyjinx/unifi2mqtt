//
//  JSONExtension.swift
//

import Foundation

public extension Encodable
{
    var json: String
    {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonData = try? jsonEncoder.encode(self)
        return jsonData != nil ? "\n" + (String(data: jsonData!, encoding: .utf8) ?? "") : ""
    }

    var description: String
    {
        json
    }
}
