# Manual MongoDB and OpenVPN Setup Runbook

This runbook is for the final-style stack where CloudFormation creates the AWS infrastructure and installs basic packages, but does not complete the hard configuration automatically.

CloudFormation is responsible for:

- VPC, public/private subnets, NAT and route tables
- web EC2, MongoDB EC2 instances and optional OpenVPN EC2
- security groups and NACLs
- MongoDB/OpenVPN package installation
- web dashboard and 402 integration files

The student/manual work is responsible for:

- OpenVPN certificates, server profile, routing and client profile
- MongoDB bind IP, keyfile, authentication and rs0 replica set
- MongoDB admin/app users
- CivicNexus seed data
- backup/restore evidence

Do not record real passwords, private keys, AWS credentials or OpenVPN client profile contents in GitHub.

## 1. Stack Parameters

Use `cfstack-secure.yml` from the working branch.

Recommended values:

- `EnableOpenVPN`: `true` when collecting VPN evidence
- `AdminAccessCidr`: your current public IP with `/32` where possible
- `MongoAppUsername`: `civicApp`
- `MongoAppPassword`: a lab password that matches the manual MongoDB app user
- `EnableEvidenceServices`: `false` unless the lab allows the required IAM/S3 resources

MongoDB admin credentials and the replica key are created manually after deployment, not passed through CloudFormation.

## 2. Optional Package Installer

CloudFormation should already install the required packages. If a package install needs to be repeated manually, use:

```bash
scripts/install_database_vpn_packages.sh mongodb
scripts/install_database_vpn_packages.sh openvpn
```

This script only installs packages. It does not configure MongoDB or OpenVPN.

## 3. OpenVPN Manual Setup Summary

Run these steps on the OpenVPN EC2 instance.

1. Confirm packages and folders exist:

```bash
sudo dnf install -y openvpn iptables-services openssl
sudo mkdir -p /etc/openvpn/server /etc/openvpn/client-config /etc/openvpn/pki
```

2. Generate a CA, server certificate, client certificate, DH parameters and TLS auth key using `openssl` and `openvpn --genkey`.

3. Create `/etc/openvpn/server/server.conf` with:

```text
port 1194
proto udp
dev tun
topology subnet
server 10.8.0.0 255.255.255.0
push "route 10.0.0.0 255.255.0.0"
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
user nobody
group nobody
status /var/log/openvpn-status.log
verb 3
```

4. Enable IPv4 forwarding:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-civicnexus-vpn.conf
sudo sysctl --system
```

5. Add the NAT rule from the VPN network to the VPC:

```bash
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -d 10.0.0.0/16 -j MASQUERADE
sudo iptables-save | sudo tee /etc/sysconfig/iptables
sudo systemctl enable iptables
sudo systemctl restart iptables
```

6. Build `/home/ec2-user/civicnexus-vpn.ovpn` manually with the CA, client certificate, client key and TLS auth key embedded.

7. Start OpenVPN:

```bash
sudo systemctl enable openvpn-server@server
sudo systemctl restart openvpn-server@server
sudo systemctl status openvpn-server@server --no-pager -l
```

8. Download the `.ovpn` profile to Windows and test:

```powershell
Test-NetConnection 10.0.10.10 -Port 27017
```

Expected result after MongoDB is running: `TcpTestSucceeded: True`.

## 4. MongoDB Manual Node Setup

Run on each MongoDB node with the correct private IP.

- mongo1: `10.0.10.10`
- mongo2: `10.0.11.10`
- mongo3: `10.0.12.10`

Create one strong replica key manually. The same key must be used on all three nodes. Do not screenshot or commit it.

Example per node:

```bash
PRIVATE_IP="10.0.10.10"
read -s -p "Replica key: " REPLICA_KEY
echo

sudo cp /etc/mongod.conf /etc/mongod.conf.before-civicnexus
printf '%s\n' "$REPLICA_KEY" | sudo tee /etc/mongo-keyfile >/dev/null
sudo chmod 400 /etc/mongo-keyfile
sudo chown mongod:mongod /etc/mongo-keyfile

sudo sed -i "s/^  bindIp:.*/  bindIp: 127.0.0.1,${PRIVATE_IP}/" /etc/mongod.conf
sudo sed -i '/^replication:/,$d' /etc/mongod.conf
sudo tee -a /etc/mongod.conf >/dev/null <<'EOF'

replication:
  replSetName: rs0

security:
  authorization: enabled
  keyFile: /etc/mongo-keyfile
EOF

sudo systemctl enable mongod
sudo systemctl restart mongod
sudo systemctl status mongod --no-pager -l
sudo ss -lntp | grep 27017
sudo grep -nE "bindIp|replSetName|authorization|keyFile" /etc/mongod.conf
```

Change `PRIVATE_IP` for mongo2 and mongo3 before running the same commands.

## 5. Initialise Replica Set on mongo1

Run on mongo1 only after all three MongoDB services are running.

```bash
mongosh "mongodb://127.0.0.1:27017/admin" --quiet --eval 'rs.initiate({_id:"rs0",members:[{_id:0,host:"10.0.10.10:27017",priority:2},{_id:1,host:"10.0.11.10:27017"},{_id:2,host:"10.0.12.10:27017"}]})'
```

Check status:

```bash
mongosh "mongodb://127.0.0.1:27017/admin" --quiet --eval 'rs.status().members.forEach(m => print(m.name, m.stateStr, m.health))'
```

Expected:

```text
10.0.10.10:27017 PRIMARY 1
10.0.11.10:27017 SECONDARY 1
10.0.12.10:27017 SECONDARY 1
```

## 6. Create Users

Create the admin user first, then the app user.

```bash
mongosh "mongodb://127.0.0.1:27017/admin?replicaSet=rs0"
```

Inside `mongosh`:

```javascript
use admin
db.createUser({
  user: "mongoAdmin",
  pwd: passwordPrompt(),
  roles: [{ role: "root", db: "admin" }]
})

use civicnexus
db.createUser({
  user: "civicApp",
  pwd: passwordPrompt(),
  roles: [{ role: "readWrite", db: "civicnexus" }]
})
```

The `civicApp` password must match the `MongoAppPassword` value entered in CloudFormation, because the web dashboard uses that account.

## 7. Seed Data

Log in as the app user:

```bash
mongosh -u civicApp -p --authenticationDatabase civicnexus 127.0.0.1:27017/civicnexus
```

Insert the required CivicNexus collections:

```javascript
db.urban_environment_data.drop()
db.personnel_data.drop()
db.system_operational_logs.drop()

db.urban_environment_data.insertMany([
  {
    record_id: "traffic-flow-001",
    data_type: "traffic_flow_monitor",
    location: "Central Avenue / Sector 4",
    timestamp: new Date("2026-04-29T08:15:00Z"),
    reading_value: 428,
    unit: "vehicles/hour",
    metadata: {
      sensor_vendor: "CivicSense",
      status: "normal"
    }
  },
  {
    record_id: "air-quality-014",
    data_type: "air_quality_reading",
    location: "Riverside Monitoring Station",
    timestamp: new Date("2026-04-29T08:20:00Z"),
    reading_value: 41,
    unit: "AQI",
    metadata: {
      pm25: 12,
      pm10: 18,
      status: "good"
    }
  }
])

db.personnel_data.insertMany([
  {
    employee_id: "CN-001",
    name: "Dr. Maya Patel",
    job_role: "Urban Planner",
    contact: "maya.patel@civicnexus.local",
    security_clearance: "Level 3"
  },
  {
    employee_id: "CN-014",
    name: "Jordan Ellis",
    job_role: "Field Technician",
    contact: "jordan.ellis@civicnexus.local",
    security_clearance: "Level 2"
  }
])

db.system_operational_logs.insertMany([
  {
    log_id: "log-traffic-9001",
    timestamp: new Date("2026-04-29T08:25:00Z"),
    subsystem: "Traffic Light Control",
    event_type: "sequence_update",
    details: {
      junction: "A12",
      plan: "peak_morning_adjustment",
      green_seconds: 42
    }
  },
  {
    log_id: "log-waste-9002",
    timestamp: new Date("2026-04-29T08:40:00Z"),
    subsystem: "Waste Management Dispatch",
    event_type: "route_optimised",
    details: {
      district: "North Dock",
      crew_id: "WM-07",
      pickup_priority: "high"
    }
  },
  {
    log_id: "log-transport-9003",
    timestamp: new Date("2026-04-29T08:55:00Z"),
    subsystem: "Public Transport Dispatch",
    event_type: "service_alert",
    details: {
      line: "TR-16",
      status: "minor_delay",
      reason: "signal_check_in_progress"
    }
  }
])
```

Check the counts:

```javascript
print("urban_environment_data:", db.urban_environment_data.countDocuments())
print("personnel_data:", db.personnel_data.countDocuments())
print("system_operational_logs:", db.system_operational_logs.countDocuments())
```

## 8. Backup and Restore Evidence

Run a local dump and restore check using the admin account. Do not show the password in screenshots.

```bash
read -s -p "Mongo admin password: " MONGO_PWD
echo
ADMIN_URI="mongodb://mongoAdmin:${MONGO_PWD}@10.0.10.10:27017,10.0.11.10:27017,10.0.12.10:27017/admin?authSource=admin&replicaSet=rs0"
mongodump --uri "$ADMIN_URI" --db civicnexus --archive=/tmp/civicnexus-backup.archive
mongorestore --uri "$ADMIN_URI" --archive=/tmp/civicnexus-backup.archive --nsFrom='civicnexus.*' --nsTo='civicnexus_restore_check.*' --drop
mongosh "$ADMIN_URI" --quiet --eval 'const d=db.getSiblingDB("civicnexus_restore_check"); printjson({urban:d.urban_environment_data.countDocuments(), personnel:d.personnel_data.countDocuments(), logs:d.system_operational_logs.countDocuments()}); d.dropDatabase();'
unset MONGO_PWD ADMIN_URI
```

## 9. Final Evidence Checks

Keep screenshots of:

- EC2 list showing MongoDB nodes have no public IPv4 address
- MongoDB security group inbound rules for TCP 27017 from security groups only
- `mongod` service running
- `mongod.conf` showing bind IP, rs0, authorization and keyFile
- `rs.status()` showing one PRIMARY and two SECONDARY nodes
- OpenVPN connected and `Test-NetConnection 10.0.10.10 -Port 27017` succeeding
- backup/restore command output
