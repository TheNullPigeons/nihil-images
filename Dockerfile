# Author: Nihil Project

FROM archlinux:latest

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"

COPY build /opt/nihil/build/
COPY runtime /opt/nihil/runtime/
COPY packages.txt /opt/nihil/

WORKDIR /opt/nihil/build

RUN chmod +x entrypoint.sh && \
    ./entrypoint.sh package_base && \
    ./entrypoint.sh install_core_tools && \
    ./entrypoint.sh install_redteam_ad && \
    ./entrypoint.sh install_redteam_web && \
    ./entrypoint.sh install_redteam_network && \
    ./entrypoint.sh install_redteam_credential && \
    ./entrypoint.sh install_netexec

WORKDIR /workspace

SHELL ["/usr/bin/zsh", "-c"]

ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]
