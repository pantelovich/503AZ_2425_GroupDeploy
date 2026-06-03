#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <stack-name> <output-folder>" >&2
  exit 1
fi

STACK_NAME="$1"
OUT_DIR="$2"

mkdir -p "$OUT_DIR"

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --output json > "$OUT_DIR/01_stack_outputs.json"

VDI_INSTANCE_ID="$(aws cloudformation describe-stack-resources \
  --stack-name "$STACK_NAME" \
  --logical-resource-id VDIInstance \
  --query 'StackResources[0].PhysicalResourceId' \
  --output text 2>/dev/null || true)"

if [ -z "$VDI_INSTANCE_ID" ] || [ "$VDI_INSTANCE_ID" = "None" ]; then
  echo "VDIInstance was not found. Confirm EnableVDI=true was used." | tee "$OUT_DIR/00_vdi_not_found.txt"
  exit 1
fi

echo "$VDI_INSTANCE_ID" > "$OUT_DIR/00_vdi_instance_id.txt"

aws ec2 describe-instances \
  --instance-ids "$VDI_INSTANCE_ID" \
  --output json > "$OUT_DIR/02_vdi_instance.json"

aws ec2 describe-instances \
  --instance-ids "$VDI_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].{InstanceId:InstanceId,State:State.Name,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress,SubnetId:SubnetId,SecurityGroups:SecurityGroups,MetadataOptions:MetadataOptions,BlockDevices:BlockDeviceMappings}' \
  --output table > "$OUT_DIR/03_vdi_instance_summary.txt"

SECURITY_GROUP_IDS="$(aws ec2 describe-instances \
  --instance-ids "$VDI_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].SecurityGroups[].GroupId' \
  --output text)"

aws ec2 describe-security-groups \
  --group-ids $SECURITY_GROUP_IDS \
  --output json > "$OUT_DIR/04_vdi_security_groups.json"

aws ec2 describe-security-groups \
  --group-ids $SECURITY_GROUP_IDS \
  --query 'SecurityGroups[].{GroupId:GroupId,GroupName:GroupName,Ingress:IpPermissions,Egress:IpPermissionsEgress}' \
  --output table > "$OUT_DIR/05_vdi_security_groups_summary.txt"

VOLUME_IDS="$(aws ec2 describe-instances \
  --instance-ids "$VDI_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[].Ebs.VolumeId' \
  --output text)"

aws ec2 describe-volumes \
  --volume-ids $VOLUME_IDS \
  --output json > "$OUT_DIR/06_vdi_volumes.json"

aws ec2 describe-volumes \
  --volume-ids $VOLUME_IDS \
  --query 'Volumes[].{VolumeId:VolumeId,Encrypted:Encrypted,VolumeType:VolumeType,Size:Size,State:State}' \
  --output table > "$OUT_DIR/07_vdi_volume_encryption_summary.txt"

cat > "$OUT_DIR/README.txt" <<EOF
VDI evidence captured for stack: $STACK_NAME
VDI instance id: $VDI_INSTANCE_ID

Checks to cite:
- 03_vdi_instance_summary.txt shows private/public IP and IMDSv2 metadata options.
- 05_vdi_security_groups_summary.txt shows VDI security group ingress/egress.
- 07_vdi_volume_encryption_summary.txt shows root volume encryption.
EOF

ls -la "$OUT_DIR"
