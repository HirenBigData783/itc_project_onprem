#!/bin/bash
set -e

export SQOOP_CONNECT="jdbc:postgresql://13.42.152.118:5432/testdb"
export SQOOP_USER="${SQOOP_USER:?Set SQOOP_USER before running this script}"
export SQOOP_PASS="${SQOOP_PASS:?Set SQOOP_PASS before running this script}"
export TARGET_BASE_DIR=/tmp/hiren/tfl_proj/tfl_data
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HIVE_DDL_FILE="$SCRIPT_DIR/create_hive_tables.hql"

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
    --fields-terminated-by '\001' \
    --lines-terminated-by '\n' \
    --null-string '\\N' \
    --null-non-string '\\N' \
    -m 1

  echo "$TABLE_NAME import completed"
done

echo "All Sqoop jobs completed successfully"

echo "Creating Hive external tables..."

hive -f "$HIVE_DDL_FILE"

echo "Hive external tables created successfully"
