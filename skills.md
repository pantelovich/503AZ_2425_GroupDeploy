# skills.md

## GitHub Actions Deployment

Use workflow dispatch for controlled lab deployment.

Required secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `GROUP_NAME`
- `GROUP_SIZE`
- `KEY_NAME`

## CloudFormation

Keep `cfstack.yml` parameterized by group values. Do not hard-code lab credentials or temporary access details.

## Evidence

Store screenshots in `evidence/` with descriptive names. After deployment, capture:

- GitHub Actions successful run
- CloudFormation stack outputs
- EC2 instances
- MongoDB load confirmation
- Any required application/service screenshots
