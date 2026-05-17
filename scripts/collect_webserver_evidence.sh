#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-${STACK_NAME:-}}"
OUT_DIR="${2:-${OUT_DIR:-evidence}}"
REGION="${AWS_REGION:-us-east-1}"
TODAY="$(date +%F)"

if [[ -z "$STACK_NAME" ]]; then
  echo "Usage: $0 <stack-name> [output-dir]" >&2
  echo "Example: $0 group01-civicnexus-stack evidence" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

write_json() {
  local name="$1"
  shift
  aws "$@" --region "$REGION" --output json > "$OUT_DIR/${TODAY}_${name}.json"
}

write_text() {
  local name="$1"
  shift
  aws "$@" --region "$REGION" --output table > "$OUT_DIR/${TODAY}_${name}.txt"
}

echo "Collecting stack outputs for $STACK_NAME"
write_json "stack_outputs" cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs"

WEB_IP="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='WebServerPublicIP'].OutputValue" \
  --output text)"

CURRENT_WEB_IP="$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" "Name=tag:Name,Values=*web-server*" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text 2>/dev/null || true)"

if [[ -n "$CURRENT_WEB_IP" && "$CURRENT_WEB_IP" != "None" ]]; then
  WEB_IP="$CURRENT_WEB_IP"
fi

if [[ -z "$WEB_IP" || "$WEB_IP" == "None" ]]; then
  echo "Could not find WebServerPublicIP in stack outputs" >&2
  exit 1
fi

WEB_INSTANCE_ID="$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=ip-address,Values=$WEB_IP" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)"

WEB_SG_ID="$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$WEB_INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
  --output text)"

echo "$WEB_IP" > "$OUT_DIR/${TODAY}_webserver_public_ip.txt"
echo "$WEB_INSTANCE_ID" > "$OUT_DIR/${TODAY}_webserver_instance_id.txt"
echo "$WEB_SG_ID" > "$OUT_DIR/${TODAY}_webserver_security_group_id.txt"

write_json "webserver_instance_details" ec2 describe-instances \
  --instance-ids "$WEB_INSTANCE_ID" \
  --query "Reservations[0].Instances[0].{InstanceId:InstanceId,PublicIp:PublicIpAddress,PrivateIp:PrivateIpAddress,SubnetId:SubnetId,VpcId:VpcId,State:State.Name,SecurityGroups:SecurityGroups}"

write_json "webserver_sg_rules" ec2 describe-security-groups \
  --group-ids "$WEB_SG_ID" \
  --query "SecurityGroups[0].{GroupId:GroupId,GroupName:GroupName,Ingress:IpPermissions,Egress:IpPermissionsEgress}"

write_text "webserver_instance_summary" ec2 describe-instances \
  --instance-ids "$WEB_INSTANCE_ID" \
  --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,SubnetId,VpcId]"

write_text "webserver_sg_inbound_summary" ec2 describe-security-groups \
  --group-ids "$WEB_SG_ID" \
  --query "SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[*].CidrIp]"

write_text "webserver_metadata_options" ec2 describe-instances \
  --instance-ids "$WEB_INSTANCE_ID" \
  --query "Reservations[0].Instances[0].MetadataOptions.[HttpTokens,HttpEndpoint]"

echo "Checking dashboard HTTP response"
HEADER_FILE="$OUT_DIR/${TODAY}_dashboard_http_headers.txt"
HOME_FILE="$OUT_DIR/${TODAY}_dashboard_homepage.html"
HEALTH_FILE="$OUT_DIR/${TODAY}_health_check.txt"
CONTROL_CHECK_FILE="$OUT_DIR/${TODAY}_webserver_control_checks.txt"

curl -I --max-time 10 "http://$WEB_IP" > "$HEADER_FILE" || true
curl --max-time 15 "http://$WEB_IP" > "$HOME_FILE" || true
curl --max-time 10 "http://$WEB_IP/health.php" > "$HEALTH_FILE" || true

{
  echo "Webserver control checks"
  echo "Date: $TODAY"
  echo "Stack: $STACK_NAME"
  echo "Web IP: $WEB_IP"
  echo

  echo "Security headers:"
  for header in \
    "X-Content-Type-Options: nosniff" \
    "X-Frame-Options: DENY" \
    "Referrer-Policy: no-referrer" \
    "Cache-Control: no-store"
  do
    if grep -qi "^$header" "$HEADER_FILE"; then
      echo "PASS - $header"
    else
      echo "CHECK - $header not found in response headers"
    fi
  done

  echo
  echo "Health endpoint:"
  if grep -qi "ok" "$HEALTH_FILE"; then
    echo "PASS - /health.php returned ok"
  else
    echo "CHECK - /health.php did not return ok"
  fi

  echo
  echo "Dashboard public data minimisation:"
  if grep -qi "Restricted from public dashboard view" "$HOME_FILE"; then
    echo "PASS - restricted data message is present"
  else
    echo "CHECK - restricted data message not found"
  fi

  if grep -qi "Personnel Data Summary" "$HOME_FILE"; then
    echo "PASS - personnel section is summary-based"
  else
    echo "CHECK - personnel summary heading not found"
  fi
} > "$CONTROL_CHECK_FILE"

cat > "$OUT_DIR/${TODAY}_webserver_evidence_summary.md" <<EOF
# Webserver Evidence Summary

Stack:

\`\`\`text
$STACK_NAME
\`\`\`

Webserver public IP:

\`\`\`text
$WEB_IP
\`\`\`

Files collected:

1. ${TODAY}_stack_outputs.json
2. ${TODAY}_webserver_instance_details.json
3. ${TODAY}_webserver_sg_rules.json
4. ${TODAY}_webserver_instance_summary.txt
5. ${TODAY}_webserver_sg_inbound_summary.txt
6. ${TODAY}_webserver_metadata_options.txt
7. ${TODAY}_dashboard_http_headers.txt
8. ${TODAY}_dashboard_homepage.html
9. ${TODAY}_health_check.txt
10. ${TODAY}_webserver_control_checks.txt

Manual screenshots still useful:

1. Webserver security group inbound rule in AWS console.
2. Webserver EC2 subnet and public IP in AWS console.
3. Dashboard homepage in browser.
4. Dashboard personnel summary showing public data minimisation.
5. Operational logs showing details restricted from public view.
EOF

echo "Evidence saved in $OUT_DIR"
