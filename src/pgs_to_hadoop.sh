#!/bin/bash
set -e

export SQOOP_CONNECT="jdbc:postgresql://13.42.152.118:5432/testdb"
export SQOOP_USER="admin"
export SQOOP_PASS="admin123"
export TARGET_BASE_DIR=/tmp/aparna/tfl_proj/tfl_data

TABLES=(
  "dim_stations"
  "fact_station_lines"
  "fact_passenger_entry_exit"
  "dim_networks"
  "dim_lines"
  "dim_date"
)

for TABLE_NAME in "${TABLES[@]}"
do
  TARGET_DIR="$TARGET_BASE_DIR/$TABLE_NAME"

  echo "Starting $TABLE_NAME import..."

  sqoop import \
    -D mapreduce.framework.name=local \
    --connect "$SQOOP_CONNECT" \
    --username "$SQOOP_USER" \
    --password "$SQOOP_PASS" \
    --table "$TABLE_NAME" \
    --target-dir "$TARGET_DIR" \
    --delete-target-dir \
    -m 1

  echo "$TABLE_NAME import completed"
done

echo "All Sqoop jobs completed successfully"