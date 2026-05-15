#!/usr/bin/env bash
set -euo pipefail

PROFILE="${AWS_PROFILE_NAME:-default}"
REGION_DEFAULT="us-east-1"
REPO="${GITHUB_REPOSITORY_NAME:-pantelovich/503AZ_2425_GroupDeploy}"

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

cat > "$TMP_FILE"

value_for() {
  local key="$1"
  awk -F= -v wanted="$key" '$1 == wanted {print substr($0, index($0, "=") + 1)}' "$TMP_FILE" | tail -n 1
}

ACCESS_KEY="$(value_for "aws_access_key_id")"
SECRET_KEY="$(value_for "aws_secret_access_key")"
SESSION_TOKEN="$(value_for "aws_session_token")"
REGION="$(awk '/^Region[[:space:]]+/ {print $2}' "$TMP_FILE" | tail -n 1)"

if [[ -z "$REGION" ]]; then
  REGION="$REGION_DEFAULT"
fi

if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" || -z "$SESSION_TOKEN" ]]; then
  echo "Could not find all AWS keys in the pasted text." >&2
  echo "Paste the AWS Details block that contains aws_access_key_id, aws_secret_access_key and aws_session_token." >&2
  exit 1
fi

aws configure set aws_access_key_id "$ACCESS_KEY" --profile "$PROFILE"
aws configure set aws_secret_access_key "$SECRET_KEY" --profile "$PROFILE"
aws configure set aws_session_token "$SESSION_TOKEN" --profile "$PROFILE"
aws configure set region "$REGION" --profile "$PROFILE"
aws configure set output json --profile "$PROFILE"

echo "Local AWS CLI profile updated: $PROFILE"
aws sts get-caller-identity --profile "$PROFILE" --region "$REGION" --output table

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh secret set AWS_ACCESS_KEY_ID --repo "$REPO" --body "$ACCESS_KEY"
  gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO" --body "$SECRET_KEY"
  gh secret set AWS_SESSION_TOKEN --repo "$REPO" --body "$SESSION_TOKEN"
  gh secret set AWS_REGION --repo "$REPO" --body "$REGION"
  echo "GitHub Actions AWS secrets updated for $REPO"
else
  echo "GitHub CLI is not authenticated, so repo secrets were not updated."
  echo "Run: gh auth login -h github.com"
fi

echo "Done. Do this again each time the Learner Lab restarts."
