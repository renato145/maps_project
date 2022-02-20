# Maps Project

## Download map data to psql
- https://osm2pgsql.org/
- Download Peru data to `data/maps/peru-latest.osm.pbf`:
  - Download extract from https://download.geofabrik.de/south-america/peru.html

## OSM2PGSQL
- Start database: `./scripts/init_db.sh`
- Get map data: `./scripts/get_map_data.sh`

## Todo
- Automatically update map data (https://osm2pgsql.org/doc/manual.html#getting-and-preparing-osm-data).
