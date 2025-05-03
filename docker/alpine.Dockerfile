########
# Base #
########
FROM alpine:latest AS base

# Install runtime dependencies.
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk --update-cache add \
    binutils \
    git \
    luajit \
    mariadb-client \
    mariadb-connector-c \
    openssl \
    python3 \
    tzdata \
    zeromq \
    zlib

RUN git config --system --add safe.directory /server
ENV PATH=/xiadmin/.local/bin:$PATH

ARG UNAME=xiadmin
ARG UGROUP=xiadmin
ARG UID=1000
ARG GID=1000

RUN addgroup --gid $GID $UGROUP && \
    adduser  --uid $UID $UNAME --ingroup $UGROUP --home /xiadmin --disabled-password

#########
# Build #
#########
FROM base AS build

# Install build dependencies.
RUN apk --update-cache add \
    binutils-dev \
    ccache \
    cmake \
    g++ \
    linux-headers \
    luajit-dev \
    make \
    mariadb-dev \
    openssl-dev \
    python3-dev \
    py3-pip \
    samurai \
    zeromq-dev \
    zlib-dev

USER $UNAME
WORKDIR /server

ARG ORIGIN='LandSandBoat'
ARG BRANCH='base'

# Download the latest release. We don't actually need the tarball but it helps with caching.
ADD --chown=$UNAME:$UGROUP https://api.github.com/repos/$ORIGIN/server/tarball/$BRANCH /server
RUN rm /server/$BRANCH && \
    git clone --filter=tree:0 --branch=$BRANCH https://github.com/$ORIGIN/server.git /server

# --- PATCH LSB ---
RUN LSB_FILE="/server/cmake/FindMariaDBCPP.cmake" && \
    if [ -f "$LSB_FILE" ]; then \
        # Check if replacement is needed.
        if grep -qF 'b09555de99ed4b1d054a88ff85acbae996bce1d1' "$LSB_FILE"; then \
            echo "Patching $LSB_FILE: Update MariaDB Connector/C++ to 1.0.5 (fixes compilation on Alpine)"; \
            sed -i 's/b09555de99ed4b1d054a88ff85acbae996bce1d1/a36ff95ac6a6236a2faaaa6ec710219c8aabe35d/g' "$LSB_FILE"; \
        fi; \
    else \
        echo "Warning: $LSB_FILE not found, skipping patch."; \
    fi;
# --- End Patch ---

# Install Python dependencies.
RUN --mount=type=cache,target=/xiadmin/.cache/pip,id=$ORIGIN-$BRANCH-pip-alpine,uid=$UID,gid=$GID \
    pip3 install --break-system-packages --user --ignore-installed --requirement /server/tools/requirements.txt

ENV CCACHE_DIR=/xiadmin/.ccache
RUN --mount=type=cache,target=/xiadmin/build,id=$ORIGIN-$BRANCH-build-alpine,uid=$UID,gid=$GID \
    --mount=type=cache,target=/xiadmin/.ccache,id=$ORIGIN-$BRANCH-ccache-alpine,uid=$UID,gid=$GID \
    # --- CACHE ---
    cp -p /xiadmin/build/version.cpp /server/src/common/ 2> /dev/null; \
    cp -p /xiadmin/build/xi_* /server/ 2> /dev/null; \
    # --- End ---
    cmake -G Ninja -S /server -B /xiadmin/build -DCMAKE_BUILD_TYPE=Release && \
    # --- PATCH efsw ---
    EFSW_FILE="/xiadmin/build/_deps/efsw-src/src/efsw/FileWatcherInotify.cpp" && \
    if [ -f "$EFSW_FILE" ]; then \
        # Check if include is missing.
        if ! grep -qF '#include <sys/select.h>' "$EFSW_FILE"; then \
            echo "Patching $EFSW_FILE: Adding #include <sys/select.h>"; \
            sed -i '1i #include <sys/select.h>' "$EFSW_FILE"; \
        fi; \
        # Check if replacement is needed.
        if grep -qF 'u_int32_t' "$EFSW_FILE"; then \
            echo "Patching $EFSW_FILE: Replacing u_int32_t with uint32_t"; \
            sed -i 's/u_int32_t/uint32_t/g' "$EFSW_FILE"; \
        fi; \
    else \
        echo "Warning: $EFSW_SRC_FILE not found, skipping patch."; \
    fi; \
    # --- End Patch ---
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
CMD ["/bin/ash"]
