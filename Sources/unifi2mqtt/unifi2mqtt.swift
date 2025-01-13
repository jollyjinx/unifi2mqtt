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
@MainActor
struct unifi2mqtt: AsyncParsableCommand
{
    @Option(help: "Set the log level.") var logLevel: JLog.Level = defaultLoglevel

    @Flag(name: .long, help: "send json output to stdout") var jsonOutput: Bool = false

    @Option(name: .long, help: "Unifi hostname") var unifiHostname: String = "unifi"
    @Option(name: .long, help: "Unifi port") var unifiPort: UInt16 = 8443
    @Option(name: .long, help: "UniFi API key. This key can also be provided via the UNIFI_API_KEY environment variable") var unifiAPIKey: String = { ProcessInfo.processInfo.environment["UNIFI_API_KEY"] ?? "" }()
    @Option(name: .long, help: "Unifi site id") var unifiSiteId: String? = nil

    #if DEBUG
        @Option(name: .shortAndLong, help: "Unifi request interval.") var requestInterval: Double = 5.0
    #else
        @Option(name: .shortAndLong, help: "Unifi request interval.") var requestInterval: Double = 15.0
    #endif
    @Option(name: .long, help: ArgumentHelp("Specify publishing options as a comma-separated list.",
                                            discussion: """
                                            Available options: 
                                            - \(PublishingOptions.allCases.map { $0.rawValue + ": " + $0.help }.joined(separator: "\n- "))
                                            """,
                                            valueName: "options")) var publishingOptions: PublishingOptions = .init(options: [.hostsbynetwork, .olddevicesbytype])

    @Option(name: .long, help: "MQTT Server hostname") var mqttHostname: String = "mqtt"
    @Option(name: .long, help: "MQTT Server port") var mqttPort: UInt16 = 1883
    @Option(name: .long, help: "MQTT Server username") var mqttUsername: String = "mqtt"
    @Option(name: .long, help: "MQTT Server password") var mqttPassword: String = ""
    @Option(name: .long, help: "Minimum Emit Interval to send updates to mqtt Server.") var minimumEmitInterval: Double = 1.0

    #if DEBUG
        @Option(name: .long, help: "Maximum Emit Interval to send updates to mqtt Server.") var maximumEmitInterval: Double = 180.0
        @Option(name: .shortAndLong, help: "MQTT Server topic.") var basetopic: String = "example/unifi/"
    #else
        @Option(name: .long, help: "Maximum Emit Interval to send updates to mqtt Server.") var maximumEmitInterval: Double = 60.0
        @Option(name: .shortAndLong, help: "MQTT Server topic.") var basetopic: String = "unifi/"
    #endif

    @Flag(name: .long, help: "Retain messages on mqtt server") var retain: Bool = false

    func run() async throws
    {
        JLog.loglevel = logLevel
        signal(SIGUSR1, SIG_IGN)
        signal(SIGUSR1, handleSIGUSR1)

        if logLevel != defaultLoglevel
        {
            JLog.info("Loglevel: \(logLevel)")
        }

        enum Error: Swift.Error
        {
            case missingEnvironmentVariable(String)
        }
        guard !unifiAPIKey.isEmpty else {  throw ValidationError("UniFi API Key not set.\n\n\(unifi2mqtt.helpMessage())") }

        let mqttPublisher = try await MQTTPublisher(hostname: mqttHostname, port: Int(mqttPort), username: mqttUsername, password: mqttPassword, emitInterval: minimumEmitInterval, baseTopic: basetopic, jsonOutput: jsonOutput)

        let unifiHost = try await UnifiHost(host: unifiHostname, apiKey: unifiAPIKey, siteId: unifiSiteId, requestInterval: requestInterval, refreshInterval: maximumEmitInterval)

        Task { await unifiHost.run() }

        await withTaskGroup(of: Void.self)
        {
            group in

            group.addTask
            {
                for await oldDevices in await unifiHost.observeOldDevices()
                {
                    try? await mqttUpdateOldDevices(oldDevices, mqttPublisher: mqttPublisher, unifiHost: unifiHost)
                }
            }
            group.addTask
            {
                for await clients in await unifiHost.observeClients()
                {
                    JLog.debug("Clients updated:\(clients.count)")
                    try? await mqttUpdateClient(clients, mqttPublisher: mqttPublisher, unifiHost: unifiHost)
                }
            }
            group.addTask
            {
                for await devices in await unifiHost.observeDevices()
                {
                    try? await mqttUpdateDevice(devices, mqttPublisher: mqttPublisher, unifiHost: unifiHost)
                }
            }
            group.addTask
            {
                for await devicedetails in await unifiHost.observeDeviceDetails()
                {
                    try? await mqttUpdateDeviceDetail(devicedetails, mqttPublisher: mqttPublisher, unifiHost: unifiHost)
                }
            }
        }
        fatalError("Exited TaskGroup - this should not happen")
    }

    func mqttUpdateClient(_ clients: Set<UnifiClient>, mqttPublisher: MQTTPublisher, unifiHost: UnifiHost) async throws
    {
        let networks = unifiHost.networks

        var hasPublishedNetwork : [ ReportedNetwork: Bool ] = [:]

        for client in clients
        {
            JLog.debug("Updating client \(client.name)")

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

                    case .hostsbynetwork: if networks.isEmpty
                        {
                            JLog.error("Can't update hostsbynetwork: no networks found")
                        }
                        else if let ipAddress = client.ipAddress
                        {
                            if let reportedNetwork = networks.first(where: { $0.network?.contains(ipAddress) ?? false}),
                               let network = reportedNetwork.network
                            {
                                if !hasPublishedNetwork[reportedNetwork, default: false]
                                {
                                    try await mqttPublisher.publish(to: [publishingOption.rawValue, network], payload: reportedNetwork.json, qos: .atMostOnce, retain: retain)
                                    hasPublishedNetwork[reportedNetwork] = true
                                }

                                try await mqttPublisher.publish(to: [publishingOption.rawValue, network, ipAddress], payload: client.json, qos: .atMostOnce, retain: retain)
                            }
                            else
                            {
                                JLog.error("Can't update hostsbynetwork: no network found \(client.description)")
                            }
                        }
                        else
                        {
                            JLog.debug("Can't update hostsbynetwork: no ipAddress found \(client.description)")
                        }

                    default: break
                }
            }
        }
    }

    func mqttUpdateDevice(_ devices: Set<UnifiDevice>, mqttPublisher: MQTTPublisher, unifiHost _: UnifiHost) async throws
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

    func mqttUpdateDeviceDetail(_ devicedetails: Set<UnifiDeviceDetail>, mqttPublisher: MQTTPublisher, unifiHost _: UnifiHost) async throws
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

    func mqttUpdateOldDevices(_ oldDevices: Set<Device>, mqttPublisher: MQTTPublisher, unifiHost _: UnifiHost) async throws
    {
        for device in oldDevices
        {
            for publishingOption in publishingOptions.options
            {
                switch publishingOption
                {
                    case .olddevicesbytype: let path: [String] = [publishingOption.rawValue, device.type.description, device.name]
                        try await mqttPublisher.publish(to: path, payload: device.json, qos: .atMostOnce, retain: retain)

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
