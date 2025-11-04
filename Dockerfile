# Author: Nihil Project

FROM debian:12-slim

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"

COPY sources /root/nihil-sources/

WORKDIR /root/nihil-sources/install

RUN chmod +x entrypoint.sh
RUN ./entrypoint.sh package_base

ENTRYPOINT ["/root/nihil-sources/install/entrypoint.sh"]
