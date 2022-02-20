#!/usr/bin/env bash
set -x
set -eo pipefail

printf -v date '%(%Y%m%d)T' -1

IMAGE_NAME='osm2pgsql'
IMAGE_PRESENT=$(docker images ${IMAGE_NAME} --format '{{.ID}}')
DIR=${0%/*}
DOCKERFILE="Dockerfile-osm2pgsql"
OSM_DIR="$PWD/data/maps"
OSM_FILE="peru-latest.osm.pbf"
OSM_DB="osm"
RUNNING_POSTGRES_CONTAINER=$(docker ps --filter 'name=postgres_osm' --format '{{.ID}}')


if [[ -n ${FORCE_BUILD} ]] || [[ -z "${IMAGE_PRESENT}" ]]
then
	echo "Building image..."
	docker build -t ${IMAGE_NAME}:${date} -f $DIR/${DOCKERFILE} $DIR
	docker build -t ${IMAGE_NAME}:latest -f $DIR/${DOCKERFILE} $DIR
else
	echo "Using existing image..."
fi

if [[ -z "${RUNNING_POSTGRES_CONTAINER}" ]]
then
	echo >&2 "No postgres instance is running..."
else
	docker run --rm -it \
		--link ${RUNNING_POSTGRES_CONTAINER}:pg \
		-v "${OSM_DIR}:/osm" \
		--name "osm2pgsql_$(date '+%s')" \
		${IMAGE_NAME}:latest \
		sh -c 'osm2pgsql --create --slim --hstore --cache 2000 \
			--database "postgres://$PG_ENV_POSTGRES_USER:$PG_ENV_POSTGRES_PASSWORD@pg:$PG_PORT_5432_TCP_PORT/'${OSM_DB}'" \
			/osm/'${OSM_FILE}''

	echo "OSM migrated to postgres :)"
fi

