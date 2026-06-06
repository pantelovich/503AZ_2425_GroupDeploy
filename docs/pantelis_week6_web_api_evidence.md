# Pantelis Week 6 Web/API Evidence Checklist

This checklist covers Pantelis' part of the final CivicNexus team submission.

Pantelis owns:

- PublicVPC, web route table and public web path
- public webserver and PHP dashboard
- `/health.php`
- web security group explanation
- browser/security headers
- safe public summary API
- private `/internal/402-mongo.php` bridge
- Cognito, API Gateway, Lambda and frontend path
- web/API evidence that proves MongoDB-backed data access

Mike owns:

- MongoDB replica administration
- MongoDB users and database authentication
- MongoDB backup and restore
- OpenVPN/admin path
- database security group evidence

## Current Evidence Captured

Evidence folder:

```text
/Users/pantelos/Library/CloudStorage/OneDrive-CoventryUniversity/Michalis Nicolaou's files - 503 Cloud Security/503AZ Shared Work/Evidence/Raw AWS Output/2026-06-06_final_tgw_live
```

Captured checks:

| Check | Expected result | Status |
|---|---|---|
| Network layout | PublicVPC `10.0.0.0/16`, PrivateVPC `192.168.0.0/16`, Transit Gateway routes | Captured |
| Web security group inbound | Public TCP 80 only, no public SSH | Captured |
| `curl -I /` | Browser/security headers present | Captured |
| `/health.php` | `status: ok`, `database: reachable` | Captured |
| Public `/internal/402-mongo.php` request | `403 Forbidden` | Captured |
| API Gateway `/items` with no token | `401 Unauthorized` | Captured |
| API Gateway `/items` with valid Cognito token | `200`, source is MongoDB | Captured |
| API Gateway `POST /items` with valid Cognito token | `201`, MongoDB write succeeds | Captured |
| `frontend/.env.local` | ignored by Git, not tracked | Captured |

## Final Refresh Notes

The 2026-06-06 evidence folder is the final live evidence set. Older dated evidence folders have been archived because they predate the stable web Elastic IP, final Transit Gateway outputs, or final 402 API path.

Do not claim OpenVPN client login, backup/restore, full three-node replica administration, HTTPS or WAF unless there is separate evidence for them.

## Final Report Wording

Use this architecture story:

```text
Cognito login -> API Gateway JWT authorizer -> Lambda VPC ENIs in PublicVPC transit subnets -> private PHP endpoint -> MongoDB
```

For the advanced network design, write it as:

```text
Cognito login -> API Gateway JWT authorizer -> Lambda VPC ENIs in PublicVPC transit subnets -> private PHP endpoint on PublicVPC web EC2 -> Transit Gateway -> MongoDB in PrivateVPC
```

Do not mention DynamoDB as the final database.

Mention HTTPS/TLS and WAF as future improvements if the AWS Academy lab does not support completing them in time.
