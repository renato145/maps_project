#!/usr/bin/env bash
set -x
set -eo pipefail

RUNNING_POSTGRES_CONTAINER=$(docker ps --filter 'name=pgosm' --format '{{.ID}}')

docker run --rm -dt \
	-p 7800:7800 \
	--link ${RUNNING_POSTGRES_CONTAINER}:pg \
	-e DATABASE_URL=postgresql://postgres:password@pg/osm_peru \
	--name "pg_tileserv" \
	pramsey/pg_tileserv:latest
