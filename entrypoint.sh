#!/bin/bash

# Export XI_ variables from corresponding MARIADB_ variables.
set -a
source "/config/.env"
set +a
export XI_NETWORK_SQL_DATABASE=$MARIADB_DATABASE
export XI_NETWORK_SQL_LOGIN=$MARIADB_USER
export XI_NETWORK_SQL_PASSWORD="$MARIADB_PASSWORD"

exec "$@"
