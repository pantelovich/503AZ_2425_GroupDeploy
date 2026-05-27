# Team Asset Ownership

Short note on who covered what.

Last updated: 2026-05-27

## Ownership

| Person | Area | Work |
|---|---|---|
| Pantelis | Webserver and PHP dashboard | Webserver hardening, dashboard behaviour, health check, web evidence |
| Mike | MongoDB database | Database exposure, access control, replica set, backup and database evidence |
| Both | Network and final testing | Security group links, integration checks, final evidence |

## Notes

`cfstack.yml` is the original weak version.

`cfstack-secure.yml` is the improved version.

We only claim controls when we have evidence.

For Mike next session:

1. Use branch `week6-final-no-402` if you want the main project without the 402 add-on.
2. This branch keeps the secure EC2/MongoDB stack, web controls, optional OpenVPN resources and manual setup scripts.
3. The 402 serverless files are not included in this branch.
4. Use `week6-final-integration` only if you want the version that also contains the 402 add-on.

Integration update:

1. Clean branch started: `week6-final-integration`.
2. Added optional OpenVPN infrastructure to `cfstack-secure.yml`.
3. OpenVPN is off by default with `EnableOpenVPN=false`, so normal deploys stay cheaper and simpler.
4. If VPN evidence is needed, deploy with `EnableOpenVPN=true` and restrict `AdminAccessCidr` to the current public IP with `/32`.
5. Mike's manual setup scripts were added under `scripts/`:
   - `scripts/manual_openvpn_setup.sh`
   - `scripts/manual_mongodb_node_setup.sh`
   - `scripts/manual_mongodb_primary_setup.sh`
6. Do not replace the working web/MongoDB stack with Mike's whole branch. We are only taking the useful parts.

Current secure target:

1. Keep the web/app layer public.
2. Keep MongoDB in a private subnet with no public IP.
3. Use NAT only if the private instance needs outbound setup access.
4. Use VPN/SSM for admin access where possible, not public SSH.
5. Keep MongoDB open only to the web/app security group and replica members.
6. Run MongoDB as a private replica set only if the final deploy proves it works.
7. Keep lab-heavy evidence services disabled by default because AWS Academy blocks some IAM role creation.
8. Keep OpenVPN optional, not always on.

Current branch position:

1. `week6-replica-cleanup` is the clean working base.
2. Pantelis' web/app side has working deployment evidence from 2026-05-26.
3. `week6-final-no-402` contains the main secure project without the 402 add-on.
4. `week6-final-integration` contains the same project plus the 402 add-on.

## Current Work

Pantelis:

1. Web EC2 controls.
2. PHP dashboard security.
3. `/health.php` testing.
4. Web evidence.
5. Final web/app wording for the Week 5 configuration document.
6. Public summary API and browser policy headers.

Mike:

1. MongoDB access controls.
2. MongoDB authentication.
3. Private MongoDB replica set.
4. Backup and restore evidence.
5. Database evidence.

Shared:

1. Final deploy.
2. Final screenshots.
3. Report evidence table.
4. Decide which optional extras are kept in CloudFormation and which stay as manual evidence.

## Evidence Rule

Evidence can be:

1. AWS output.
2. Screenshots.
3. Test results.
4. CloudFormation changes.

## Update Log

| Date | Person | Update |
|---|---|---|
| 2026-05-17 | Pantelis | Added webserver hardening and health check work. |
| 2026-05-19 | Mike | Added database evidence fixes. |
| 2026-05-19 | Pantelis | Restricted MongoDB access to the webserver security group. |
| 2026-05-20 | Pantelis | Added lab resource checker to avoid leaving AWS resources running. |
| 2026-05-20 | Pantelis | Added agreed next target: private MongoDB subnet, NAT only for setup, VPN/SSM for admin, 402/S3 later. |
| 2026-05-20 | Pantelis | Updated secure template so MongoDB uses a private subnet and NAT is used for outbound setup. |
| 2026-05-21 | Pantelis | Tightened MongoDB so it listens only on localhost and its private VPC IP. |
| 2026-05-21 | Pantelis | Added MongoDB backup and restore evidence support for availability. |
| 2026-05-21 | Pantelis | Added VPC Flow Logs support for network monitoring evidence. |
| 2026-05-21 | Pantelis | Added network and audit evidence helper for Flow Logs and CloudTrail. |
| 2026-05-22 | Pantelis / Mike | Brought in the useful MongoDB replica set work on a clean branch, without OpenVPN. |
| 2026-05-22 | Pantelis | Disabled optional VDI by default and removed public RDP from the secure template. |
| 2026-05-22 | Pantelis | Deployed the clean replica branch in the AWS lab with evidence services disabled because the lab blocks IAM role creation. |
| 2026-05-26 | Pantelis | Deployed the web evidence stack, confirmed dashboard, health check, headers, IMDSv2 and private MongoDB path, then deleted the stack after saving evidence. |
| 2026-05-26 | Pantelis | Added a public summary API and stronger browser policy headers as an extra web-layer control. |
| 2026-05-27 | Pantelis | Started `week6-final-integration`, added optional OpenVPN resources disabled by default, and brought in Mike's manual VPN/MongoDB setup scripts. |
| 2026-05-27 | Pantelis | Created `week6-final-no-402` for the main secure project without the 402 add-on. |
