# syntax=docker/dockerfile:1-labs

##############
# Base stage #
##############
FROM ubuntu:latest AS base

ARG UNAME=xiadmin
ARG UGROUP=xiadmin
ARG UID=1000
ARG GID=1000

ARG DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    > /etc/apt/apt.conf.d/keep-cache

RUN userdel --remove ubuntu && \
    groupadd --gid $GID $UNAME && \
    useradd  --uid $UID $UNAME --gid $UGROUP --home-dir /xiadmin --create-home --skel /dev/null

# Install runtime dependencies at the base level.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install --assume-yes --no-install-recommends --quiet \
    binutils \
    git \
    libluajit-5.1-2 \
    libssl3t64 \
    libzmq5 \
    mariadb-client \
    python3 \
    tzdata \
    zlib1g

RUN git config --system --add safe.directory /server
ENV PATH=/xiadmin/.local/bin:$PATH

###############
# Build stage #
###############
FROM base AS build

# Install build dependencies.
RUN apt-get update && apt-get install --assume-yes --no-install-recommends --quiet \
    binutils-dev \
    build-essential \
    ccache \
    cmake \
    g++ \
    libluajit-5.1-dev \
    libmariadb-dev-compat \
    libssl-dev \
    libzmq3-dev \
    make \
    ninja-build \
    python3-dev \
    python3-pip \
    zlib1g-dev

USER $UNAME
WORKDIR /server

# Install Python dependencies here, copied into runtime stage.
RUN --mount=type=bind,source=server/tools/requirements.txt,target=/tmp/requirements.txt \
    --mount=type=cache,target=/xiadmin/.cache/pip,uid=$UID,gid=$GID \
    pip3 install --break-system-packages --user --ignore-installed --requirement /tmp/requirements.txt

# Exclude changes to git metadata, scripts, and sql not needed for build.
# Excluded here instead of dockerignore so they can be bind mounted during build.
# Saves from copying everything whenever scripts/sql change.
# https://docs.docker.com/reference/dockerfile/#copy---exclude (docker/dockerfile:1.7-labs)
COPY --chown=$UNAME:$UGROUP --exclude=.git --exclude=scripts --exclude=sql server /server

# Cache the build. Bind mounts to save copy time and keep clean git hash.
ENV CCACHE_DIR=/xiadmin/.ccache
RUN --mount=type=cache,target=/xiadmin/build,uid=$UID,gid=$GID \
    --mount=type=cache,target=/xiadmin/.ccache,uid=$UID,gid=$GID \
    --mount=type=bind,source=.git,target=/.git \
    --mount=type=bind,source=server/.git,target=/server/.git \
    --mount=type=bind,source=server/scripts,target=/server/scripts \
    --mount=type=bind,source=server/sql,target=/server/sql \
    # --- CACHE ---
    cp -p /xiadmin/build/version.cpp /server/src/common/ 2> /dev/null; \
    cp -p /xiadmin/build/xi_* /server/ 2> /dev/null; \
    # --- End ---
    cmake -G Ninja -S /server -B /xiadmin/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /xiadmin/build -j$(nproc) && \
    # --- CACHE ---
    cp -p /server/xi_* /xiadmin/build/ && \
    cp -p /server/src/common/version.cpp /xiadmin/build/
    # --- End ---

#################
# Runtime stage #
#################
FROM base AS service

USER $UNAME
WORKDIR /server

COPY server/res/compress.dat server/res/decompress.dat /server/res/

# Copy installed Python dependencies and built executables from build stage.
COPY --from=build /xiadmin/.local /xiadmin/.local
COPY --from=build /server/xi_* /server/

COPY --chmod=0755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
