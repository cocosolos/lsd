########
# Base #
########
FROM ubuntu:latest AS base

ARG DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    > /etc/apt/apt.conf.d/keep-cache

# Install runtime dependencies.
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
    tini \
    tzdata \
    zlib1g

RUN git config --system --add safe.directory /server
ENV PATH=/xiadmin/.local/bin:$PATH

ARG UNAME=xiadmin
ARG UGROUP=xiadmin
ARG UID=1000
ARG GID=1000

RUN userdel --remove ubuntu && \
    groupadd --gid $GID $UNAME && \
    useradd  --uid $UID $UNAME --gid $UGROUP --home-dir /xiadmin --create-home

#########
# Build #
#########
FROM base AS build

# Install build dependencies.
RUN apt-get update && apt-get install --assume-yes --no-install-recommends --quiet \
    binutils-dev \
    build-essential \
    ccache \
    cmake \
    g++-14 \
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

ARG ORIGIN='LandSandBoat'
ARG BRANCH='base'

# Download the latest release. We don't actually need the tarball but it helps with caching.
ADD --chown=$UNAME:$UGROUP https://api.github.com/repos/$ORIGIN/server/tarball/$BRANCH /server
RUN rm /server/$BRANCH && \
    git clone --filter=tree:0 --branch=$BRANCH https://github.com/$ORIGIN/server.git /server

# Install Python dependencies.
RUN --mount=type=cache,target=/xiadmin/.cache/pip,id=$ORIGIN-$BRANCH-pip,uid=$UID,gid=$GID \
    pip3 install --break-system-packages --user --ignore-installed --requirement /server/tools/requirements.txt

ENV CC=/usr/bin/gcc-14
ENV CXX=/usr/bin/g++-14
ENV CCACHE_DIR=/xiadmin/.ccache
RUN --mount=type=cache,target=/xiadmin/build,id=$ORIGIN-$BRANCH-build,uid=$UID,gid=$GID \
    --mount=type=cache,target=/xiadmin/.ccache,id=$ORIGIN-$BRANCH-ccache,uid=$UID,gid=$GID \
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

###########
# Service #
###########
FROM base AS service

USER $UNAME
WORKDIR /server

COPY --chown=$UNAME:$UGROUP --from=build /xiadmin/.local /xiadmin/.local
COPY --chown=$UNAME:$UGROUP --from=build /server/res/compress.dat /server/res/decompress.dat /server/res/
COPY --chown=$UNAME:$UGROUP --from=build /server/scripts /server/scripts
COPY --chown=$UNAME:$UGROUP --from=build /server/sql /server/sql
COPY --chown=$UNAME:$UGROUP --from=build /server/tools /server/tools
COPY --chown=$UNAME:$UGROUP --from=build /server/modules /server/modules
COPY --chown=$UNAME:$UGROUP --from=build /server/settings /server/settings
COPY --chown=$UNAME:$UGROUP --from=build /server/.git /server/.git
COPY --chown=$UNAME:$UGROUP --from=build /server/xi_* /server/

COPY --chmod=0755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
