#!/usr/bin/env bash
set -x
set -eo pipefail

# Check if a custom user has been set, otherwise default to 'postgres'
DB_USER=${POSTGRES_USER:=postgres}
# Check if a custom password has been set, otherwise default to 'password'
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
# Check if a custom port has been set, otherwise default to '5432'
DB_PORT="${POSTGRES_PORT:=5432}"
# Check if a custom database name has been set, otherwise default to 'osm_peru'
DB_NAME=${POSTGRES_DB:=osm_peru}
# Check if a custom ram has been set, otherwise default to '8'
RAM=${RAM:=8}
RUNNING_POSTGRES_CONTAINER=$(docker ps --filter 'name=pgosm' --format '{{.ID}}')
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}"
printf -v date '%(%Y-%m-%d)T' -1
SQL_FILE="data/maps/south-america-peru-default-$date.sql"

if [[ -z "${RUNNING_POSTGRES_CONTAINER}" ]]
then
	echo >&2 "No postgres instance is running..."
else
	# Check if file already exists
	if [[ -f ${SQL_FILE} ]]
	then
		echo "Using already existing ${SQL_FILE}..."
	else
		# Get data and process to sql file
		docker exec -it pgosm \
			python3 docker/pgosm_flex.py \
			--ram=$RAM \
			--region=south-america \
			--subregion=peru
	fi
	
	# Drop / create new database
	psql "${DB_URL}/postgres" -c "DROP DATABASE IF EXISTS ${DB_NAME};"
	psql "${DB_URL}/postgres" -c "CREATE DATABASE ${DB_NAME}"
	psql "${DB_URL}/${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;"

	# Load sql file to database
	psql "${DB_URL}/${DB_NAME}" -f ${SQL_FILE}
	echo "${SQL_FILE} loaded into postgres db: ${DB_NAME}"
fi
