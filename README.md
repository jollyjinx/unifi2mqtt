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

1. **Build the Project (if swift is installed):**

    
    ```bash
    cd unifi2mqtt
    swift build -c release
    ```
1. **Build the Project via docker:**

    ```bash
    docker build . --file unifi2mqtt.product.dockerfile --tag unifi2mqtt
    docker run --name unifi2mqtt unifi2mqtt --unifi-api-key <unifi-api-key> .....
    ```

1. **Run the Project with docker:**

    ```bash
    docker run --name unifi2mqtt jollyjinx/unifi2mqtt:latest unifi2mqtt --unifi-api-key <unifi-api-key> .....
    ```

    
1. **Run the Executable:**

    ```bash
    .build/release/unifi2mqtt
    
    USAGE: unifi2mqtt [<options>] --unifi-api-key <unifi-api-key>

    OPTIONS:
    --log-level <log-level> Set the log level. (values: trace, debug, info, notice, warning, error, critical; default: debug)
    --json-output           send json output to stdout
    --unifi-hostname <unifi-hostname>
                          Unifi hostname (default: unifi)
    --unifi-port <unifi-port>
                          Unifi port (default: 8443)
    --unifi-api-key <unifi-api-key>
                          Unifi API key
    --unifi-site-id <unifi-site-id>
                          Unifi site id
    -r, --request-interval <request-interval>
                          Unifi request interval. (default: 5.0)
    --publishing-options <options>
                          Specify publishing options as a comma-separated list. (default: hostsbynetwork, olddevicesbytype)
        Available options: 
        - hostsbyid: Publish hosts by their unifi id
        - hostsbyip: Publish hosts by IP address
        - hostsbyname: Publish hosts by name
        - hostsbymac: Publish hosts by MAC address
        - hostsbynetwork: Publish hosts by network
        - devicesbyid: Publish unifi devices by their unifi id
        - devicesbyip: Publish unifi devices by IP address
        - devicesbyname: Publish unifi devices by name
        - devicesbymac: Publish unifi devices by MAC address
        - devicedetailsbyid: Publish unifi device details by their unifi id
        - devicedetailsbyip: Publish unifi device details by IP address
        - devicedetailsbyname: Publish unifi device details by name
        - devicedetailsbymac: Publish unifi device details by MAC address
        - olddevicesbytype: Publish old unifi device details by type
    --mqtt-hostname <mqtt-hostname>
                          MQTT Server hostname (default: mqtt)
    --mqtt-port <mqtt-port> MQTT Server port (default: 1883)
    --mqtt-username <mqtt-username>
                          MQTT Server username (default: mqtt)
    --mqtt-password <mqtt-password>
                          MQTT Server password
    --minimum-emit-interval <minimum-emit-interval>
                          Minimum Emit Interval to send updates to mqtt Server. (default: 1.0)
    --maximum-emit-interval <maximum-emit-interval>
                          Maximum Emit Interval to send updates to mqtt Server. (default: 60.0)
    -b, --basetopic <basetopic>
                          MQTT Server topic. (default: example/unifi/)
    --retain                Retain messages on mqtt server
    -h, --help              Show help information.
    ```



## Further reading

Some documentation and resources that might be helpful:

- https://unifi.local/unifi-api/network
- https://ubntwiki.com/products/software/unifi-controller/api
- https://developer.ui.com/site-manager-api/
- https://github.com/Art-of-WiFi/UniFi-API-client

