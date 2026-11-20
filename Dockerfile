
# syntax=docker/dockerfile:1.7

# ============================================================
# Stage 1: Download ESA SNAP 14 installer
# ============================================================
FROM ubuntu:24.04 AS downloads

ARG TARGETARCH
ARG SNAP_VERSION=14.0.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /artifacts

RUN test "${TARGETARCH}" = "amd64" \
    && curl -fL --retry 3 \
       "https://download.esa.int/step/snap/14.0/installers/esa-snap_all_linux-${SNAP_VERSION}.sh" \
       -o esa-snap-installer.sh \
    && chmod 755 esa-snap-installer.sh


# ============================================================
# Stage 2: ESA SNAP remote desktop environment
# ============================================================
FROM ghcr.io/eoepca/iga-remote-desktop:latest-dev

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    LIBGL_ALWAYS_SOFTWARE=1

# ------------------------------------------------------------
# Minimal SNAP GUI/runtime dependencies
# ------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       libgl1 \
       libgl1-mesa-dri \
       libglu1-mesa \
       libxext6 \
       libxrender1 \
       libxtst6 \
       libxi6 \
       libfreetype6 \
       fontconfig \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Install ESA SNAP 14
# ------------------------------------------------------------
COPY response.varfile /tmp/response.varfile

COPY --from=downloads \
    /artifacts/esa-snap-installer.sh \
    /tmp/esa-snap-installer.sh

RUN sh /tmp/esa-snap-installer.sh \
      -q \
      -varfile /tmp/response.varfile \
    && rm -f \
       /tmp/esa-snap-installer.sh \
       /tmp/response.varfile

# ------------------------------------------------------------
# SNAP executable paths
# ------------------------------------------------------------
ENV PATH="/usr/local/snap/bin:${PATH}"

# ------------------------------------------------------------
# Desktop integration
# ------------------------------------------------------------
COPY snap.desktop \
    /etc/xdg/autostart/snap.desktop

COPY snap.desktop \
    /usr/share/applications/snap.desktop

# ------------------------------------------------------------
# Permissions
# ------------------------------------------------------------
RUN chown -R "${NB_UID}:${NB_GID}" "${HOME}"

USER ${NB_USER}

# ------------------------------------------------------------
# SNAP module initialization
# ------------------------------------------------------------
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG SNAP_UPDATE_TIMEOUT=600

RUN set -eu; \
    timeout --signal=TERM --kill-after=15s \
      "${SNAP_UPDATE_TIMEOUT}" \
      snap --nosplash --nogui --modules --update-all \
      > /tmp/snap-update.log 2>&1 \
      || { \
        status=$?; \
        cat /tmp/snap-update.log; \
        echo "SNAP module update failed: ${status}"; \
        exit "${status}"; \
      }; \
    cat /tmp/snap-update.log; \
    rm -f /tmp/snap-update.log

# ------------------------------------------------------------
# Build-time smoke checks
# ------------------------------------------------------------
RUN test -x /usr/local/snap/bin/snap \
    && test -x /usr/local/snap/bin/gpt \
    && snap --nosplash --nogui --modules --list
