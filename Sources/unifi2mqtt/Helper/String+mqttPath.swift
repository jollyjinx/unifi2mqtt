//
//  String+mqttPath.swift
//

extension String
{
    var mqttPath: String
    {
        return replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
