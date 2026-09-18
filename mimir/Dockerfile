FROM=ghcr.io/home-assistant/base:latest

# Automatically injected by the Home Assistant Builder
ARG BUILD_ARCH
ARG BUILD_VERSION

ARG MIMIR_VERSION="3.2.1"

# Explicit assignment to retain environment variables at container runtime
ENV BUILD_ARCH=${BUILD_ARCH}
ENV BUILD_VERSION=${BUILD_VERSION}
ENV MIMIR_VERSION=${MIMIR_VERSION}

# Labels
LABEL \
	network.spiritscorp.mimir.version="${MIMIR_VERSION}" \
    org.opencontainers.image.title="Grafana Mimir" \
    org.opencontainers.image.description="Grafana Mimir for Prometheus-compatible long-term metrics storage in Home Assistant." \
    org.opencontainers.image.licenses="GPL-3.0-or-later" \
    org.opencontainers.image.version="${BUILD_VERSION}" \
    org.opencontainers.image.source="https://github.com/Mastertomspirit/ha_apps_spiritscorp" \
    org.opencontainers.image.documentation="https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/mimir/DOCS.md" \
    org.opencontainers.image.authors="mastertomspirit <thespirit@spiritscorp.network>"

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Download official Mimir binary matching the target architecture and verify with official SHA-256
RUN apk add --no-cache \
        curl \
        jq \
        ca-certificates \
        tzdata \
        nginx \
        openssl \
        libcap && \
    case "${BUILD_ARCH}" in \
        "amd64")   MIMIR_ARCH="amd64" ;; \
        "aarch64") MIMIR_ARCH="arm64" ;; \
        *) echo "Unsupported architecture for Grafana Mimir: ${BUILD_ARCH}. Supported: aarch64, amd64"; exit 1 ;; \
    esac && \
    DOWNLOAD_URL="https://github.com/grafana/mimir/releases/download/mimir-${MIMIR_VERSION}/mimir-linux-${MIMIR_ARCH}" && \
    SHA_URL="https://github.com/grafana/mimir/releases/download/mimir-${MIMIR_VERSION}/mimir-linux-${MIMIR_ARCH}-sha-256" && \
    echo "Downloading Grafana Mimir v${MIMIR_VERSION} for architecture ${BUILD_ARCH} (${MIMIR_ARCH})..." && \
    curl -sSL -f "${DOWNLOAD_URL}" -o /usr/local/bin/mimir && \
    echo "Verifying SHA-256 checksum..." && \
    EXPECTED_SHA=$(curl -sSL -f "${SHA_URL}" | tr -d '[:space:]') && \
    ACTUAL_SHA=$(sha256sum /usr/local/bin/mimir | awk '{print $1}') && \
    echo "Expected SHA256: ${EXPECTED_SHA}" && \
    echo "Actual SHA256:   ${ACTUAL_SHA}" && \
    if [ -n "${EXPECTED_SHA}" ]; then \
        if [ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]; then \
            echo "ERROR: SHA256 checksum verification failed!"; \
            exit 1; \
        fi; \
        echo "SUCCESS: SHA256 checksum verified."; \
    else \
        echo "WARNING: Could not fetch SHA-256 from release, Build failed."; \
            exit 1; \
    fi && \
    chmod a+x /usr/local/bin/mimir && \
    mkdir -p /etc/mimir /data/mimir /var/log/mimir /run/nginx /var/log/nginx /var/www/mimir-ui && \
    chmod -R 775 /etc/mimir /data/mimir /var/log/mimir

COPY rootfs/ /

RUN chmod a+x /run.sh /usr/local/bin/mimir-healthcheck

EXPOSE 9009 34520

VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD /usr/local/bin/mimir-healthcheck

ENTRYPOINT ["/run.sh"]