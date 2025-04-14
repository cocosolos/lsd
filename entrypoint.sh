#!/bin/sh
set -e

echo "Loading configuration from /config/.env..."
if [ -f "/config/.env" ]; then
    set -a
    . "/config/.env"
    set +a
    unset MARIADB_ROOT_PASSWORD
else
    echo "Warning: /config/.env not found."
fi

export XI_NETWORK_SQL_PASSWORD="$MARIADB_PASSWORD" && unset MARIADB_PASSWORD
export XI_NETWORK_SQL_LOGIN="$MARIADB_USER" && unset MARIADB_USER
export XI_NETWORK_SQL_DATABASE="$MARIADB_DATABASE" && unset MARIADB_DATABASE

exec "$@"
