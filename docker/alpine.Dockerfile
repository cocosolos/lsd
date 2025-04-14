# syntax=docker/dockerfile:1-labs

##############
# Base stage #
##############
FROM alpine:latest AS base

ARG UNAME=xiadmin
ARG UGROUP=xiadmin
ARG UID=1000
ARG GID=1000

RUN addgroup --gid $GID $UGROUP && \
    adduser  --uid $UID $UNAME --ingroup $UGROUP --home /xiadmin --disabled-password

# Install runtime dependencies at the base level.
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk --update-cache add \
    binutils \
    git \
    luajit \
    mariadb-client \
    mariadb-connector-c \
    openssl \
    python3 \
    zeromq \
    zlib

RUN git config --system --add safe.directory /server
ENV PATH=/xiadmin/.local/bin:$PATH

###############
# Build stage #
###############
FROM base AS build

# Install build dependencies.
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk --update-cache add \
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
    zeromq-dev \
    zlib-dev

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
    cmake -S /server -B /xiadmin/build -DCMAKE_BUILD_TYPE=Release && \
    # --- PATCH efsw ---
    EFSW_FILE="/xiadmin/build/_deps/efsw-src/src/efsw/FileWatcherInotify.cpp"; \
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
    # Alpine seems to always re-link the executables.
    cp -p /server/xi_* /xiadmin/build/; \
    cp -p /server/src/common/version.cpp /xiadmin/build/;
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
