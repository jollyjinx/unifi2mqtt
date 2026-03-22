#!/bin/bash
set -euo pipefail

for architecture in amd64 arm64
do
    echo "Building static Linux release archive for architecture: $architecture"

    scratchdir="/tmp/unifi2mqtt-build-$architecture"
    packagedir="unifi2mqtt.$architecture"
    archive="unifi2mqtt.$architecture.tar.gz"

    rm -rf "$packagedir" "$archive"

    docker run --rm \
      --platform "linux/$architecture" \
      --user "$(id -u):$(id -g)" \
      -e HOME=/tmp \
      -v "$(pwd):/workspace" \
      -w /workspace \
      swift:6.2.1-jammy \
      bash -lc "rm -rf '$scratchdir' && \
                swift build -c release --static-swift-stdlib --jobs 1 --scratch-path '$scratchdir' && \
                mkdir -p '$packagedir' && \
                strip '$scratchdir/release/unifi2mqtt' && \
                strip '$scratchdir/release/unifimqtt2dns' && \
                cp '$scratchdir/release/unifi2mqtt' '$packagedir/' && \
                cp '$scratchdir/release/unifimqtt2dns' '$packagedir/' && \
                tar -czf '$archive' '$packagedir' && \
                rm -rf '$scratchdir' '$packagedir'"

    test -f "$archive"
    echo
    echo "Archive size: $(du -h "$archive" | cut -f1)"
    echo "Contents:"
    tar -tzf "$archive"
    echo
done
