//
//  MQTTPublisher.swift
//

import Foundation
import JLog
import MQTTNIO
import NIO
import NIOPosix

public actor MQTTPublisher
{
    enum MQTTClientError: Swift.Error
    {
        case connectFailed
    }

    let mqttClient: MQTTClient
    let jsonOutput: Bool
    let emitInterval: Double
    let baseTopic: String
    let mqttQueue = DispatchQueue(label: "mqttQueue")
    var lasttimeused = [String: Date]()

    public init(hostname: String, port: Int, username: String? = nil, password _: String? = nil, emitInterval: Double = 1.0, baseTopic: String = "", jsonOutput: Bool = false) async throws
    {
        self.emitInterval = emitInterval
        self.jsonOutput = jsonOutput
        self.baseTopic = baseTopic.hasSuffix("/") ? String(baseTopic.dropLast(1)) : baseTopic

        mqttClient = MQTTClient(host: hostname, port: port, identifier: ProcessInfo.processInfo.processName, eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton), configuration: .init(userName: username, password: ""))

        mqttQueue.async { _ = self.mqttClient.connect() }
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
        var sendcounter = 10
        var sent = false
        while !sent && sendcounter > 0
        {
            sendcounter -= 1

            if !mqttClient.isActive()
            {
                do
                {
                    JLog.debug("mqttClient.is NOT Active")
                    guard try await mqttClient.connect() else { throw MQTTClientError.connectFailed }
                }
                catch
                {
                    JLog.error("mqttClient.connect failed: \(error)")
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            else
            {
                do
                {
                    let byteBuffer = ByteBuffer(string: payload)
                    JLog.debug("publish:\(topic)")
                    JLog.trace("publish:\(topic) payload:\(payload)")

                    try await mqttClient.publish(to: topic, payload: byteBuffer, qos: qos, retain: retain)
                    sent = true
                }
                catch
                {
                    JLog.error("mqttClient.publish failed: \(error)")
                }
            }
        }
        if sendcounter == 0
        {
            JLog.error("mqttClient.publish failed: \(topic)")
        }
//        let byteBuffer = ByteBuffer(string: payload)
//
//        mqttQueue.async
//        {
//            let byteBuffer = ByteBuffer(string: payload)
//
//            while !self.mqttClient.isActive()
//            {
//                JLog.debug("mqttClient.is NOT Active")
//                _ = self.mqttClient.connect()
//            }
//            JLog.debug("publish:\(topic)")
//            JLog.trace("publish:\(topic) payload:\(payload)")
//            let published = tr self.mqttClient.publish(to: topic, payload: byteBuffer, qos: qos, retain: retain)
    }
}
