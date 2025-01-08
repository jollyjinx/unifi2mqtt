//
//  unifi2mqtt.swift
//

import ArgumentParser
import Foundation
import JLog
import MQTTNIO
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
    @Option(name: .long, help: ArgumentHelp("Specify publishing options as a comma-separated list.",
                                            discussion: """
                                            Available options: 
                                            - \(PublishingOptions.allCases.map { $0.rawValue + ": " + $0.help }.joined(separator: "\n- "))
                                            """,
                                            valueName: "options")) var publishingOptions: PublishingOptions = .init(options: [.hostsbyip, .hostsbyname, .hostsbymac, .hostsbynetwork, .devicesbymac, .devicedetailsbymac])

    @Option(name: .long, help: "MQTT Server hostname") var mqttHostname: String = "mqtt"
    @Option(name: .long, help: "MQTT Server port") var mqttPort: UInt16 = 1883
    @Option(name: .long, help: "MQTT Server username") var mqttUsername: String = "mqtt"
    @Option(name: .long, help: "MQTT Server password") var mqttPassword: String = ""
    @Option(name: .shortAndLong, help: "Minimum Emit Interval to send updates to mqtt Server.") var emitInterval: Double = 1.0
    #if DEBUG
        @Option(name: .shortAndLong, help: "MQTT Server topic.") var basetopic: String = "example/unifi/"
    #else
        @Option(name: .shortAndLong, help: "MQTT Server topic.") var basetopic: String = "unifi/"
    #endif

    @Flag(name: .long, help: "Retain messages on mqtt server") var retain: Bool = false

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

        let mqttPublisher = try await MQTTPublisher(hostname: mqttHostname, port: Int(mqttPort), username: mqttUsername, password: mqttPassword, emitInterval: emitInterval, baseTopic: basetopic, jsonOutput: jsonOutput)

        let unifiHost = try await UnifiHost(host: unifiHostname, apiKey: unifiAPIKey, siteId: unifiSiteId, refreshInterval: refreshInterval)

        Task { await unifiHost.run() }


        while true
        {
            await withTaskGroup(of: Void.self)
            { group in
                group.addTask
                { for await clients in await unifiHost.observeClients()
                    {
                        try? await mqttUpdateClient(clients, mqttPublisher: mqttPublisher, unifiHost: unifiHost)
                    }
                }
                group.addTask
                { for await devices in await unifiHost.observeDevices()
                    {
                        try? await mqttUpdateDevice(devices, mqttPublisher: mqttPublisher, unifiHost: unifiHost)
                    }
                }
                group.addTask
                { for await devicedetails in await unifiHost.observeDeviceDetails()
                    {
                        try? await mqttUpdateDeviceDetail(devicedetails, mqttPublisher: mqttPublisher, unifiHost: unifiHost)
                    }
                }
            }

            try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
        }
    }

    func mqttUpdateClient(_ clients: Set<UnifiClient>, mqttPublisher: MQTTPublisher, unifiHost: UnifiHost) async throws
    {
        async let networks = unifiHost.networks

        for client in clients
        {
            for publishingOption in publishingOptions.options
            {
                switch publishingOption
                {
                    case .hostsbyid: try await mqttPublisher.publish(to: [publishingOption.rawValue, client.id], payload: client.json, qos: .atMostOnce, retain: retain)

                    case .hostsbyip: if let ipAddress = client.ipAddress
                        {
                            try await mqttPublisher.publish(to: [publishingOption.rawValue, ipAddress], payload: client.json, qos: .atMostOnce, retain: retain)
                        }

                    case .hostsbyname: try await mqttPublisher.publish(to: [publishingOption.rawValue, client.name], payload: client.json, qos: .atMostOnce, retain: retain)

                    case .hostsbymac: try await mqttPublisher.publish(to: [publishingOption.rawValue, client.macAddress], payload: client.json, qos: .atMostOnce, retain: retain)

                    case .hostsbynetwork: if let ipAddress = client.ipAddress,
                                         let network = await networks.first(where: { $0.contains(ip: ipAddress) })?.name
                        {
                            try await mqttPublisher.publish(to: [publishingOption.rawValue, network, ipAddress], payload: client.json, qos: .atMostOnce, retain: retain)
                        }

                    default: break
                }
            }
        }
    }

    func mqttUpdateDevice(_ devices: Set<UnifiDevice>, mqttPublisher: MQTTPublisher, unifiHost: UnifiHost) async throws
    {
        for device in devices
        {
            for publishingOption in publishingOptions.options
            {
                switch publishingOption
                {
                    case .devicesbyid: try await mqttPublisher.publish(to: [publishingOption.rawValue, device.id], payload: device.json, qos: .atMostOnce, retain: retain)

                    case .devicesbyip: if let ipAddress = device.ipAddress
                        {
                            try await mqttPublisher.publish(to: [publishingOption.rawValue, ipAddress], payload: device.json, qos: .atMostOnce, retain: retain)
                        }

                    case .devicesbyname: try await mqttPublisher.publish(to: [publishingOption.rawValue, device.name], payload: device.json, qos: .atMostOnce, retain: retain)

                    case .devicesbymac: try await mqttPublisher.publish(to: [publishingOption.rawValue, device.macAddress], payload: device.json, qos: .atMostOnce, retain: retain)

                    default: break
                }
            }
        }
    }

    func mqttUpdateDeviceDetail(_ devicedetails: Set<UnifiDeviceDetail>, mqttPublisher: MQTTPublisher, unifiHost: UnifiHost) async throws
    {
        for devicedetail in devicedetails
        {
            for publishingOption in publishingOptions.options
            {
                switch publishingOption
                {
                    case .devicedetailsbyid: try await mqttPublisher.publish(to: [publishingOption.rawValue, devicedetail.id], payload: devicedetail.json, qos: .atMostOnce, retain: retain)

                    case .devicedetailsbyip: if let ipAddress = devicedetail.ipAddress
                        {
                            try await mqttPublisher.publish(to: [publishingOption.rawValue, ipAddress], payload: devicedetail.json, qos: .atMostOnce, retain: retain)
                        }

                    case .devicedetailsbyname: try await mqttPublisher.publish(to: [publishingOption.rawValue, devicedetail.name], payload: devicedetail.json, qos: .atMostOnce, retain: retain)

                    case .devicedetailsbymac: try await mqttPublisher.publish(to: [publishingOption.rawValue, devicedetail.macAddress], payload: devicedetail.json, qos: .atMostOnce, retain: retain)

                    default: break
                }
            }
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
