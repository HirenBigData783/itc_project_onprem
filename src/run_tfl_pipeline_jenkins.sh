#!/bin/bash
set -Eeuo pipefail

# ==================================================
# TfL Pipeline - Jenkins Linux Shell Script
# GitHub -> Cloudera -> Sqoop -> HDFS -> Hive
# ==================================================

# ------------------------------
# Configuration
# ------------------------------
REMOTE_HOST="${REMOTE_HOST:-13.41.167.97}"
REMOTE_USER="${REMOTE_USER:-consultant}"
REMOTE_DIR="${REMOTE_DIR:-/home/consultant/hiren/TFL_Project_Demo}"
HDFS_TARGET="${HDFS_TARGET:-/tmp/hiren/tfl_proj/tfl_data}"
HIVE_DB="${HIVE_DB:-tfl_proj_hiren}"

# Jenkins workspace fallback
WORKSPACE="${WORKSPACE:-$(pwd)}"

# IMPORTANT:
# Set REMOTE_PASSWORD in Jenkins as a secret/environment variable.
# Do not hardcode passwords in this script.
if [[ -z "${REMOTE_PASSWORD:-}" ]]; then
  echo "ERROR: REMOTE_PASSWORD is not set."
  echo "Set REMOTE_PASSWORD in Jenkins using Credentials Binding / Secret Text."
  exit 1
fi

if [[ -z "${SQOOP_USER:-}" ]]; then
  echo "ERROR: SQOOP_USER is not set."
  echo "Set SQOOP_USER in Jenkins using Credentials Binding / Secret Text."
  exit 1
fi

if [[ -z "${SQOOP_PASS:-}" ]]; then
  echo "ERROR: SQOOP_PASS is not set."
  echo "Set SQOOP_PASS in Jenkins using Credentials Binding / Secret Text."
  exit 1
fi

# ------------------------------
# Helper functions
# ------------------------------
log_section() {
  echo ""
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

check_local_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: Required command '$1' is not installed on Jenkins agent."
    exit 1
  fi
}

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

remote_exec() {
  local cmd="$1"
  sshpass -p "$REMOTE_PASSWORD" ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "$cmd"
}

remote_copy() {
  sshpass -p "$REMOTE_PASSWORD" scp $SSH_OPTS "$@"
}

# ------------------------------
# Pre-checks
# ------------------------------
log_section "TfL Pipeline - Starting"
echo "Workspace     : $WORKSPACE"
echo "Remote host   : $REMOTE_HOST"
echo "Remote user   : $REMOTE_USER"
echo "Remote dir    : $REMOTE_DIR"
echo "HDFS target   : $HDFS_TARGET"
echo "Hive database : $HIVE_DB"

log_section "Checking Jenkins agent tools"
check_local_command ssh
check_local_command scp
check_local_command sshpass
echo "Local tools OK."

log_section "Checking GitHub workspace files"

if [[ ! -d "$WORKSPACE/src/sqoop" ]]; then
  echo "ERROR: Missing directory: $WORKSPACE/src/sqoop"
  exit 1
fi

if [[ ! -f "$WORKSPACE/src/sqoop/pgs_to_hadoop.sh" ]]; then
  echo "ERROR: Missing file: $WORKSPACE/src/sqoop/pgs_to_hadoop.sh"
  exit 1
fi

if [[ ! -f "$WORKSPACE/src/sqoop/create_hive_tables.hql" ]]; then
  echo "ERROR: Missing file: $WORKSPACE/src/sqoop/create_hive_tables.hql"
  exit 1
fi

echo "Sqoop scripts:"
ls -lh "$WORKSPACE/src/sqoop/"*.sh

echo ""
echo "Hive HQL scripts:"
ls -lh "$WORKSPACE/src/sqoop/"*.hql

# ------------------------------
# Remote setup
# ------------------------------
log_section "Creating remote project directories"
remote_exec "mkdir -p '$REMOTE_DIR/src/sqoop'"
echo "Remote directories created."

log_section "Copying Sqoop scripts to Cloudera"
remote_copy "$WORKSPACE/src/sqoop/"*.sh "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/src/sqoop/"
echo "Sqoop scripts copied."

log_section "Copying Hive HQL scripts to Cloudera"
remote_copy "$WORKSPACE/src/sqoop/"*.hql "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/src/sqoop/"
echo "Hive HQL scripts copied."

log_section "Setting remote script permissions"
remote_exec "chmod +x '$REMOTE_DIR/src/sqoop/'*.sh 2>/dev/null || true"
echo "Permissions set."

# ------------------------------
# Remote environment checks
# ------------------------------
log_section "Checking remote Hadoop/Sqoop/Hive commands"
remote_exec "which hdfs && which hive && which sqoop"
echo "Remote commands available."

# ------------------------------
# Pipeline execution
# ------------------------------
log_section "Cleaning HDFS target"
remote_exec "hdfs dfs -rm -r -f -skipTrash '$HDFS_TARGET' || true"
echo "HDFS target cleaned."

log_section "Running Sqoop Import"
remote_exec "cd '$REMOTE_DIR' && SQOOP_USER='$SQOOP_USER' SQOOP_PASS='$SQOOP_PASS' bash src/sqoop/pgs_to_hadoop.sh"
echo "Sqoop import and Hive table creation completed."

# ------------------------------
# Verification
# ------------------------------
log_section "Verification - HDFS contents"
remote_exec "hdfs dfs -ls '$HDFS_TARGET'"

log_section "Verification - Hive tables"
remote_exec "hive -e 'USE $HIVE_DB; SHOW TABLES;'"

log_section "Verification - Record counts"
remote_exec "hive -e \"
USE $HIVE_DB;
SELECT 'dim_stations' AS table_name, COUNT(*) AS row_count FROM dim_stations;
SELECT 'dim_networks' AS table_name, COUNT(*) AS row_count FROM dim_networks;
SELECT 'fact_passenger_entry_exit' AS table_name, COUNT(*) AS row_count FROM fact_passenger_entry_exit;
\""

log_section "Pipeline completed successfully"
echo "Source workspace : $WORKSPACE"
echo "Remote directory : $REMOTE_DIR"
echo "HDFS target      : $HDFS_TARGET"
echo "Hive database    : $HIVE_DB"
echo "Status           : SUCCESS"
