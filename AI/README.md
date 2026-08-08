---
title: unifi2mqtt agent documentation
description: Routing index for package architecture, runtime operations, external contracts, validation, and nested dependency boundaries.
audience:
  - agents
  - maintainers
status: current
last_updated: 2026-07-22
related:
  - ../README.md
  - ../docs/INDEX.md
  - ../docs/ARCHITECTURE.md
  - ../docs/OPERATIONS.md
  - ../docs/AGENT_GUIDE.md
---

# Agent documentation

Use [docs/INDEX.md](../docs/INDEX.md) as the authoritative documentation map. This `AI/` entry point exposes the existing front-matter documentation set to repository-wide tooling without duplicating its detailed guidance.

## Routing

- Package targets, data flow, dependencies, and source landmarks: [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
- Builds, release defaults, execution, images, and verification: [docs/OPERATIONS.md](../docs/OPERATIONS.md)
- Change placement and documentation rules: [docs/AGENT_GUIDE.md](../docs/AGENT_GUIDE.md)
- Human setup and quick starts for both executables: [README.md](../README.md)

## Compatibility boundaries

Preserve these external contracts unless a breaking change is explicitly requested:

- `unifi2mqtt` CLI option names, release defaults, publishing-option names, MQTT topic shapes, JSON payload models, and `SIGUSR1` behavior;
- `UNIFI_API_KEY` fallback behavior;
- `unifimqtt2dns` MQTT filter, hostname normalization, allowed-IP filtering, TTL `60` eligibility rule, cooldown/cache semantics, and Hetzner environment variables;
- both GHCR image names, product-selecting Docker build argument, unprivileged runtime user, and main/development/version tag meanings.

Shared UniFi models, parsing, and network helpers belong in `UnifiLibrary`. Keep ArgumentParser wiring and service-specific orchestration in the matching executable target.

## Nested dependency boundary

`.build/checkouts/` contains SwiftPM-managed nested Git repositories. Treat them as read-only diagnostic inputs: do not edit, stage, commit, rebase, or push them as part of root work. Before dependency-sensitive validation, record their commits and dirty state; confirm both are unchanged afterward. Make dependency changes through `Package.swift` and `Package.resolved` only when the task explicitly requires them.

## Validation baseline

From the repository root:

```sh
swift build
swift test
swift build -c release --product unifi2mqtt
swift build -c release --product unifimqtt2dns
```

For documentation-only changes, at minimum parse all front matter, resolve local links, run `git diff --check`, and run the test suite when feasible. For container changes, build each affected product with `unifi2mqtt.product.dockerfile` and verify the image entry point with `--help`.
