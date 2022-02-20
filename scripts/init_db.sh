#!/usr/bin/env bash
set -x
set -eo pipefail

# Check if a custom user has been set, otherwise default to 'postgres'
DB_USER=${POSTGRES_USER:=postgres}
# Check if a custom password has been set, otherwise default to 'password'
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
# Check if a custom port has been set, otherwise default to '5432'
DB_PORT="${POSTGRES_PORT:=5432}"
VOLUME_PATH="$HOME/common/docker_volumes/postgres/maps_project"
MAP_DATA_DIR="$PWD/data/maps"
IMAGE_NAME="rustprooflabs/pgosm-flex"

docker run -d \
	-v ${VOLUME_PATH}:/var/lib/postgresql/data \
    -v /etc/localtime:/etc/localtime:ro \
    -v ${MAP_DATA_DIR}:/app/output \
	-e POSTGRES_USER=${DB_USER} \
	-e POSTGRES_PASSWORD=${DB_PASSWORD} \
	-p "${DB_PORT}":5432 \
	--name "pgosm" \
	${IMAGE_NAME}

# Keep pinging Postgres until it's ready to accept commands
export PGPASSWORD="${DB_PASSWORD}"
until psql -h "localhost" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c '\q'; do
	>&2 echo "Postgres is still unavailable - sleeping"
	sleep 1
done

echo "Postgres is up and running on port ${DB_PORT}"
