# Author: Nihil Project

FROM debian:12-slim

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.nihil.tag="${TAG}"
LABEL org.nihil.version="${VERSION}"
LABEL org.nihil.build_date="${BUILD_DATE}"
LABEL org.nihil.app="Nihil"

# Copy project files
COPY build /opt/nihil/build/
COPY runtime /opt/nihil/runtime/

# Build-time workdir
WORKDIR /opt/nihil/build

# Ensure scripts are executable and run base install
RUN chmod +x entrypoint.sh lib/common.sh modules/base.sh && \
    ./entrypoint.sh package_base

# Runtime entrypoint
ENTRYPOINT ["/opt/nihil/runtime/entrypoint.sh"]
