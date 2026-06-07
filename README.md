# 503AZ_2425_GroupDeploy

This repository contains the CivicNexus cloud security coursework environment for 503AZ.

The project keeps the weak baseline and the improved secure version separate so the risk assessment and treatment work can be compared clearly.

## Main Files

| File | Purpose |
|---|---|
| `cfstack.yml` | Original weak baseline stack kept only for comparison. Do not deploy it as final evidence. |
| `cfstack-secure.yml` | Improved two-VPC stack with PublicVPC, PrivateVPC and Transit Gateway routing. |
| `cfstack-402-serverless.yml` | Optional 402-style add-on using Cognito, API Gateway, Lambda and the existing MongoDB-backed web tier. |
| `frontend/` | Optional React/Amplify frontend for the 402-style add-on. |
| `DBLoad.js` | Baseline MongoDB seed data script. |
| `scripts/update_lab_credentials.sh` | Updates local AWS CLI and GitHub Actions secrets from the Learner Lab credentials block. |
| `scripts/collect_webserver_evidence.sh` | Collects webserver, dashboard, header, health check, and security group evidence. |
| `scripts/collect_database_evidence.sh` | Collects MongoDB instance, security group, and access evidence. |
| `scripts/collect_vdi_evidence.sh` | Collects VDI instance, security group, metadata, and volume encryption evidence. |
| `scripts/collect_network_audit_evidence.sh` | Collects CloudFormation, CloudTrail, and VPC Flow Log evidence. |
| `scripts/list_lab_resources.sh` | Lists active AWS lab resources so unused stacks can be deleted before they waste credit. |
| `docs/team_asset_ownership.md` | Records who worked on which asset and what changed. |

## Current Secure Direction

The secure stack currently focuses on:

- web dashboard data minimisation
- PHP error handling
- Apache security headers
- browser policy headers, including CSP and Permissions-Policy
- IMDSv2 on the web EC2 instance
- web health check with MongoDB reachability
- public summary API that exposes only safe city data
- application database credentials stored outside the public web root
- two-VPC design with PublicVPC `10.0.0.0/16` and PrivateVPC `192.168.0.0/16`
- Transit Gateway routes between the public/admin side and the private resource side
- MongoDB placed in PrivateVPC private subnets with no public IP
- MongoDB `27017` restricted to trusted public/admin and private replica paths
- MongoDB packages installed by CloudFormation, with any final admin/VPN checks documented outside GitHub
- explicit outbound security group rules for web, VPN, and MongoDB setup traffic
- NAT Gateway in PublicVPC for private outbound setup access through Transit Gateway
- database user, seed data and backup/restore evidence recorded outside GitHub when manually collected
- MongoDB backup bucket encryption, versioning, public access blocking, and HTTPS-only bucket policy
- MongoDB backup bucket controls, with optional backup upload evidence support where the lab allows the needed IAM/S3 setup
- optional VPC Flow Logs support for accepted and rejected traffic evidence across both VPCs
- optional 402-style add-on with Amplify/Cognito, API Gateway JWT authorisation, Lambda and MongoDB-backed data
- private VDI instance with no public RDP, IMDSv2, encrypted root volume, and optional RDP only through OpenVPN

The final live evidence snapshot was collected before teardown from stack `pantelis-civicnexus-stack` and the 402 add-on stack `pantelis-402-serverless-addon`. The AWS lab resources were then deleted to save credit, so saved evidence should be used unless the stack is redeployed.

## Deploy

Deployment can be done through GitHub Actions or manually in CloudFormation.

Use the manual workflow and select:

```text
cfstack-secure.yml
```

The optional 402 add-on can be selected after the secure stack is deployed. Deploy order matters because the 402 template imports VPC, subnet and web private IP outputs from the secure stack:

```text
cfstack-402-serverless.yml
```

For the 402 add-on, set `allowed_origin` to the frontend origin you will use. Use `http://localhost:5173` for the local Vite frontend, or the S3/static website URL if the frontend is hosted.

Manual MongoDB/OpenVPN connection notes, one-off commands, client profile details and local scripts are intentionally kept outside GitHub so secrets and private profile material are not committed.

## Evidence

After deployment, collect evidence with:

```bash
scripts/collect_webserver_evidence.sh <stack-name> <output-folder>
scripts/collect_database_evidence.sh <stack-name> <output-folder>
scripts/collect_vdi_evidence.sh <stack-name> <output-folder>
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
7. public summary API returns only safe city data and marks sensitive records as restricted

For VDI evidence, the useful checks are:

1. VDI instance exists in a private subnet
2. VDI has no public IP address
3. VDI security group does not allow public RDP
4. IMDSv2 is required
5. root EBS volume encryption is enabled
6. RDP is allowed only from OpenVPN/admin CIDR when VPN is enabled

## Lab Credit Check

Before finishing a work session, check what is still running:

```bash
scripts/list_lab_resources.sh
```

Keep the current evidence stack only while testing or collecting evidence. Delete old duplicate coursework stacks when they are no longer needed.

The secure stack creates a Transit Gateway and NAT Gateway so PrivateVPC resources can reach outbound setup services without public IPs. These resources can use AWS lab credit quickly, so delete the secure stack after evidence is saved.

The MongoDB backup bucket is retained so backup evidence is not removed when the stack is deleted. Empty and delete that bucket manually after the evidence is no longer needed.

When tearing the lab down, delete the 402 add-on stack before deleting the secure stack. The add-on imports outputs from the secure stack, so CloudFormation can block secure-stack deletion while the add-on still exists.
