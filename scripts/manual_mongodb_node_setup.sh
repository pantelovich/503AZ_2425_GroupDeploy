#!/bin/bash
set -euo pipefail

# Run on each MongoDB EC2 instance after the stack is created.
# Example:
#   sudo ./manual_mongodb_node_setup.sh 10.0.10.10 MySharedReplicaKey1234567890

PRIVATE_IP="${1:-}"
REPLICA_KEY="${2:-}"

if [ -z "$PRIVATE_IP" ] || [ -z "$REPLICA_KEY" ]; then
  echo "Usage: sudo $0 <node-private-ip> <shared-replica-key>"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script with sudo."
  exit 1
fi

cp /etc/mongod.conf /etc/mongod.conf.before-civicnexus
printf '%s\n' "$REPLICA_KEY" > /etc/mongo-keyfile
chmod 400 /etc/mongo-keyfile
chown mongod:mongod /etc/mongo-keyfile

sed -i "s/^  bindIp:.*/  bindIp: 127.0.0.1,${PRIVATE_IP}/" /etc/mongod.conf
sed -i '/^replication:/,$d' /etc/mongod.conf
cat >> /etc/mongod.conf <<'EOF'

replication:
  replSetName: rs0

security:
  authorization: enabled
  keyFile: /etc/mongo-keyfile
EOF

systemctl enable mongod
systemctl restart mongod
systemctl status mongod --no-pager

echo "MongoDB node configured for ${PRIVATE_IP}."
