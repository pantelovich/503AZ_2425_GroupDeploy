#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-${STACK_NAME:-}}"
OUT_DIR="${2:-${OUT_DIR:-evidence}}"
REGION="${AWS_REGION:-us-east-1}"
TODAY="$(date +%F)"

if [[ -z "$STACK_NAME" ]]; then
  echo "Usage: $0 <stack-name> [output-dir]" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

MONGO_IP="${MONGO_IP:-}"

if [[ -z "$MONGO_IP" ]]; then
  MONGO_IP="$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='MongoServerPublicIP'].OutputValue" \
    --output text)"
fi

if [[ -z "$MONGO_IP" || "$MONGO_IP" == "None" ]]; then
  echo "Could not find MongoServerPublicIP in stack outputs" >&2
  echo "If CloudFormation read access is blocked, rerun with MONGO_IP set." >&2
  exit 1
fi

MONGO_INSTANCE_ID="${MONGO_INSTANCE_ID:-}"
MONGO_SG_ID="${MONGO_SG_ID:-}"

if [[ -z "$MONGO_INSTANCE_ID" ]]; then
  MONGO_INSTANCE_ID="$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=ip-address,Values=$MONGO_IP" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text 2>/dev/null || true)"
fi

if [[ -n "$MONGO_INSTANCE_ID" && "$MONGO_INSTANCE_ID" != "None" && -z "$MONGO_SG_ID" ]]; then
  MONGO_SG_ID="$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$MONGO_INSTANCE_ID" \
    --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
    --output text 2>/dev/null || true)"
fi

echo "$MONGO_IP" > "$OUT_DIR/${TODAY}_mongodb_public_ip.txt"
echo "$MONGO_INSTANCE_ID" > "$OUT_DIR/${TODAY}_mongodb_instance_id.txt"
echo "$MONGO_SG_ID" > "$OUT_DIR/${TODAY}_mongodb_security_group_id.txt"

if [[ -n "$MONGO_INSTANCE_ID" && "$MONGO_INSTANCE_ID" != "None" ]]; then
  aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$MONGO_INSTANCE_ID" \
    --query "Reservations[0].Instances[0].{InstanceId:InstanceId,PublicIp:PublicIpAddress,PrivateIp:PrivateIpAddress,SubnetId:SubnetId,VpcId:VpcId,State:State.Name,SecurityGroups:SecurityGroups}" \
    --output json > "$OUT_DIR/${TODAY}_mongodb_instance_details.json" || true
else
  echo "MongoDB instance details skipped because EC2 lookup was not available." > "$OUT_DIR/${TODAY}_mongodb_instance_details.json"
fi

if [[ -n "$MONGO_SG_ID" && "$MONGO_SG_ID" != "None" ]]; then
  aws ec2 describe-security-groups \
    --region "$REGION" \
    --group-ids "$MONGO_SG_ID" \
    --query "SecurityGroups[0].{GroupId:GroupId,GroupName:GroupName,Ingress:IpPermissions,Egress:IpPermissionsEgress}" \
    --output json > "$OUT_DIR/${TODAY}_mongodb_sg_rules.json" || true

  aws ec2 describe-security-groups \
    --region "$REGION" \
    --group-ids "$MONGO_SG_ID" \
    --query "SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[*].CidrIp]" \
    --output table > "$OUT_DIR/${TODAY}_mongodb_sg_inbound_summary.txt" || true
else
  echo "MongoDB security group details skipped because SG lookup was not available." > "$OUT_DIR/${TODAY}_mongodb_sg_rules.json"
  echo "MongoDB security group summary skipped because SG lookup was not available." > "$OUT_DIR/${TODAY}_mongodb_sg_inbound_summary.txt"
fi

if command -v mongosh >/dev/null 2>&1; then
  mongosh "mongodb://${MONGO_IP}:27017" --quiet --eval \
    'const dbs=db.adminCommand({listDatabases:1}); printjson(dbs.databases.map(d => ({name:d.name,sizeOnDisk:d.sizeOnDisk}))); const d=db.getSiblingDB("civicnexus"); printjson({urban:d.urban_environmental_data.countDocuments(), personnel:d.personnel_data.countDocuments(), logs:d.system_logs.countDocuments()});' \
    > "$OUT_DIR/${TODAY}_mongodb_connection_check.txt" || true
else
  echo "mongosh not installed, database connection check skipped." > "$OUT_DIR/${TODAY}_mongodb_connection_check.txt"
fi

cat > "$OUT_DIR/${TODAY}_mongodb_evidence_summary.md" <<EOF
# MongoDB Evidence Summary

Stack:

\`\`\`text
$STACK_NAME
\`\`\`

MongoDB public IP:

\`\`\`text
$MONGO_IP
\`\`\`

Files collected:

1. ${TODAY}_mongodb_public_ip.txt
2. ${TODAY}_mongodb_instance_id.txt
3. ${TODAY}_mongodb_security_group_id.txt
4. ${TODAY}_mongodb_instance_details.json
5. ${TODAY}_mongodb_sg_rules.json
6. ${TODAY}_mongodb_sg_inbound_summary.txt
7. ${TODAY}_mongodb_connection_check.txt

What this supports:

1. MongoDB has a public IP.
2. MongoDB security group rules can be checked from AWS evidence.
3. The database can be queried using the current public endpoint.
4. The seeded CivicNexus collections contain data.
EOF

echo "Database evidence saved in $OUT_DIR"
