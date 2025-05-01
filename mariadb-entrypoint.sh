#!/bin/bash
set -e

ENV_FILE="/config/.env"

echo "Running custom entrypoint..."

# Set default values if the .env file doesn't exist.
if [ ! -e "$ENV_FILE" ]; then
    echo "$ENV_FILE not found, generating one..."
    MARIADB_DATABASE=xidb
    MARIADB_USER=xiadmin

    # Generate random passwords. (MARIADB_RANDOM_ROOT_PASSWORD)
    # https://github.com/MariaDB/mariadb-docker/blob/87a043a031e8c56ba66a0ad06e633417ae75ee1e/docker-entrypoint.sh#L378-L382
    MARIADB_PASSWORD=$(pwgen --numerals --capitalize --symbols --remove-chars="'\\" -1 32)
    export MARIADB_RANDOM_ROOT_PASSWORD=1

    # Write the variables to the .env file.
    cat <<-EOF > "$ENV_FILE"
		MARIADB_DATABASE=$MARIADB_DATABASE
		MARIADB_USER=$MARIADB_USER
		MARIADB_PASSWORD='$MARIADB_PASSWORD'
	EOF
    chown mysql:mysql "$ENV_FILE"
fi

# Load environment variables.
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE..."
    set -a # Automatically export all sourced variables.
    source "$ENV_FILE"
    set +a
fi

# Execute the original MariaDB entrypoint.
echo "Handing over to official MariaDB entrypoint..."
exec /usr/local/bin/docker-entrypoint.sh "$@"
