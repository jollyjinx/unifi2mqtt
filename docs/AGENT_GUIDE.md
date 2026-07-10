---
title: Agent Guide
description: Navigation and maintenance guidance for coding agents working in the unifi2mqtt repository.
audience:
  - agents
status: current
related:
  - INDEX.md
  - ARCHITECTURE.md
  - OPERATIONS.md
  - ../README.md
  - ../Package.swift
source_landmarks:
  cli_unifi2mqtt: ../Sources/unifi2mqtt/unifi2mqtt.swift
  cli_unifimqtt2dns: ../Sources/unifimqtt2dns/unifimqtt2dns.swift
  publisher_options: ../Sources/unifi2mqtt/Helper/PublishingOptions.swift
  mqtt_publisher: ../Sources/unifi2mqtt/Helper/MQTTPublisher.swift
  unifi_library: ../Sources/UnifiLibrary
  fixtures: ../Tests/UnifiLibraryTests/Resources
---

# Agent Guide

Start with `docs/INDEX.md` for documentation scope, then use `docs/ARCHITECTURE.md` for code navigation and `docs/OPERATIONS.md` for commands.

## Documentation Rules

- Keep `README.md` as plain Markdown without front matter.
- Put agent-oriented documentation in `docs/`.
- Start every `docs/*.md` file with YAML front matter.
- Include `related` or `source_landmarks` whenever a document describes specific code paths.
- Prefer linking to existing docs instead of duplicating operational instructions.

## Coding Rules

- Preserve the SwiftPM target split: shared UniFi behavior belongs in `UnifiLibrary`; executable-specific behavior belongs in the matching executable target.
- Keep strict concurrency compatibility in mind because `Package.swift` enables `StrictConcurrency=complete`.
- Prefer typed decoding models and focused tests using fixtures under `Tests/UnifiLibraryTests/Resources`.
- For MQTT topic changes, update publishing options, publisher behavior, docs, and tests together when the behavior is externally visible.
- For CLI option changes, update the relevant `AsyncParsableCommand`, README usage snippets if user-facing, and `docs/OPERATIONS.md`.

## Validation

Use `swift test` for documentation or model-only changes when feasible. Use `swift build && swift test` for behavior changes. Add targeted tests when changing decoding, IP helpers, publishing option parsing, or DNS filtering behavior.
