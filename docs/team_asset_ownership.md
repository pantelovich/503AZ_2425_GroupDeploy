# Team Asset Ownership

This file records who is responsible for each part of the CivicNexus security work.

Last updated: 2026-05-17

## Ownership

| Team member | Main asset | Responsibility |
|---|---|---|
| Pantelis | Webserver and PHP dashboard | Webserver exposure, PHP dashboard behaviour, web-to-database connection, webserver evidence |
| Mike | MongoDB database server | MongoDB exposure, database access control, database hardening, backup and recovery evidence |
| Shared | VPC and network design | Subnets, routing, security group relationships, integration checks, residual risk consistency |

## Working Rule

`cfstack.yml` is the weak baseline and should not be overwritten.

`cfstack-secure.yml` is the improved version used for agreed controls.

Do not claim a control is complete unless the evidence exists.

## Control Areas

Each person should cover:

1. Network controls.
2. Instance controls.
3. Server or OS controls.
4. Data controls.

## Current Agreed Work

Pantelis is currently covering:

1. Web application connection to MongoDB.
2. PHP error display and logging.
3. Webserver package/tooling exposure.
4. Dashboard health check and web evidence.

Mike is currently covering:

1. MongoDB security group exposure.
2. MongoDB public/private access.
3. MongoDB authentication and service hardening.
4. MongoDB backup, restore, and data evidence.

Shared decisions still need agreement before implementation:

1. Final MongoDB security group source.
2. Whether MongoDB moves to a private subnet.
3. Whether dashboard personnel data is hidden, authenticated, or documented as demo exposure.
4. Final residual risk scores.

## Evidence Rule

Only claim a control is implemented when there is matching evidence such as:

1. CloudFormation changes.
2. AWS CLI output.
3. AWS screenshots.
4. Application screenshots.
5. Test output.

## Update Log

| Date | Person | Update |
|---|---|---|
| 2026-05-17 | Pantelis | Added team asset ownership and clean working boundaries. |
