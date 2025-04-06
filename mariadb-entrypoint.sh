#!/bin/bash

ENV_FILE="/env/.env"

# Set default values if the .env file is empty.
if [ ! -s "$ENV_FILE" ]; then
    MARIADB_DATABASE=xidb
    MARIADB_USER=xiadmin
    XI_NETWORK_ENABLE_HTTP=1

    # Generate random passwords. (MARIADB_RANDOM_ROOT_PASSWORD)
    # https://github.com/MariaDB/mariadb-docker/blob/87a043a031e8c56ba66a0ad06e633417ae75ee1e/docker-entrypoint.sh#L378-L382
    MARIADB_PASSWORD=$(pwgen --numerals --capitalize --symbols --remove-chars="'\\" -1 32)
    MARIADB_ROOT_PASSWORD=$(pwgen --numerals --capitalize --symbols --remove-chars="'\\" -1 32)

    # Write the variables to the .env file.
    cat <<-EOF > "$ENV_FILE"
		MARIADB_DATABASE=$MARIADB_DATABASE
		MARIADB_USER=$MARIADB_USER
		MARIADB_PASSWORD='$MARIADB_PASSWORD'
		MARIADB_ROOT_PASSWORD='$MARIADB_ROOT_PASSWORD'
		XI_NETWORK_ENABLE_HTTP=$XI_NETWORK_ENABLE_HTTP # Enables the LSB HTTP API
	EOF
fi

# Load environment variables.
if [ -f "$ENV_FILE" ]; then
    set -a # Automatically export all sourced variables.
    source "$ENV_FILE"
    set +a
fi

# Execute the original MariaDB entrypoint.
exec /usr/local/bin/docker-entrypoint.sh mariadbd "$@"
