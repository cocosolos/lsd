##############
# Base stage #
##############
FROM ubuntu:latest AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    > /etc/apt/apt.conf.d/keep-cache

###############
# Build stage #
###############
FROM base AS build

# Install build exclusive dependencies.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt install -yqq --no-install-recommends \
    binutils-dev build-essential cmake git python3 python3-dev python3-pip \
    software-properties-common libluajit-5.1-dev libmariadb-dev-compat \
    libssl-dev libzmq3-dev zlib1g-dev

# Install Python dependencies as user to facilitate copying to runtime image.
RUN --mount=type=bind,source=./server/tools/requirements.txt,target=/tmp/requirements.txt \
    --mount=type=cache,target=/root/.cache/pip \
    pip3 install --break-system-packages --user --requirement /tmp/requirements.txt

# LSB requires Git for the build, and emits version.cpp along with the executables.
# The bind mounted server directory does not persist changes, so copy these from/to
# the cached build folder, preserving timestamps to avoid unnecessary rebuilds.
# Then make a copy of the executables that can be passed to the runtime stage.
RUN --mount=type=cache,target=/build \
    --mount=type=bind,source=./.git,target=/.git \
    --mount=type=bind,source=./server,target=/server,rw \
    cp -p /build/version.cpp /server/src/common 2> /dev/null || true && \
    cp -p /build/xi_* /server 2> /dev/null || true && \
    cmake -S /server -B /build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /build -j$(nproc) && \
    cp -p /server/src/common/version.cpp /build && \
    cp -p /server/xi_* /build && \
    cp /server/xi_* /root

#################
# Runtime stage #
#################
FROM base AS service

# Install runtime dependencies.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt install -yqq --no-install-recommends \
    binutils git libluajit-5.1-2 libssl3t64 libzmq5 mariadb-client \
    python3 zlib1g \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /server
RUN git config --global --add safe.directory /server

# Copy installed Python dependencies and built executables from build stage.
COPY --from=build /root/.local /root/.local
COPY --from=build /root/xi_* /server
COPY entrypoint.sh /entrypoint.sh
