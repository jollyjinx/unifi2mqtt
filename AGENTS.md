---
name: spm-local-unifi2mqtt
description: Use when working on the local unifi2mqtt Swift package, including Package.swift, UnifiLibrary, MQTT publishing, UniFi API models, the unifi2mqtt or unifimqtt2dns executables, documentation, tests, and container packaging.
---

# unifi2mqtt Swift Package

Use this skill for `/Users/jolly/GitHub/unifi2mqtt`.

## Project Shape

- SwiftPM package with tools version 6.2 and `StrictConcurrency=complete`.
- Executables:
  - `Sources/unifi2mqtt/unifi2mqtt.swift`: polls UniFi and publishes selected host/device payloads to MQTT.
  - `Sources/unifimqtt2dns/unifimqtt2dns.swift`: subscribes to MQTT host updates and updates eligible Hetzner DNS records.
- Shared library:
  - `Sources/UnifiLibrary`: UniFi API/old API models, `UnifiHost`, retrieval, IP/MAC helpers, and observables.
- Tests:
  - `Tests/UnifiLibraryTests`: decoding and helper tests with fixtures in `Resources`.

## Documentation

- Keep `README.md` plain Markdown for GitHub.
- Agent-oriented docs live in `docs/` and must use YAML front matter.
- Start project work by reading `AI/README.md` and `docs/INDEX.md`, then `docs/ARCHITECTURE.md` or `docs/OPERATIONS.md` as relevant.

## Repository And Releases

- Treat the public `jnxpublic` repository on `gitmaster.jinx.eu` as the primary Git remote and keep the `github` remote synchronized for public releases.
- Use `development` for development images and merge tested release history into `main` for stable releases.
- Create annotated semantic-version tags for releases. Push `main`, `development`, and the release tag to both `jnxpublic` and `github`, then verify that the remote object IDs match.
- `.github/workflows/release.yml` publishes the `development`, `main`/`latest`, and semantic-version GHCR image tags from the corresponding branch and tag pushes.
- Treat SwiftPM repositories under `.build/checkouts/` as read-only diagnostic inputs. Make dependency changes only through `Package.swift` and `Package.resolved`.

## Commands

```bash
swift build
swift test
swift build -c release
```

Use Docker for container workflows:

```bash
docker build . --file unifi2mqtt.product.dockerfile --build-arg PRODUCT=unifi2mqtt --tag unifi2mqtt
docker build . --file unifi2mqtt.product.dockerfile --build-arg PRODUCT=unifimqtt2dns --tag unifimqtt2dns
```

## Change Guidance

- Keep reusable UniFi parsing and network behavior in `UnifiLibrary`.
- Keep executable wiring and CLI options in the matching executable target.
- Update docs when changing CLI options, MQTT topics, container behavior, or operational defaults.
- Add focused tests for decoding, IP helpers, publishing option parsing, and DNS filtering changes.
- Preserve strict concurrency compatibility; prefer actors or explicit isolation for shared mutable state.
