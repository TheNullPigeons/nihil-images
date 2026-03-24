# Author: Nihil Project
# Multi-stage Dockerfile — targets: base (internal), full, ad, web

# ============================================================
# Stage: base (shared, never published)
# OS setup + core CLI tools
# ============================================================
FROM archlinux:latest AS base

COPY build /opt/nihil/build/
COPY runtime /opt/nihil/runtime/
RUN chmod +x /opt/nihil/runtime/entrypoint.sh /opt/nihil/runtime/load_my_resources.sh /opt/nihil/runtime/browser_ui.sh

WORKDIR /opt/nihil/build
SHELL ["/bin/bash", "-c"]

RUN chmod +x entrypoint.sh && \
    ./entrypoint.sh package_base && \
    ./entrypoint.sh install_core_tools

# ============================================================
# Stage: full — The whole flock. Every tool, every module.
# ============================================================
FROM base AS full

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"
LABEL org.nihil.variant="full"

RUN ./entrypoint.sh install_redteam_ad && \
    ./entrypoint.sh install_redteam_c2 && \
    ./entrypoint.sh install_redteam_web && \
    ./entrypoint.sh install_redteam_pwn && \
    ./entrypoint.sh install_redteam_network && \
    ./entrypoint.sh install_redteam_credential && \
    ./entrypoint.sh install_redteam_misc && \
    ./entrypoint.sh healthcheck

WORKDIR /workspace
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]

# ============================================================
# Stage: ad — Nest in their Active Directory.
# ============================================================
FROM base AS ad

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"
LABEL org.nihil.variant="ad"

RUN ./entrypoint.sh install_redteam_ad && \
    ./entrypoint.sh install_redteam_c2 && \
    ./entrypoint.sh install_redteam_network && \
    ./entrypoint.sh install_redteam_credential && \
    ./entrypoint.sh install_redteam_misc && \
    ./entrypoint.sh healthcheck core_tools redteam_ad redteam_c2 redteam_network redteam_credential redteam_misc

WORKDIR /workspace
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]

# ============================================================
# Stage: web — Beak through their web apps.
# ============================================================
FROM base AS web

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"
LABEL org.nihil.variant="web"

RUN ./entrypoint.sh install_redteam_web && \
    ./entrypoint.sh install_redteam_network && \
    ./entrypoint.sh install_redteam_credential && \
    ./entrypoint.sh install_redteam_misc && \
    ./entrypoint.sh healthcheck core_tools redteam_web redteam_network redteam_credential redteam_misc resources

WORKDIR /workspace
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]
