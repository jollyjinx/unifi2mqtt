---
title: Architecture
description: Package layout, runtime flow, and source landmarks for the unifi2mqtt Swift package.
audience:
  - agents
  - maintainers
status: current
related:
  - ../Package.swift
  - ../Sources/unifi2mqtt/unifi2mqtt.swift
  - ../Sources/unifimqtt2dns/unifimqtt2dns.swift
  - ../Sources/UnifiLibrary/UnifiHost.swift
  - ../Sources/UnifiLibrary/UnifiHostRetriever.swift
source_landmarks:
  package_manifest: ../Package.swift
  mqtt_bridge_entrypoint: ../Sources/unifi2mqtt/unifi2mqtt.swift
  dns_updater_entrypoint: ../Sources/unifimqtt2dns/unifimqtt2dns.swift
  unifi_client_library: ../Sources/UnifiLibrary
  tests: ../Tests/UnifiLibraryTests
---

# Architecture

`unifi2mqtt` is a SwiftPM package with two executable targets and one shared library target.

## Targets

- `unifi2mqtt`: polls the UniFi API and publishes client, device, device-detail, and legacy device payloads to MQTT topics.
- `unifimqtt2dns`: subscribes to MQTT client updates and updates matching Hetzner DNS `A` records.
- `UnifiLibrary`: shared UniFi API models, old API models, host polling, networking helpers, IP and MAC helpers, and async observation primitives.
- `UnifiLibraryTests`: decoding and helper tests with JSON fixtures under `Tests/UnifiLibraryTests/Resources`.

## Runtime Flow

`unifi2mqtt`:

1. Parses CLI arguments with `swift-argument-parser`.
2. Reads `UNIFI_API_KEY` when `--unifi-api-key` is omitted.
3. Opens a scoped async `MQTTConnection` and creates `MQTTPublisher` around it.
4. Creates `UnifiHost`, which retrieves UniFi data on an interval.
5. Starts the UniFi polling task.
6. Observes old devices, clients, devices, and device details concurrently.
7. Publishes selected payloads according to `--publishing-options`.

`unifimqtt2dns`:

1. Parses MQTT and Hetzner options.
2. Reads `HETZNER_ZONE_IDENTIFIER` and `HETZNER_API_TOKEN` when matching CLI options are omitted.
3. Opens a scoped async MQTT connection and consumes `unifi/hostsbynetwork/+/+` as an `AsyncSequence` in release builds.
4. Decodes client update payloads.
5. Filters updates by IPv4 regex and hostname normalization.
6. Checks Hetzner record eligibility by requiring a TTL 60 `A` record.
7. Updates DNS through `HetznerDynDNS` while applying per-host cooldown and cache rules.

## Dependency Notes

The package uses:

- `swift-argument-parser` for command-line parsing.
- The `jollyjinx/mqtt-nio` fork's `main` branch for scoped async MQTT connections, publishing, and subscriptions.
- `async-http-client` and `swift-nio` in `UnifiLibrary`.
- `JLog` for logging.
- `hetzner-dyndns-cgi` for DNS updates.

Strict concurrency is enabled through `StrictConcurrency=complete` in `Package.swift`.

## Change Landmarks

- Add or change CLI options in the executable entrypoint files.
- Add new UniFi response fields in `Sources/UnifiLibrary/API` or `Sources/UnifiLibrary/OldAPI`.
- Add shared network or parsing helpers in `Sources/UnifiLibrary/Helper`.
- Update publishing topic behavior in `Sources/unifi2mqtt/unifi2mqtt.swift` and `Sources/unifi2mqtt/Helper/PublishingOptions.swift`.
- Update MQTT publishing mechanics in `Sources/unifi2mqtt/Helper/MQTTPublisher.swift`.
- Update DNS filtering or Hetzner rules in `Sources/unifimqtt2dns/unifimqtt2dns.swift`.
