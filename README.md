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
| `scripts/list_lab_resources.sh` | Lists active AWS lab resources so unused stacks can be deleted before they waste credit. |
| `docs/team_asset_ownership.md` | Records who worked on which asset and what changed. |

## Current Secure Direction

The secure stack currently focuses on:

- web dashboard data minimisation
- PHP error handling
- Apache security headers
- IMDSv2 on the web EC2 instance
- web health check with MongoDB reachability
- MongoDB `27017` restricted to the webserver security group
- local database seeding during secure stack bootstrap

## Deploy

Deployment is done through GitHub Actions.

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
```

Do not commit evidence dumps, screenshots, credentials, or private keys to this repository.

## Lab Credit Check

Before finishing a work session, check what is still running:

```bash
scripts/list_lab_resources.sh
```

Keep the current evidence stack only while testing or collecting evidence. Delete old duplicate coursework stacks when they are no longer needed.
