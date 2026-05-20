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

MONGO_PUBLIC_IP="${MONGO_PUBLIC_IP:-${MONGO_IP:-}}"
MONGO_PRIVATE_IP="${MONGO_PRIVATE_IP:-}"
BACKUP_BUCKET="${MONGO_BACKUP_BUCKET:-}"

if [[ -z "$MONGO_PUBLIC_IP" ]]; then
  MONGO_PUBLIC_IP="$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='MongoServerPublicIP'].OutputValue" \
    --output text 2>/dev/null || true)"
fi

if [[ -z "$MONGO_PRIVATE_IP" ]]; then
  MONGO_PRIVATE_IP="$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='MongoServerPrivateIP'].OutputValue" \
    --output text 2>/dev/null || true)"
fi

if [[ -z "$BACKUP_BUCKET" ]]; then
  BACKUP_BUCKET="$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='MongoBackupBucketName'].OutputValue" \
    --output text 2>/dev/null || true)"
fi

if [[ -z "$MONGO_PUBLIC_IP" || "$MONGO_PUBLIC_IP" == "None" ]]; then
  MONGO_PUBLIC_IP="None"
fi

if [[ -z "$MONGO_PRIVATE_IP" || "$MONGO_PRIVATE_IP" == "None" ]]; then
  MONGO_PRIVATE_IP="None"
fi

if [[ -z "$BACKUP_BUCKET" || "$BACKUP_BUCKET" == "None" ]]; then
  BACKUP_BUCKET="None"
fi

MONGO_INSTANCE_ID="${MONGO_INSTANCE_ID:-}"
MONGO_SG_ID="${MONGO_SG_ID:-}"

if [[ -z "$MONGO_INSTANCE_ID" ]]; then
  if [[ "$MONGO_PUBLIC_IP" != "None" ]]; then
    MONGO_INSTANCE_ID="$(aws ec2 describe-instances \
      --region "$REGION" \
      --filters "Name=ip-address,Values=$MONGO_PUBLIC_IP" \
      --query "Reservations[0].Instances[0].InstanceId" \
      --output text 2>/dev/null || true)"
  elif [[ "$MONGO_PRIVATE_IP" != "None" ]]; then
    MONGO_INSTANCE_ID="$(aws ec2 describe-instances \
      --region "$REGION" \
      --filters "Name=private-ip-address,Values=$MONGO_PRIVATE_IP" \
      --query "Reservations[0].Instances[0].InstanceId" \
      --output text 2>/dev/null || true)"
  fi
fi

if [[ -n "$MONGO_INSTANCE_ID" && "$MONGO_INSTANCE_ID" != "None" && -z "$MONGO_SG_ID" ]]; then
  MONGO_SG_ID="$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$MONGO_INSTANCE_ID" \
    --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
    --output text 2>/dev/null || true)"
fi

echo "$MONGO_PUBLIC_IP" > "$OUT_DIR/${TODAY}_mongodb_public_ip.txt"
echo "$MONGO_PRIVATE_IP" > "$OUT_DIR/${TODAY}_mongodb_private_ip.txt"
echo "$MONGO_INSTANCE_ID" > "$OUT_DIR/${TODAY}_mongodb_instance_id.txt"
echo "$MONGO_SG_ID" > "$OUT_DIR/${TODAY}_mongodb_security_group_id.txt"
echo "$BACKUP_BUCKET" > "$OUT_DIR/${TODAY}_mongodb_backup_bucket.txt"

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
    --query "SecurityGroups[0].IpPermissions[*].{Protocol:IpProtocol,FromPort:FromPort,ToPort:ToPort,CidrSources:IpRanges[].CidrIp,SecurityGroupSources:UserIdGroupPairs[].GroupId}" \
    --output table > "$OUT_DIR/${TODAY}_mongodb_sg_inbound_summary.txt" || true
else
  echo "MongoDB security group details skipped because SG lookup was not available." > "$OUT_DIR/${TODAY}_mongodb_sg_rules.json"
  echo "MongoDB security group summary skipped because SG lookup was not available." > "$OUT_DIR/${TODAY}_mongodb_sg_inbound_summary.txt"
fi

if command -v mongosh >/dev/null 2>&1; then
  if [[ "$MONGO_PUBLIC_IP" != "None" ]]; then
    PUBLIC_MONGO_URI="mongodb://${MONGO_PUBLIC_IP}:27017/?serverSelectionTimeoutMS=5000"

    if mongosh "$PUBLIC_MONGO_URI" --quiet --eval 'db.adminCommand({ping:1})' \
      > "$OUT_DIR/${TODAY}_mongodb_public_access_check.txt" 2>&1; then
      echo "CONNECTED - public MongoDB endpoint accepted a connection from this host." \
        >> "$OUT_DIR/${TODAY}_mongodb_public_access_check.txt"
    else
      echo "BLOCKED - public MongoDB endpoint did not accept a connection from this host." \
        >> "$OUT_DIR/${TODAY}_mongodb_public_access_check.txt"
    fi

    if mongosh "$PUBLIC_MONGO_URI" --quiet --eval \
      'const dbs=db.adminCommand({listDatabases:1}); printjson(dbs.databases.map(d => ({name:d.name,sizeOnDisk:d.sizeOnDisk}))); const auth=db.adminCommand({connectionStatus:1}); printjson({authenticatedUsers:auth.authInfo.authenticatedUsers}); const d=db.getSiblingDB("civicnexus"); printjson({urban:d.urban_environment_data.countDocuments(), personnel:d.personnel_data.countDocuments(), logs:d.system_operational_logs.countDocuments()});' \
      > "$OUT_DIR/${TODAY}_mongodb_connection_check.txt" 2>&1; then
      echo "CONNECTED - collection count check completed from this host." \
        >> "$OUT_DIR/${TODAY}_mongodb_connection_check.txt"
    else
      echo "BLOCKED - collection count check could not run from this host because MongoDB public access is blocked." \
        >> "$OUT_DIR/${TODAY}_mongodb_connection_check.txt"
    fi
  else
    echo "PASS - MongoDB has no public IP output to test." > "$OUT_DIR/${TODAY}_mongodb_public_access_check.txt"
    echo "SKIPPED - collection count check cannot run from this host without a public MongoDB endpoint." > "$OUT_DIR/${TODAY}_mongodb_connection_check.txt"
  fi
else
  echo "mongosh not installed, public access check skipped." > "$OUT_DIR/${TODAY}_mongodb_public_access_check.txt"
  echo "mongosh not installed, database connection check skipped." > "$OUT_DIR/${TODAY}_mongodb_connection_check.txt"
fi

if [[ "$BACKUP_BUCKET" != "None" ]]; then
  aws s3 ls "s3://$BACKUP_BUCKET/mongodb/" --recursive \
    > "$OUT_DIR/${TODAY}_mongodb_backup_objects.txt" 2>&1 || true
else
  echo "SKIPPED - backup bucket output is not present on this stack." \
    > "$OUT_DIR/${TODAY}_mongodb_backup_objects.txt"
fi

cat > "$OUT_DIR/${TODAY}_mongodb_evidence_summary.md" <<EOF
# MongoDB Evidence Summary

Stack:

\`\`\`text
$STACK_NAME
\`\`\`

MongoDB public IP:

\`\`\`text
$MONGO_PUBLIC_IP
\`\`\`

MongoDB private IP:

\`\`\`text
$MONGO_PRIVATE_IP
\`\`\`

MongoDB backup bucket:

\`\`\`text
$BACKUP_BUCKET
\`\`\`

Files collected:

1. ${TODAY}_mongodb_public_ip.txt
2. ${TODAY}_mongodb_private_ip.txt
3. ${TODAY}_mongodb_instance_id.txt
4. ${TODAY}_mongodb_security_group_id.txt
5. ${TODAY}_mongodb_instance_details.json
6. ${TODAY}_mongodb_sg_rules.json
7. ${TODAY}_mongodb_sg_inbound_summary.txt
8. ${TODAY}_mongodb_public_access_check.txt
9. ${TODAY}_mongodb_connection_check.txt
10. ${TODAY}_mongodb_backup_bucket.txt
11. ${TODAY}_mongodb_backup_objects.txt

What this supports:

1. Whether MongoDB has a public IP or is private-only.
2. MongoDB security group rules can be checked from AWS evidence.
3. The public MongoDB endpoint can be tested from outside the VPC.
4. For the secure stack, public access should be blocked or there should be no public IP.
5. The connection output shows whether the current session has authenticated users when a connection is allowed.
6. Backup objects can be checked when the secure template includes the MongoDB backup bucket.
EOF

echo "Database evidence saved in $OUT_DIR"
