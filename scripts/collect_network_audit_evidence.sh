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

STACK_ID="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].StackId" \
  --output text)"

FLOW_LOG_GROUP="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='VpcFlowLogGroupName'].OutputValue" \
  --output text 2>/dev/null || true)"

echo "$STACK_ID" > "$OUT_DIR/${TODAY}_stack_id.txt"
echo "${FLOW_LOG_GROUP:-None}" > "$OUT_DIR/${TODAY}_vpc_flow_log_group.txt"

aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "StackEvents[].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]" \
  --output table > "$OUT_DIR/${TODAY}_cloudformation_events.txt"

aws cloudtrail lookup-events \
  --region "$REGION" \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue="$STACK_NAME" \
  --max-results 50 \
  --output json > "$OUT_DIR/${TODAY}_cloudtrail_stack_events.json" 2>&1 || true

aws cloudtrail lookup-events \
  --region "$REGION" \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AuthorizeSecurityGroupIngress \
  --max-results 20 \
  --output json > "$OUT_DIR/${TODAY}_cloudtrail_sg_ingress_events.json" 2>&1 || true

if [[ -n "$FLOW_LOG_GROUP" && "$FLOW_LOG_GROUP" != "None" ]]; then
  aws logs describe-log-streams \
    --region "$REGION" \
    --log-group-name "$FLOW_LOG_GROUP" \
    --order-by LastEventTime \
    --descending \
    --max-items 5 \
    --output json > "$OUT_DIR/${TODAY}_vpc_flow_log_streams.json" 2>&1 || true

  aws logs filter-log-events \
    --region "$REGION" \
    --log-group-name "$FLOW_LOG_GROUP" \
    --filter-pattern ACCEPT \
    --max-items 20 \
    --output json > "$OUT_DIR/${TODAY}_vpc_flow_log_accept_examples.json" 2>&1 || true

  aws logs filter-log-events \
    --region "$REGION" \
    --log-group-name "$FLOW_LOG_GROUP" \
    --filter-pattern REJECT \
    --max-items 20 \
    --output json > "$OUT_DIR/${TODAY}_vpc_flow_log_reject_examples.json" 2>&1 || true
else
  echo "SKIPPED - stack does not output VpcFlowLogGroupName." \
    > "$OUT_DIR/${TODAY}_vpc_flow_log_accept_examples.json"
  echo "SKIPPED - stack does not output VpcFlowLogGroupName." \
    > "$OUT_DIR/${TODAY}_vpc_flow_log_reject_examples.json"
fi

cat > "$OUT_DIR/${TODAY}_network_audit_evidence_summary.md" <<EOF
# Network and Audit Evidence Summary

Stack:

\`\`\`text
$STACK_NAME
\`\`\`

Files collected:

1. ${TODAY}_stack_id.txt
2. ${TODAY}_vpc_flow_log_group.txt
3. ${TODAY}_cloudformation_events.txt
4. ${TODAY}_cloudtrail_stack_events.json
5. ${TODAY}_cloudtrail_sg_ingress_events.json
6. ${TODAY}_vpc_flow_log_streams.json
7. ${TODAY}_vpc_flow_log_accept_examples.json
8. ${TODAY}_vpc_flow_log_reject_examples.json

Use this evidence for:

1. CloudFormation deployment activity.
2. Security group change auditing.
3. VPC Flow Log monitoring.
4. Accepted and rejected traffic examples where available.
EOF

echo "Network and audit evidence saved in $OUT_DIR"
