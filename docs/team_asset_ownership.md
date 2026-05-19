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
5. Public dashboard data minimisation.

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
| 2026-05-17 | Pantelis | Added web-side hardening in `cfstack-secure.yml`: IMDSv2 requirement, Apache security headers, and reduced public dashboard display of personnel/log details. |
| 2026-05-17 | Pantelis | Updated `scripts/collect_webserver_evidence.sh` to collect health check output, IMDSv2 metadata options, security header checks, and dashboard redaction checks. |
| 2026-05-17 | Pantelis | Reduced webserver post-install exposure by disabling directory indexes and removing Composer/build tools after dashboard dependencies are installed. |
| 2026-05-17 | Pantelis | Added GitHub Actions validation for CloudFormation YAML and shell scripts before manual deployment runs. |
| 2026-05-19 | Pantelis | Updated manual GitHub Actions deployment to use `cfstack-secure.yml` by default while keeping `cfstack.yml` available as the baseline option. |
| 2026-05-19 | Pantelis | Improved the web health endpoint so it checks MongoDB reachability and reports degraded status if the database cannot be reached. |
| 2026-05-19 | Mike | Fixed database evidence collection names and added authenticated user output to the MongoDB connection check. |
| 2026-05-19 | Pantelis | Restricted secure-stack MongoDB access to the webserver security group and moved demo data seeding into MongoDB instance bootstrap so public database loading is no longer needed. |
| 2026-05-19 | Pantelis | Updated database evidence collection to record whether the public MongoDB endpoint is connected or blocked from outside the VPC. |
