# Author: Nihil Project
# Image Nihil spécialisée Pwn / exploitation binaire (base + outils pwn)

FROM archlinux:latest

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"
LABEL org.nihil.variant="pwn"

COPY build /opt/nihil/build/
COPY runtime /opt/nihil/runtime/
WORKDIR /opt/nihil/build

SHELL ["/bin/bash", "-c"]

RUN chmod +x entrypoint.sh && \
    ./entrypoint.sh package_base && \
    ./entrypoint.sh install_core_tools && \
    ./entrypoint.sh install_redteam_pwn

WORKDIR /workspace

SHELL ["/usr/bin/zsh", "-c"]

ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]
