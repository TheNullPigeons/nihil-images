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

WORKDIR /opt/nihil/build

RUN chmod +x entrypoint.sh && \
    ./entrypoint.sh package_base

WORKDIR /workspace

ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]
