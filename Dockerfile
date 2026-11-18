
# syntax=docker/dockerfile:1.7

# ============================================================
# Stage 1: Download ESA SNAP installer
# ============================================================
FROM ubuntu:24.04 AS downloads

ARG TARGETARCH=amd64
ARG SNAP_MAJOR_VERSION=12.0
ARG SNAP_MINOR_VERSION=0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /artifacts

RUN test "${TARGETARCH}" = "amd64" \
    && curl -fL --retry 3 \
       "https://download.esa.int/step/snap/${SNAP_MAJOR_VERSION}/installers/esa-snap_all_linux-${SNAP_MAJOR_VERSION}.${SNAP_MINOR_VERSION}.sh" \
       -o esa-snap-installer.sh \
    && chmod 755 esa-snap-installer.sh


# ============================================================
# Stage 2: ESA SNAP remote desktop environment
#
# Base:
#   Python 3.13
#   XFCE / TurboVNC / Firefox
#   JupyterLab
# ============================================================
#TODO pin version, e.g. 1.3.0
FROM ghcr.io/eoepca/iga-remote-desktop:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Software rendering for remote desktop
# ------------------------------------------------------------
ENV LIBGL_ALWAYS_SOFTWARE=1

# ------------------------------------------------------------
# Java and SNAP runtime dependencies
# ------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       openjdk-17-jdk \
       maven \
       wget \
       libgl1-mesa-dri \
       libgl1 \
       libglu1-mesa \
       mesa-utils \
       libxext6 \
       libxrender1 \
       libxtst6 \
       libxi6 \
       libx11-6 \
       libfreetype6 \
       fontconfig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Java environment
# ------------------------------------------------------------
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ------------------------------------------------------------
# SNAP installer configuration
# ------------------------------------------------------------
COPY response.varfile /tmp/response.varfile

COPY --from=downloads \
    /artifacts/esa-snap-installer.sh \
    /tmp/esa-snap-installer.sh

# ------------------------------------------------------------
# Install ESA SNAP 12.0.0
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# Runtime user
# ------------------------------------------------------------
USER ${NB_USER}

# ------------------------------------------------------------
# SNAP module initialization
#
# Preserve original module-update behavior.
# Avoid indefinite blocking during Docker build.
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
RUN java -version \
    && mvn -version \
    && test -x /usr/local/snap/bin/snap \
    && test -x /usr/local/snap/bin/gpt \
    && snap --nosplash --nogui --modules --list
