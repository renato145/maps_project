#!/usr/bin/env bash
set -x
set -eo pipefail

if ! [ -x "$(command -v psql)" ]; then
	echo >&2 "Error: `psql` is not installed."
	exit 1
fi

printf -v date '%(%Y%m%d)T' -1

IMAGE_NAME='postgres_osm'
IMAGE_PRESENT=$(docker images ${IMAGE_NAME} --format '{{.ID}}')
DIR=${0%/*}
DOCKERFILE="Dockerfile-postgres"

if [[ -n ${FORCE_BUILD} ]] || [[ -z "${IMAGE_PRESENT}" ]]
then
	echo "Building image..."
	docker build -t ${IMAGE_NAME}:${date} -f $DIR/${DOCKERFILE} $DIR
	docker build -t ${IMAGE_NAME}:latest -f $DIR/${DOCKERFILE} $DIR
else
	echo "Using existing image..."
fi

# Check if a custom user has been set, otherwise default to 'postgres'
DB_USER=${POSTGRES_USER:=postgres}
# Check if a custom password has been set, otherwise default to 'password'
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
# Check if a custom database name has been set, otherwise default to 'newsletter'
DB_NAME="${POSTGRES_DB:=osm}"
# Check if a custom port has been set, otherwise default to '5432'
DB_PORT="${POSTGRES_PORT:=5432}"
VOLUME_PATH="$HOME/common/docker_volumes/postgres/maps_project"

# Allow to skip Docker if a dockerized Postgres database is already running
if [[ -z "${SKIP_DOCKER}" ]]
then
	# if a postgres container is running, print instructions to kill it and exit
	RUNNING_POSTGRES_CONTAINER=$(docker ps --filter 'name=postgres_osm' --format '{{.ID}}')
	if [[ -n $RUNNING_POSTGRES_CONTAINER ]]; then
		echo >&2 "there is a postgres container already running, kill it with"
		echo >&2 "    docker kill ${RUNNING_POSTGRES_CONTAINER}"
		exit 1
	fi
	# Launch postgres using Docker
	docker run \
		-v ${VOLUME_PATH}:/var/lib/postgresql/data \
		-e POSTGRES_USER=${DB_USER} \
		-e POSTGRES_PASSWORD=${DB_PASSWORD} \
		-e POSTGRES_DB=${DB_NAME} \
		-p "${DB_PORT}":5432 \
		-d \
		--name "postgres_osm$(date '+%s')" \
		${IMAGE_NAME}:latest -N 1000
     	#                    ^ Increased maximum number of connections for testing purposes
fi

# Keep pinging Postgres until it's ready to accept commands
export PGPASSWORD="${DB_PASSWORD}"
until psql -h "localhost" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c '\q'; do
	>&2 echo "Postgres is still unavailable - sleeping"
	sleep 1
done
>&2 echo "Postgres is up and running on port ${DB_PORT}"
