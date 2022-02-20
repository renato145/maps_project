# Maps Project

## Download map data to psql
- https://osm2pgsql.org/
- Download Peru data to `data/maps/peru-latest.osm.pbf`:
  - Download extract from https://download.geofabrik.de/south-america/peru.html

## OSM2PGSQL
- Start database: `./scripts/init_db.sh`
- Run osm2pgsql: `./scripts/run_osm2pgsql.sh`

## Todo
- Automatically update map data.