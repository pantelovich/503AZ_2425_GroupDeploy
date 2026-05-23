#!/bin/bash
set -euo pipefail

# Run on mongo1 after all three nodes have been configured with
# manual_mongodb_node_setup.sh.
#
# Required:
#   export MONGO_ADMIN_PASSWORD='your_admin_password'
#   export MONGO_APP_PASSWORD='your_app_password'
#
# Optional:
#   export BACKUP_BUCKET='your-s3-bucket-name'

PRIMARY_IP="${PRIMARY_IP:-10.0.10.10}"
SECONDARY_1_IP="${SECONDARY_1_IP:-10.0.11.10}"
SECONDARY_2_IP="${SECONDARY_2_IP:-10.0.12.10}"
ADMIN_USER="${MONGO_ADMIN_USER:-mongoAdmin}"
APP_USER="${MONGO_APP_USER:-civicApp}"
DB_NAME="${MONGO_DB_NAME:-civicnexus}"
ADMIN_PASSWORD="${MONGO_ADMIN_PASSWORD:-}"
APP_PASSWORD="${MONGO_APP_PASSWORD:-}"

if [ -z "$ADMIN_PASSWORD" ] || [ -z "$APP_PASSWORD" ]; then
  echo "Set MONGO_ADMIN_PASSWORD and MONGO_APP_PASSWORD before running this script."
  exit 1
fi

for host in "$PRIMARY_IP" "$SECONDARY_1_IP" "$SECONDARY_2_IP"; do
  for attempt in {1..30}; do
    if timeout 2 bash -c "</dev/tcp/${host}/27017" >/dev/null 2>&1; then
      break
    fi
    sleep 5
  done
done

mongosh "mongodb://${PRIMARY_IP}:27017/admin" --quiet --eval "rs.initiate({_id:'rs0',members:[{_id:0,host:'${PRIMARY_IP}:27017',priority:2},{_id:1,host:'${SECONDARY_1_IP}:27017'},{_id:2,host:'${SECONDARY_2_IP}:27017'}]})" || true

for attempt in {1..30}; do
  if mongosh "mongodb://${PRIMARY_IP}:27017/admin?replicaSet=rs0" --quiet --eval 'db.hello().isWritablePrimary' | grep -q true; then
    break
  fi
  sleep 5
done

cat > /tmp/civicnexus_users.js <<EOF
db = db.getSiblingDB('admin');
if (!db.getUser('${ADMIN_USER}')) {
  db.createUser({
    user: '${ADMIN_USER}',
    pwd: '${ADMIN_PASSWORD}',
    roles: [ { role: 'root', db: 'admin' } ]
  });
}

db = db.getSiblingDB('${DB_NAME}');
if (!db.getUser('${APP_USER}')) {
  db.createUser({
    user: '${APP_USER}',
    pwd: '${APP_PASSWORD}',
    roles: [ { role: 'readWrite', db: '${DB_NAME}' } ]
  });
}
EOF
mongosh "mongodb://${PRIMARY_IP}:27017/admin?replicaSet=rs0" /tmp/civicnexus_users.js
rm -f /tmp/civicnexus_users.js

cat > /tmp/civicnexus_seed.js <<'EOF'
db = db.getSiblingDB('civicnexus');

db.urban_environment_data.drop();
db.personnel_data.drop();
db.system_operational_logs.drop();

db.urban_environment_data.insertMany([
  {
    record_id: 'traffic-flow-001',
    data_type: 'traffic_flow_monitor',
    location: 'Central Avenue / Sector 4',
    timestamp: new Date('2026-04-29T08:15:00Z'),
    reading_value: 428,
    unit: 'vehicles/hour',
    metadata: { sensor_vendor: 'CivicSense', status: 'normal' }
  },
  {
    record_id: 'air-quality-014',
    data_type: 'air_quality_reading',
    location: 'Riverside Monitoring Station',
    timestamp: new Date('2026-04-29T08:20:00Z'),
    reading_value: 41,
    unit: 'AQI',
    metadata: { pm25: 12, pm10: 18, status: 'good' }
  }
]);

db.personnel_data.insertMany([
  {
    employee_id: 'CN-001',
    name: 'Dr. Maya Patel',
    job_role: 'Urban Planner',
    contact: 'maya.patel@civicnexus.local',
    security_clearance: 'Level 3'
  },
  {
    employee_id: 'CN-014',
    name: 'Jordan Ellis',
    job_role: 'Field Technician',
    contact: 'jordan.ellis@civicnexus.local',
    security_clearance: 'Level 2'
  }
]);

db.system_operational_logs.insertMany([
  {
    log_id: 'log-traffic-9001',
    timestamp: new Date('2026-04-29T08:25:00Z'),
    subsystem: 'Traffic Light Control',
    event_type: 'sequence_update',
    details: { junction: 'A12', plan: 'peak_morning_adjustment', green_seconds: 42 }
  },
  {
    log_id: 'log-waste-9002',
    timestamp: new Date('2026-04-29T08:40:00Z'),
    subsystem: 'Waste Management Dispatch',
    event_type: 'route_optimised',
    details: { district: 'North Dock', crew_id: 'WM-07', pickup_priority: 'high' }
  },
  {
    log_id: 'log-transport-9003',
    timestamp: new Date('2026-04-29T08:55:00Z'),
    subsystem: 'Public Transport Dispatch',
    event_type: 'service_alert',
    details: { line: 'TR-16', status: 'minor_delay', reason: 'signal_check_in_progress' }
  }
]);
EOF

APP_URI="mongodb://${APP_USER}:${APP_PASSWORD}@${PRIMARY_IP}:27017,${SECONDARY_1_IP}:27017,${SECONDARY_2_IP}:27017/${DB_NAME}?authSource=${DB_NAME}&replicaSet=rs0"
ADMIN_URI="mongodb://${ADMIN_USER}:${ADMIN_PASSWORD}@${PRIMARY_IP}:27017,${SECONDARY_1_IP}:27017,${SECONDARY_2_IP}:27017/admin?authSource=admin&replicaSet=rs0"

mongosh "$APP_URI" /tmp/civicnexus_seed.js
rm -f /tmp/civicnexus_seed.js

mongosh "$APP_URI" --quiet --eval 'db.runCommand({connectionStatus:1})'
mongosh "$ADMIN_URI" --quiet --eval 'rs.status().members.map(m => ({name:m.name,state:m.stateStr,health:m.health}))'

if [ -n "${BACKUP_BUCKET:-}" ]; then
  BACKUP_FILE="/tmp/civicnexus-initial-backup.archive"
  BACKUP_LOG="/var/log/civicnexus-backup-restore.log"
  {
    echo "CivicNexus MongoDB backup and restore check"
    date -u
    mongodump --uri "$ADMIN_URI" --db "$DB_NAME" --archive="$BACKUP_FILE"
    mongorestore --uri "$ADMIN_URI" --archive="$BACKUP_FILE" --nsFrom="${DB_NAME}.*" --nsTo="${DB_NAME}_restore_check.*" --drop
    mongosh "$ADMIN_URI" --quiet --eval "const d=db.getSiblingDB('${DB_NAME}_restore_check'); printjson({urban:d.urban_environment_data.countDocuments(), personnel:d.personnel_data.countDocuments(), logs:d.system_operational_logs.countDocuments()}); d.dropDatabase();"
    aws s3 cp "$BACKUP_FILE" "s3://${BACKUP_BUCKET}/mongodb/civicnexus-initial-backup.archive"
  } > "$BACKUP_LOG" 2>&1
  aws s3 cp "$BACKUP_LOG" "s3://${BACKUP_BUCKET}/mongodb/civicnexus-backup-restore.log"
fi

echo "MongoDB replica set, users and seed data are ready."
