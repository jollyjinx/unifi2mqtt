# unifi2mqtt

`unifi2mqtt` is a Swift-based command-line tool that bridges Ubiquiti's UniFi network management system with an MQTT broker. It periodically retrieves client data from a UniFi controller and publishes this information to specified MQTT topics, facilitating seamless integration between UniFi networks and MQTT-enabled applications.

## Features

- **Periodic Data Retrieval:** Fetches client data from the UniFi controller at user-defined intervals.
- **MQTT Publishing:** Publishes the retrieved data to an MQTT broker, enabling real-time monitoring and integration.
- **Configurable Logging:** Adjustable log levels to control the verbosity of the application's output.
- **Signal Handling:** Supports runtime log level adjustments via `SIGUSR1` signals.

## Prerequisites

- Swift 6 or later, macOS, linux
- Access to a UniFi controller with API key
- MQTT broker credentials

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/jollyjinx/unifi2mqtt.git
    ```

2. **Build the Project:**

    ```bash
    cd unifi2mqtt
    swift build -c release
    ```
    
3. **Run the Executable:**

    ```bash
    .build/release/unifi2mqtt
    
    USAGE: unifi2mqtt <options>

    OPTIONS:
    --log-level <log-level> Set the log level. (values: trace, debug, info, notice, warning, error, critical; default: notice)
    --json-output           send json output to stdout
    --unifi-hostname <unifi-hostname>
                          Unifi hostname (default: unifi)
    --unifi-port <unifi-port>
                          Unifi port (default: 8443)
    --unifi-api-key <unifi-api-key>
                          Unifi API key
    --unifi-site-id <unifi-site-id>
                          Unifi site id
    -r, --refresh-interval <refresh-interval>
                          Unifi request interval. (default: 10.0)
    --publishing-options <options>
                          Specify publishing options as a comma-separated list. (default: hostsbyip, hostsbymac, hostsbyname, hostsbynetwork)
        Available options: 
        - hostsbyip: Publish hosts by IP address
        - hostsbyname: Publish hosts by name
        - hostsbymac: Publish hosts by MAC address
        - hostsbynetwork: Publish hosts by network
        - devicesbyip: Publish unifi devices by IP address
        - devicesbyname: Publish unifi devices by name
        - devicesbymac: Publish unifi devices by MAC address
    --mqtt-servername <mqtt-servername>
                          MQTT Server hostname (default: mqtt)
    --mqtt-port <mqtt-port> MQTT Server port (default: 1883)
    --mqtt-username <mqtt-username>
                          MQTT Server username (default: mqtt)
    --mqtt-password <mqtt-password>
                          MQTT Server password
    -e, --emit-interval <emit-interval>
                          Minimum Emit Interval to send updates to mqtt Server. (default: 1.0)
    -b, --basetopic <basetopic>
                          MQTT Server topic. (default: unifi/)
    -h, --help              Show help information.


```
