# Team Asset Ownership

Short note on who covered what.

Last updated: 2026-06-03

## Ownership

| Person | Area | Work |
|---|---|---|
| Pantelis | Webserver and PHP dashboard | Webserver hardening, dashboard behaviour, health check, web evidence |
| Pantelis | 402 Cognito/API/frontend path | Cognito login, API Gateway JWT authorizer, Lambda VPC bridge, private PHP endpoint, MongoDB-backed read/write evidence |
| Mike | MongoDB database | Database exposure, access control, replica set, backup and database evidence |
| Mike | Manual database and VPN controls | MongoDB users/authentication, OpenVPN admin path, backup/restore and manual runbook evidence |
| Shared | VDI asset | Private Windows VDI provisioning, no public RDP, IMDSv2, encrypted root volume, and VPN-only admin path evidence |
| Both | Network and final testing | PublicVPC, PrivateVPC, Transit Gateway routing, security group links, integration checks, final evidence |

## Notes

`cfstack.yml` is the original weak version.

`cfstack-secure.yml` is the improved version.

We only claim controls when we have evidence.

402 MongoDB integration status:

1. Work from `week6-final-integration`.
2. Dan wants one database only, so final 402 work now uses MongoDB, not DynamoDB.
3. Pantelis built the 402-style add-on path:
   - `cfstack-402-serverless.yml`
   - `frontend/`
   - Cognito user pool
   - API Gateway HTTP API
   - JWT authorizer
   - Lambda
4. The 402 data path now uses the existing private MongoDB-backed web tier.
5. Cognito, API Gateway, JWT authorizer and the frontend login flow are kept.
6. DynamoDB is removed from the final 402 template.
7. Mike should review the MongoDB/security side only. Do not merge `mike/database-work` directly.

Dan's 402 requirement from 2026-05-28:

1. Replace the DynamoDB data connection with MongoDB.
2. Keep Cognito login.
3. Put Cognito/JWT authorisation on the API route, not only on the frontend.
4. Show a simple landing page if possible.
5. Evidence must show:
   - no token is rejected
   - valid Cognito token is accepted
   - the accepted API request reads or writes MongoDB

Files to read before editing:

1. `docs/team_asset_ownership.md`
2. `cfstack-secure.yml`
3. `cfstack-402-serverless.yml`
4. `frontend/src/App.tsx`
5. `frontend/src/main.tsx`
6. `frontend/README.md`
7. `.github/workflows/main.yml`
8. `README.md`
9. `DBLoad.js`

MongoDB conversion rules:

1. Read `cfstack-secure.yml` first.
2. Reuse the existing MongoDB replica set:
   - `192.168.10.10:27017`
   - `192.168.11.10:27017`
   - `192.168.12.10:27017`
   - replica set: `rs0`
   - database: `civicnexus`
3. Do not make MongoDB public.
4. Do not create a second database service.
5. Do not use DynamoDB in the final version.
6. API routes should prove Dan's video pattern:
   - missing token is rejected
   - valid Cognito JWT is accepted
   - API reads or writes MongoDB
7. Keep public safe data separate from restricted data.
8. Do not expose personnel details or raw operational logs through a public route.
9. Current implementation uses API Gateway with Cognito JWT, then Lambda inside the PrivateVPC, then a private PHP endpoint on the web EC2 in PublicVPC through Transit Gateway, then MongoDB.
10. This avoids fake Lambda MongoDB imports because PHP already has the Composer MongoDB driver.
11. Do not leave fake imports like `require("mongodb")` in inline Lambda code unless the dependency is actually packaged.
12. Push after each small working milestone so Pantelis can review.

Important implementation note:

Direct Lambda to MongoDB is good, but only if the Lambda deployment really includes the MongoDB driver and the Lambda runs inside the VPC. Inline CloudFormation Lambda code cannot just `require("mongodb")` because the dependency is not included by default.

If packaging the Lambda driver becomes too fragile, use this safer lab design:

1. API Gateway has the Cognito JWT authorizer.
2. Authenticated API Gateway route calls Lambda.
3. Lambda is inside the PrivateVPC.
4. Lambda calls a private PHP endpoint on the web EC2 through Transit Gateway.
5. PHP talks to MongoDB using the existing Composer MongoDB driver.
6. The public API result still comes from MongoDB, and DynamoDB is removed.

Integration update:

1. Clean branch started: `week6-final-integration`.
2. Added optional OpenVPN infrastructure to `cfstack-secure.yml`.
3. OpenVPN is off by default with `EnableOpenVPN=false`, so normal deploys stay cheaper and simpler.
4. If VPN evidence is needed, deploy with `EnableOpenVPN=true` and restrict `AdminAccessCidr` to the current public IP with `/32`.
5. MongoDB and OpenVPN package installation can use `scripts/install_database_vpn_packages.sh` if package installation needs to be repeated manually.
6. MongoDB replica set setup, authentication, seed data, backup/restore and OpenVPN certificate/profile setup are manual runbook tasks, not hidden CloudFormation automation.
7. Do not replace the working web/MongoDB stack with Mike's whole branch. We are only taking the useful parts.

Current secure target:

1. Keep the web/app layer in PublicVPC.
2. Keep MongoDB and VDI in PrivateVPC private subnets with no public IP.
3. Use Transit Gateway for PublicVPC to PrivateVPC routing.
4. Use NAT in PublicVPC only if private instances need outbound setup access.
5. Use VPN/SSM for admin access where possible, not public SSH.
6. Keep MongoDB open only to trusted PublicVPC/admin traffic and replica members.
7. Run MongoDB as a private replica set after manual configuration proves it works.
8. Keep lab-heavy evidence services disabled by default because AWS Academy blocks some IAM role creation.
9. Treat the 402/S3 frontend as an extra after the secure stack works.
10. Keep the 402 serverless add-on separate from the main secure stack so it does not destabilise the core coursework environment.
11. Keep OpenVPN optional, not always on.

Current branch position:

1. `week6-replica-cleanup` is the clean working base.
2. Pantelis' web/app side has working deployment evidence from 2026-05-26.
3. `week6-final-integration` now contains the 402 add-on and selected optional VPN/MongoDB manual setup work.

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
5. Keep the submitted branch clear about code-backed controls versus manual controls.
6. Capture VDI evidence because the VDI asset is part of the CivicNexus scenario.

## Final Team Submission Split

The final team branch should keep Pantelis' web/API path in code and Mike's heavier database/VPN work as manual runbook evidence unless it has been fully tested.

Pantelis code-backed controls:

1. `cfstack-secure.yml` PublicVPC, PrivateVPC, Transit Gateway, web EC2, web security group, Apache/PHP dashboard, `/health.php`, browser headers, public summary route and private internal 402 bridge.
2. `cfstack-402-serverless.yml` Cognito user pool, API Gateway HTTP API, JWT authorizer, Lambda VPC bridge and CORS setting.
3. `frontend/` operator login and API client.

Mike manual/database controls:

1. MongoDB replica administration.
2. MongoDB users and database authentication.
3. MongoDB backup and restore.
4. OpenVPN/admin access path.
5. Database security group and database hardening evidence.

Evidence rule for final report:

1. Claim implemented controls only when there is code or live evidence.
2. Claim manual controls only when Mike's runbook and screenshots/output prove them.
3. Keep HTTPS/TLS and WAF as future improvements unless they are implemented and evidenced.
4. Keep the final database story MongoDB-only.
5. Claim VDI controls only after EC2/security group/metadata/volume evidence is captured.

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
| 2026-05-26 | Pantelis | Pushed `pantelis/402-serverless-addon`, deployed it, tested the Lambda/DynamoDB public summary endpoint and saved frontend evidence. |
| 2026-05-27 | Pantelis | Started `week6-final-integration`, added optional OpenVPN resources disabled by default, and brought in Mike's manual VPN/MongoDB setup scripts. |
| 2026-05-27 | Pantelis | Tightened admin CIDR defaults, outbound rules, web credential storage, and backup bucket controls after reviewing the CloudFormation security notes. |
| 2026-05-28 | Pantelis | Reworked the 402 add-on so Cognito-protected API Gateway routes call Lambda, then a private PHP endpoint, then MongoDB. DynamoDB was removed from the final 402 path. |
| 2026-06-02 | Pantelis | Captured final Pantelis web/API evidence: web SG inbound, security headers, health check, public internal-endpoint block, API 401 without token, and valid Cognito GET/POST to MongoDB. |
| 2026-06-03 | Pantelis | Added final team-submission split: Pantelis web/API code-backed controls and Mike manual MongoDB/OpenVPN controls. |
| 2026-06-03 | Shared | Brought VDI into the final branch as an enabled private asset and added VDI evidence collection guidance. |
| 2026-06-03 | Shared | Moved the secure template to a tutor-style PublicVPC plus PrivateVPC design connected with Transit Gateway. |
