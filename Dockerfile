# Author: Nihil Project
# The whole flock. Every tool, every module.

FROM archlinux:latest

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"
LABEL org.nihil.variant="full"

COPY build /opt/nihil/build/
COPY runtime /opt/nihil/runtime/
RUN chmod +x /opt/nihil/runtime/entrypoint.sh /opt/nihil/runtime/load_my_resources.sh /opt/nihil/runtime/browser_ui.sh

WORKDIR /opt/nihil/build
SHELL ["/bin/bash", "-c"]

RUN chmod +x entrypoint.sh && \
    ./entrypoint.sh package_base && \
    ./entrypoint.sh install_core_tools && \
    ./entrypoint.sh install_mod_ad && \
    ./entrypoint.sh install_mod_c2 && \
    ./entrypoint.sh install_mod_web && \
    ./entrypoint.sh install_mod_pwn && \
    ./entrypoint.sh install_mod_network && \
    ./entrypoint.sh install_mod_credential && \
    ./entrypoint.sh install_mod_misc && \
    ./entrypoint.sh install_mod_reverse && \
    ./entrypoint.sh install_mod_crypto && \
    ./entrypoint.sh install_mod_forensics && \
    ./entrypoint.sh healthcheck core_tools mod_ad mod_web mod_network mod_credential mod_pwn mod_c2 mod_misc mod_reverse mod_crypto mod_forensics resources && \
    ./entrypoint.sh post_install

WORKDIR /workspace
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]
