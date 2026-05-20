#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"

echo "AWS account"
aws sts get-caller-identity --output table

echo
echo "CloudFormation stacks"
aws cloudformation list-stacks \
  --region "$REGION" \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE CREATE_IN_PROGRESS UPDATE_IN_PROGRESS DELETE_IN_PROGRESS ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE \
  --query "StackSummaries[].{Name:StackName,Status:StackStatus,Created:CreationTime}" \
  --output table

echo
echo "EC2 instances that can affect lab credit"
aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,InstanceId:InstanceId,Type:InstanceType,State:State.Name,PublicIp:PublicIpAddress}" \
  --output table

echo
echo "NAT gateways"
aws ec2 describe-nat-gateways \
  --region "$REGION" \
  --filter "Name=state,Values=pending,available,deleting" \
  --query "NatGateways[].{NatGatewayId:NatGatewayId,State:State,SubnetId:SubnetId}" \
  --output table

echo
echo "Elastic IPs"
aws ec2 describe-addresses \
  --region "$REGION" \
  --query "Addresses[].{PublicIp:PublicIp,AllocationId:AllocationId,AssociationId:AssociationId,InstanceId:InstanceId}" \
  --output table

echo
echo "Note: delete unused coursework stacks after evidence is saved."
