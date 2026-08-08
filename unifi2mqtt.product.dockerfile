# syntax=docker/dockerfile:1.7
FROM swift:6.2.1-jammy AS builder

ARG PRODUCT=unifi2mqtt

WORKDIR /workspace
ENV SWIFTPM_BUILD_TESTS=false

COPY Package.swift ./
RUN --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/root/.swiftpm \
    swift package resolve
COPY Sources ./Sources
COPY Tests ./Tests

RUN --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/workspace/.build \
    swift build -c release --product "${PRODUCT}" --static-swift-stdlib \
    && install -Dm755 ".build/release/${PRODUCT}" "/out/${PRODUCT}"

FROM ubuntu:22.04

ARG PRODUCT=unifi2mqtt

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libcurl4 tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --home-dir /app appuser

COPY --from=builder "/out/${PRODUCT}" "/usr/local/bin/${PRODUCT}"

RUN printf '#!/bin/sh\nexec /usr/local/bin/%s "$@"\n' "${PRODUCT}" > /usr/local/bin/entrypoint \
    && chmod 755 /usr/local/bin/entrypoint "/usr/local/bin/${PRODUCT}" \
    && chown -R appuser:appuser /app

USER appuser

ENTRYPOINT ["/usr/local/bin/entrypoint"]
