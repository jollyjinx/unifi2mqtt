# unifi2mqtt

`unifi2mqtt` is a Swift service that polls a UniFi controller and publishes selected client, network, device, and device-detail data to MQTT. The same Swift package also provides `unifimqtt2dns`, an MQTT consumer that updates eligible Hetzner DNS `A` records from UniFi client events.

## Features

- UniFi client and device retrieval through API-key authentication
- Configurable MQTT topic families, base topic, retain behavior, and emit intervals
- JSON output mode for inspection and pipelines
- Hetzner DNS updates with IPv4 filtering, TTL eligibility checks, caching, and per-host cooldown
- Runtime log-level cycling with `SIGUSR1`
- Swift 6.2 strict-concurrency checking
- Multi-architecture Linux images for both executables

## Requirements

- A UniFi controller and API key
- An MQTT broker
- For `unifimqtt2dns`, a Hetzner zone identifier and API token
- Swift 6.2.3 or newer for source builds; macOS 15 is the declared Apple platform
- Docker for local or Linux container workflows

## Clone and build

```sh
git clone https://gitmaster.jinx.eu/jnxpublic/unifi2mqtt.git
cd unifi2mqtt
swift build -c release
swift test
```

The release executables are `.build/release/unifi2mqtt` and `.build/release/unifimqtt2dns`.

## Run unifi2mqtt

The UniFi API key can be provided with `UNIFI_API_KEY` or `--unifi-api-key`:

```sh
UNIFI_API_KEY='replace-me' \
.build/release/unifi2mqtt \
  --unifi-hostname unifi.local \
  --mqtt-hostname mqtt.local \
  --mqtt-username mqtt \
  --mqtt-password 'replace-me'
```

Important release defaults:

| Option | Default |
| --- | --- |
| `--unifi-port` | `8443` |
| `--request-interval` | `15` seconds |
| `--mqtt-port` | `1883` |
| `--basetopic` | `unifi/` |
| `--minimum-emit-interval` | `1` second |
| `--maximum-emit-interval` | `60` seconds |
| `--publishing-options` | `hostsbynetwork,olddevicesbytype` |

`--publishing-options` accepts a comma-separated selection of host, device, device-detail, and legacy-device topic families. Run the executable with `--help` for the complete current list and descriptions.

Published paths are formed from the base topic, publishing option, and the selected identifier. For example, the default network-oriented client path is below:

```text
unifi/hostsbynetwork/<network>/<client-ip>
```

Use `--retain` when the broker should retain published messages. `--json-output` additionally writes JSON payloads to standard output.

## Run unifimqtt2dns

The DNS updater subscribes to `unifi/hostsbynetwork/+/+` in release builds. It accepts the Hetzner zone and token through environment variables or command-line options:

```sh
HETZNER_ZONE_IDENTIFIER='example.com' \
HETZNER_API_TOKEN='replace-me' \
.build/release/unifimqtt2dns \
  --mqtt-hostname mqtt.local \
  --mqtt-username mqtt \
  --mqtt-password 'replace-me'
```

It updates only payloads whose IPv4 address matches `--allowed-ip-regex`, whose normalized hostname identifies a Hetzner `A` record with TTL `60`, and whose cooldown permits an update. If MQTT hostnames are fully qualified, pass `--hetzner-zone-name example.com` so they can be normalized before lookup.

Review the default allowed-IP regular expression before deployment; it is intentionally tailored to the original private-network ranges. Use `unifimqtt2dns --help` for the topic-filter, cooldown, record-refresh, and filtering options.

## Published container images

The release workflow publishes one image per executable:

```text
ghcr.io/jollyjinx/unifi2mqtt
ghcr.io/jollyjinx/unifimqtt2dns
```

`latest` and `main` follow the main branch. `development` follows the development branch. Version tags are published for matching Git tags.

```sh
docker run --rm --name unifi2mqtt \
  --env UNIFI_API_KEY='replace-me' \
  ghcr.io/jollyjinx/unifi2mqtt:latest \
  --unifi-hostname unifi.local \
  --mqtt-hostname mqtt.local \
  --mqtt-username mqtt \
  --mqtt-password 'replace-me'

docker run --rm --name unifimqtt2dns \
  --env HETZNER_ZONE_IDENTIFIER='example.com' \
  --env HETZNER_API_TOKEN='replace-me' \
  ghcr.io/jollyjinx/unifimqtt2dns:latest \
  --mqtt-hostname mqtt.local \
  --mqtt-username mqtt \
  --mqtt-password 'replace-me'
```

Prefer a versioned image tag for reproducible deployments. Be aware that command-line secrets can be visible in process and container metadata; restrict access to the host and orchestration configuration.

## Build container images locally

```sh
docker build . \
  --file unifi2mqtt.product.dockerfile \
  --build-arg PRODUCT=unifi2mqtt \
  --tag unifi2mqtt

docker build . \
  --file unifi2mqtt.product.dockerfile \
  --build-arg PRODUCT=unifimqtt2dns \
  --tag unifimqtt2dns
```

The images run as an unprivileged `appuser` and use the selected executable as their entry point.

## Build and push container images

The publishing script builds both products for AMD64 and ARM64 by default. Select exactly one
registry; the image tag defaults to the normalized current branch name:

```sh
./scripts/build_and_push_image.sh --gitmaster
./scripts/build_and_push_image.sh --github
```

Select one product or architecture for a faster development build, or override the tag explicitly:

```sh
./scripts/build_and_push_image.sh --gitmaster --unifi2mqtt --arm64 --tag development
./scripts/build_and_push_image.sh --github --unifimqtt2dns --amd64 --tag test-amd64
```

On macOS the script uses Apple Container. On other hosts it uses Docker Buildx. Authenticate with
the selected registry before running it.

## Operations

Send `SIGUSR1` to either long-running process to cycle its JLog verbosity. Do not send secrets to logs or JSON-output pipelines.

For build commands, runtime defaults, and verification, see [docs/OPERATIONS.md](docs/OPERATIONS.md). The complete documentation map is [docs/INDEX.md](docs/INDEX.md), and agent-oriented routing starts at [AI/README.md](AI/README.md).

## References

- [UniFi Site Manager API](https://developer.ui.com/site-manager-api/)
- [Art-of-WiFi UniFi API client](https://github.com/Art-of-WiFi/UniFi-API-client)

## License

See [LICENSE](LICENSE).
