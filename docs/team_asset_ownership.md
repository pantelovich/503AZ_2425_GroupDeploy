# Team Asset Ownership

Short note on who covered what.

Last updated: 2026-05-26

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

Current secure target:

1. Keep the web/app layer public.
2. Keep MongoDB in a private subnet with no public IP.
3. Use NAT only if the private instance needs outbound setup access.
4. Use VPN/SSM for admin access where possible, not public SSH.
5. Keep MongoDB open only to the web/app security group and replica members.
6. Run MongoDB as a private replica set only if the final deploy proves it works.
7. Keep lab-heavy evidence services disabled by default because AWS Academy blocks some IAM role creation.
8. Treat the 402/S3 frontend as an extra after the secure stack works.
9. Keep the 402 serverless add-on separate from the main secure stack so it does not destabilise the core coursework environment.

Current branch position:

1. `week6-replica-cleanup` is the clean working base.
2. Pantelis' web/app side has working deployment evidence from 2026-05-26.
3. Mike's latest database branch still needs review before merge because it adds public endpoint changes.

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
| 2026-05-26 | Pantelis | Started a separate 402-style serverless add-on using Amplify/Cognito, Lambda, API Gateway and DynamoDB. |
