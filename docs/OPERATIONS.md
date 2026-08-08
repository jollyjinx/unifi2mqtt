---
title: Operations
description: Build, run, configuration, container, and verification commands for unifi2mqtt.
audience:
  - agents
  - operators
  - maintainers
status: current
related:
  - ../README.md
  - ../Package.swift
  - ../unifi2mqtt.product.dockerfile
commands:
  build: swift build
  test: swift test
  release_build: swift build -c release
---

# Operations

## Build And Test

```bash
swift build
swift test
swift build -c release
```

The package declares Swift tools version 6.2 and enables complete strict concurrency checking.

## Run unifi2mqtt

```bash
UNIFI_API_KEY=... \
.build/release/unifi2mqtt \
  --unifi-hostname unifi \
  --mqtt-hostname mqtt \
  --mqtt-username mqtt \
  --mqtt-password secret
```

Important defaults:

- `--unifi-port`: `8443`
- `--mqtt-port`: `1883`
- `--basetopic`: `unifi/` in release builds
- `--request-interval`: `15.0` seconds in release builds
- `--publishing-options`: `hostsbynetwork,olddevicesbytype`

Use `SIGUSR1` to cycle the runtime log level.

## Run unifimqtt2dns

```bash
HETZNER_ZONE_IDENTIFIER=example.com \
HETZNER_API_TOKEN=... \
.build/release/unifimqtt2dns \
  --mqtt-hostname mqtt \
  --mqtt-username mqtt \
  --mqtt-password secret
```

The DNS updater subscribes to `unifi/hostsbynetwork/+/+` in release builds. It only updates a host when the MQTT payload decodes as a client update, the IPv4 address matches `--allowed-ip-regex`, the target Hetzner record is a TTL 60 `A` record, and the per-host cooldown allows another update.

If MQTT client names are fully qualified, pass `--hetzner-zone-name example.com` so names can be normalized before Hetzner lookup.

## Container Builds

This repository uses Docker for local container operations.

```bash
docker build . \
  --file unifi2mqtt.product.dockerfile \
  --build-arg PRODUCT=unifi2mqtt \
  --tag unifi2mqtt

docker build . \
  --file unifi2mqtt.product.dockerfile \
  --build-arg PRODUCT=unifimqtt2dns \
  --tag unifimqtt2dns
```

Run published images:

```bash
docker run --rm --name unifi2mqtt \
  ghcr.io/jollyjinx/unifi2mqtt:latest \
  --unifi-api-key ... \
  --mqtt-hostname mqtt

docker run --rm --name unifimqtt2dns \
  ghcr.io/jollyjinx/unifimqtt2dns:latest \
  --mqtt-hostname mqtt \
  --mqtt-password secret
```

## Verification Checklist

For documentation-only changes, run at least:

```bash
swift test
```

For code changes, run:

```bash
swift build
swift test
```

For container or release changes, also run the relevant `docker build` command for each affected product.
