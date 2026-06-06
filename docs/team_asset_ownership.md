# Team Asset Ownership

Last updated: 2026-06-06

## Final Branch

Use:

```text
week6-team-submission-merge
```

This branch keeps deployable code and clean project docs only. Manual MongoDB/OpenVPN steps, client profiles, one-off commands and private evidence notes are kept outside GitHub.

## Ownership

| Person | Area | Work |
|---|---|---|
| Pantelis | Webserver and PHP dashboard | Webserver hardening, dashboard behaviour, health check, public summary route, web evidence |
| Pantelis | 402 Cognito/API/frontend path | Cognito login, API Gateway JWT authorizer, Lambda VPC bridge, private PHP endpoint, MongoDB-backed read/write evidence |
| Pantelis | Network integration | PublicVPC, PrivateVPC, Transit Gateway routing, final CloudFormation integration |
| Mike | MongoDB database controls | Database access control, authentication, replica administration, backup/restore evidence |
| Mike | OpenVPN/admin path | OpenVPN admin access path and private MongoDB connectivity testing |
| Shared | VDI asset | Private Windows VDI, no public RDP, IMDSv2, encrypted root volume, internal admin path evidence |

## Final Architecture Story

```text
Cognito login -> API Gateway JWT authorizer -> Lambda VPC ENIs in PublicVPC transit subnets -> private PHP endpoint on web EC2 -> MongoDB through Transit Gateway
```

## Current Live Stack Values

| Output | Value |
|---|---|
| Web public IP | `52.73.62.146` |
| OpenVPN public IP | `34.204.247.209` |
| MongoDB private IPs | `192.168.10.10`, `192.168.11.10`, `192.168.12.10` |
| PublicVPC | `10.0.0.0/16` |
| PrivateVPC | `192.168.0.0/16` |
| Transit Gateway | `tgw-09c8644e65d2ebb00` |
| 402 API | `https://poa5mm0rs1.execute-api.us-east-1.amazonaws.com/items` |

## Evidence Rules

Claim implemented controls only when backed by CloudFormation, AWS output, screenshot evidence or live test output.

Do not claim these as final unless fresh evidence exists:

1. full three-node MongoDB replica is configured live
2. MongoDB backup/restore succeeded
3. OpenVPN client connection works for the current stack
4. VDI RDP login works
5. HTTPS/TLS is complete
6. WAF is deployed

Old MongoDB screenshots using `10.0.10.10`, `10.0.11.10` or `10.0.12.10` are historical only. The current final stack uses `192.168.10.10`, `192.168.11.10` and `192.168.12.10`.
