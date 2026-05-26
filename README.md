# 503AZ_2425_GroupDeploy

This repository contains the CivicNexus cloud security coursework environment for 503AZ.

The project keeps the weak baseline and the improved secure version separate so the risk assessment and treatment work can be compared clearly.

## Main Files

| File | Purpose |
|---|---|
| `cfstack.yml` | Original weak baseline stack. Keep this unchanged for comparison. |
| `cfstack-secure.yml` | Improved stack used for agreed security controls. |
| `DBLoad.js` | Baseline MongoDB seed data script. |
| `scripts/update_lab_credentials.sh` | Updates local AWS CLI and GitHub Actions secrets from the Learner Lab credentials block. |
| `scripts/collect_webserver_evidence.sh` | Collects webserver, dashboard, header, health check, and security group evidence. |
| `scripts/collect_database_evidence.sh` | Collects MongoDB instance, security group, and access evidence. |
| `scripts/collect_network_audit_evidence.sh` | Collects CloudFormation, CloudTrail, and VPC Flow Log evidence. |
| `scripts/list_lab_resources.sh` | Lists active AWS lab resources so unused stacks can be deleted before they waste credit. |
| `docs/team_asset_ownership.md` | Records who worked on which asset and what changed. |

## Current Secure Direction

The secure stack currently focuses on:

- web dashboard data minimisation
- PHP error handling
- Apache security headers
- IMDSv2 on the web EC2 instance
- web health check with MongoDB reachability
- MongoDB placed in a private subnet with no public IP
- MongoDB `27017` restricted to the webserver security group
- MongoDB bound only to localhost and its private VPC IP
- NAT Gateway for private subnet outbound setup access
- local database seeding during secure stack bootstrap
- optional MongoDB backup evidence support, where the lab allows the needed IAM/S3 setup
- optional VPC Flow Logs support for accepted and rejected traffic evidence

The latest Pantelis webserver evidence was collected on 2026-05-26 from stack `pantelis-week5-web-evidence`. The stack was deleted after evidence was saved to avoid wasting AWS Academy lab credit.

## Deploy

Deployment can be done through GitHub Actions or manually in CloudFormation.

Use the manual workflow and select:

```text
cfstack-secure.yml
```

The baseline template can still be selected when the weak environment is needed for comparison:

```text
cfstack.yml
```

## Evidence

After deployment, collect evidence with:

```bash
scripts/collect_webserver_evidence.sh <stack-name> <output-folder>
scripts/collect_database_evidence.sh <stack-name> <output-folder>
scripts/collect_network_audit_evidence.sh <stack-name> <output-folder>
```

Do not commit evidence dumps, screenshots, credentials, or private keys to this repository.

For Pantelis' web/app evidence, the useful checks are:

1. dashboard page returns HTTP 200
2. `/health.php` returns `status: ok` and `database: reachable`
3. HTTP response includes the security headers
4. EC2 metadata options require IMDSv2
5. dashboard shows restricted public data instead of raw personnel records
6. web security group only exposes the required lab web port

## Lab Credit Check

Before finishing a work session, check what is still running:

```bash
scripts/list_lab_resources.sh
```

Keep the current evidence stack only while testing or collecting evidence. Delete old duplicate coursework stacks when they are no longer needed.

The secure stack creates a NAT Gateway so the private MongoDB instance can download packages during setup. NAT Gateway can use AWS lab credit quickly, so delete the secure stack after evidence is saved.

If the optional MongoDB backup bucket is created, it is retained so backup evidence is not removed when the stack is deleted. Empty and delete that bucket manually after the evidence is no longer needed.
