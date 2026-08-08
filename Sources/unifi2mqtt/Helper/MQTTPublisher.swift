//
//  MQTTPublisher.swift
//

import Foundation
import JLog
import MQTTNIO
import NIOCore

public actor MQTTPublisher
{
    let mqttConnection: MQTTConnection
    let jsonOutput: Bool
    let emitInterval: Double
    let baseTopic: String
    var lasttimeused = [String: Date]()

    public init(connection: MQTTConnection, emitInterval: Double = 1.0, baseTopic: String = "", jsonOutput: Bool = false)
    {
        mqttConnection = connection
        self.emitInterval = emitInterval
        self.jsonOutput = jsonOutput
        self.baseTopic = baseTopic.hasSuffix("/") ? String(baseTopic.dropLast(1)) : baseTopic
    }

    public func publish(to topics: [CustomStringConvertible], payload: String, qos: MQTTQoS, retain: Bool) async throws
    {
        let topic = topics.map(\.description.mqttPath).joined(separator: "/")

        try await publish(to: topic, payload: payload, qos: qos, retain: retain)
    }

    public func publish(to topic: String, payload: String, qos: MQTTQoS, retain: Bool) async throws
    {
        let topic = baseTopic + "/" + topic

        let timenow = Date()
        let lasttime = lasttimeused[topic, default: .distantPast]

        guard timenow.timeIntervalSince(lasttime) > emitInterval else { return }
        lasttimeused[topic] = timenow

        if jsonOutput
        {
            print("{\"topic\":\"\(topic)\",\"payload\":\(payload)}")
        }
        let byteBuffer = ByteBuffer(string: payload)
        JLog.debug("publish:\(topic)")
        JLog.trace("publish:\(topic) payload:\(payload)")

        try await mqttConnection.publish(to: topic, payload: byteBuffer, qos: qos, retain: retain)
    }
}
