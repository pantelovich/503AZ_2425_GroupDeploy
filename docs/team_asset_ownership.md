# Team Asset Ownership

This file records who is responsible for each part of the CivicNexus security work.

## Ownership

| Team member | Main asset | Responsibility |
|---|---|---|
| Pantelis | Webserver and PHP dashboard | Webserver exposure, PHP dashboard behaviour, web-to-database connection, web evidence |
| Mike | MongoDB database server | MongoDB exposure, database access control, database hardening, backup/recovery evidence |
| Shared | VPC and network design | Subnets, routing, security group relationships, residual risk consistency |

## Working Rule

`cfstack.yml` is the weak baseline and should not be overwritten.

`cfstack-secure.yml` is the improved version used for agreed controls.

## Control Areas

Each person should cover:

1. Network controls.
2. Instance controls.
3. Server or OS controls.
4. Data controls.

## Evidence Rule

Only claim a control is implemented when there is matching evidence such as:

1. CloudFormation changes.
2. AWS CLI output.
3. AWS screenshots.
4. Application screenshots.
5. Test output.

