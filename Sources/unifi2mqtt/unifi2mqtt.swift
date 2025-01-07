//
//  unifi2mqtt.swift
//

import ArgumentParser
import Foundation
import JLog
import MQTTNIO
import Observation
import UnifiLibrary

extension JLog.Level: @retroactive ExpressibleByArgument {}
#if DEBUG
    let defaultLoglevel: JLog.Level = .debug
#else
    let defaultLoglevel: JLog.Level = .notice
#endif

@main
struct unifi2mqtt: AsyncParsableCommand
{
    @Option(help: "Set the log level.") var logLevel: JLog.Level = defaultLoglevel

    @Flag(name: .long, help: "send json output to stdout") var jsonOutput: Bool = false

    @Option(name: .long, help: "Unifi hostname") var unifiHostname: String = "unifi"
    @Option(name: .long, help: "Unifi port") var unifiPort: UInt16 = 8443
    @Option(name: .long, help: "Unifi API key") var unifiAPIKey: String
    @Option(name: .long, help: "Unifi site id") var unifiSiteId: String? = nil

    #if DEBUG
        @Option(name: .shortAndLong, help: "Unifi request interval.") var refreshInterval: Double = 1.0
    #else
        @Option(name: .shortAndLong, help: "Unifi request interval.") var refreshInterval: Double = 10.0
    #endif
    @Option(name: .long, help: ArgumentHelp(
            "Specify publishing options as a comma-separated list.",
            discussion: """
            Available options: 
            - \( PublishingOptions.allCases.map { $0.rawValue + ": " + $0.help }.joined(separator: "\n- ") )
            """,
            valueName: "options"
        )
        ) var publishingOptions: PublishingOptions = PublishingOptions(options:[.hostsbyip, .hostsbyname, .hostsbymac, .hostsbynetwork])

    @Option(name: .long, help: "MQTT Server hostname") var mqttServername: String = "mqtt"
    @Option(name: .long, help: "MQTT Server port") var mqttPort: UInt16 = 1883
    @Option(name: .long, help: "MQTT Server username") var mqttUsername: String = "mqtt"
    @Option(name: .long, help: "MQTT Server password") var mqttPassword: String = ""
    @Option(name: .shortAndLong, help: "Minimum Emit Interval to send updates to mqtt Server.") var emitInterval: Double = 1.0
    #if DEBUG
        @Option(name: .shortAndLong, help: "MQTT Server topic.") var basetopic: String = "example/unifi/"
    #else
        @Option(name: .shortAndLong, help: "MQTT Server topic.") var basetopic: String = "unifi/"
    #endif

    @MainActor
    func run() async throws
    {
        JLog.loglevel = logLevel
        signal(SIGUSR1, SIG_IGN)
        signal(SIGUSR1, handleSIGUSR1)

        if logLevel != defaultLoglevel
        {
            JLog.info("Loglevel: \(logLevel)")
        }

        let mqttPublisher = try await MQTTPublisher(hostname: mqttServername, port: Int(mqttPort), username: mqttUsername, password: mqttPassword, emitInterval: emitInterval, baseTopic: basetopic, jsonOutput: jsonOutput)

        let unifiHost = try await UnifiHost(host: unifiHostname, apiKey: unifiAPIKey, siteId: unifiSiteId, refreshInterval: refreshInterval)

        Task { await unifiHost.run() }

        let observationStream = AsyncStream<Void>
        { continuation in
            let observer = UnifiHostObserver(unifiHost: unifiHost, continuation: continuation)
            observer.observe()
        }

        for await _ in observationStream
        {
            for client in unifiHost.clients
            {
                for publishingOption in publishingOptions.options
                {
                    switch publishingOption
                    {
                        case .hostsbyip:        if let ipAddress = client.ipAddress
                                                {
                                                    try await mqttPublisher.publish(to: "\(publishingOption.rawValue)/\(ipAddress)", payload: client.json, qos: .atMostOnce, retain: true)
                                                }

                        case .hostsbyname:      try await mqttPublisher.publish(to: "\(publishingOption.rawValue)/\(client.name)", payload: client.json, qos: .atMostOnce, retain: true)

                        case .hostsbymac:       try await mqttPublisher.publish(to: "\(publishingOption.rawValue)/\(client.macAddress)", payload: client.json, qos: .atMostOnce, retain: true)

                        case .hostsbynetwork:   if let network = client.network
                                                {
                                                    try await mqttPublisher.publish(to: "\(publishingOption.rawValue)/\(network)", payload: client.json, qos: .atMostOnce, retain: true)
                                                }
                        default: break
                    }
                }
            }
            for device in unifiHost.devices
            {
                for publishingOption in publishingOptions.options
                {
                    switch publishingOption
                    {
                        case .devicesbyip:      if let ipAddress = device.ipAddress
                                                {
                                                    try await mqttPublisher.publish(to: "\(publishingOption.rawValue)/\(ipAddress)", payload: device.json, qos: .atMostOnce, retain: true)
                                                }
                        case .devicesbyname:    try await mqttPublisher.publish(to: "\(publishingOption.rawValue)/\(device.name)", payload: device.json, qos: .atMostOnce, retain: true)

                        case .devicesbymac:     try await mqttPublisher.publish(to: "\(publishingOption.rawValue)/\(device.macAddress)", payload: device.json, qos: .atMostOnce, retain: true)

                        default: break
                    }
                }
            }
        }
    }
}

@MainActor
struct UnifiHostObserver: Sendable
{
    let unifiHost: UnifiHost
    let continuation: AsyncStream<Void>.Continuation

    func observe()
    {
        withObservationTracking
        {
            _ = unifiHost.clients
            _ = unifiHost.devices
        } onChange: {
            continuation.yield(())
            Task { await observe() }
        }
    }
}

func handleSIGUSR1(signal: Int32)
{
    DispatchQueue.main.async
    {
        JLog.notice("Received \(signal) signal.")
        JLog.notice("Switching Log level from \(JLog.loglevel)")
        switch JLog.loglevel
        {
            case .trace: JLog.loglevel = .info
            case .debug: JLog.loglevel = .trace
            case .info: JLog.loglevel = .debug
            default: JLog.loglevel = .debug
        }

        JLog.notice("to \(JLog.loglevel)")
    }
}
