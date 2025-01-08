//
//  String+mqttPath.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 08.01.25.
//

extension String
{
    var mqttPath: String
    {
        return self.replacingOccurrences(of: "/", with: "_")
                   .replacingOccurrences(of: " ", with: "_")
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
