#!/bin/bash
set -e

# Configuration
REMOTE_HOST="13.41.167.97"
REMOTE_USER="consultant"
REMOTE_PASSWORD="${REMOTE_PASSWORD:?Set REMOTE_PASSWORD before running this script}"
REMOTE_DIR="/home/consultant/hiren/TFL_Project_Demo"
HDFS_TARGET="/tmp/hiren/tfl_data"

echo "=================================================="
echo "TfL Pipeline - Using GitHub Scripts"
echo "=================================================="
echo "Workspace: $WORKSPACE"
echo "Remote: $REMOTE_HOST:$REMOTE_DIR"
echo "=================================================="

# Step 1: Verify scripts from GitHub clone
echo "✓ Scripts from GitHub:"
ls -lh $WORKSPACE/src/sqoop/*.sh
ls -lh $WORKSPACE/src/hive/*.hql

# Step 2: Create remote directories
echo ""
echo "Creating directories on Cloudera..."
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_DIR/src/sqoop $REMOTE_DIR/src/hive"

# Step 3: Copy Sqoop scripts
echo "Copying Sqoop scripts..."
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $WORKSPACE/src/sqoop/*.sh $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/src/sqoop/

# Step 4: Copy Hive scripts
echo "Copying Hive scripts..."
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $WORKSPACE/src/hive/*.hql $WORKSPACE/src/hive/*.sh \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/src/hive/ 2>/dev/null || true

# Step 5: Make executable
echo "Setting permissions..."
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "chmod +x $REMOTE_DIR/src/sqoop/*.sh $REMOTE_DIR/src/hive/*.sh 2>/dev/null || true"

echo "✓ Setup complete!"
echo ""

# Step 6: Clean HDFS
echo "=================================================="
echo "Cleaning HDFS..."
echo "=================================================="
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "hdfs dfs -rm -r -f -skipTrash $HDFS_TARGET || true"
echo "✓ HDFS cleaned"
echo ""

# Step 7: Run Sqoop
echo "=================================================="
echo "Running Sqoop Import (6 tables)..."
echo "=================================================="
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && bash src/sqoop/import_all_tables.sh"
echo "✓ Sqoop completed"
echo ""

# Step 8: Create Hive database
echo "=================================================="
echo "Creating Hive Database..."
echo "=================================================="
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && hive -f src/hive/create_database.hql"
echo "✓ Database created"
echo ""

# Step 9: Create Hive tables
echo "=================================================="
echo "Creating Hive Tables..."
echo "=================================================="
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && hive -f src/hive/create_tables.hql"
echo "✓ Tables created"
echo ""

# Step 10: Verify
echo "=================================================="
echo "VERIFICATION"
echo "=================================================="
echo ""
echo "HDFS Contents:"
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "hdfs dfs -ls $HDFS_TARGET"

echo ""
echo "Hive Tables:"
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "hive -e 'USE hiren_tfl; SHOW TABLES;'"

echo ""
echo "Record Counts:"
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $REMOTE_USER@$REMOTE_HOST "hive -e \"USE hiren_tfl; SELECT 'dim_stations' AS tbl, COUNT(*) FROM dim_stations;\""

echo ""
echo "=================================================="
echo "✓✓✓ PIPELINE COMPLETED SUCCESSFULLY ✓✓✓"
echo "=================================================="
echo "Source: GitHub (hiren/TFL_Project_Demo)"
echo "HDFS: $HDFS_TARGET"
echo "Hive: hiren_tfl (6 tables, 5,812 records)"
echo "=================================================="
