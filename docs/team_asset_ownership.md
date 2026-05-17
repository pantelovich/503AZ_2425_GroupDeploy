# Team Asset Ownership

This file records who is responsible for each part of the CivicNexus security work.
It is used so the group can show who worked on which asset without mixing all
work into one large change.

## Ownership

| Team member | Main asset | Responsibility |
|---|---|---|
| Pantelis | Webserver and PHP dashboard | Webserver exposure, PHP dashboard behaviour, web-to-database connection, web evidence |
| Mike | MongoDB database server | MongoDB exposure, database access control, database hardening, backup/recovery evidence |
| Shared | VPC and network design | Subnets, routing, security group relationships, residual risk consistency |

## Pantelis Scope

Pantelis is responsible for the webserver and PHP dashboard side of the system.
This includes how the dashboard is reached from the internet, what data is shown
to users, and how the webserver connects to MongoDB.

Main areas:

1. Webserver security group and public HTTP exposure.
2. PHP dashboard behaviour and browser error handling.
3. Web-to-database connection path.
4. Webserver screenshots, AWS evidence, and test output.

## Mike Scope

Mike is responsible for the MongoDB database server and database security work.
This includes whether MongoDB is publicly reachable, how access is controlled,
and whether there is evidence for backup and recovery.

Main areas:

1. MongoDB security group and port `27017` exposure.
2. MongoDB public/private network placement.
3. MongoDB authentication and service hardening.
4. Database backup, recovery, logging, and evidence.

## Shared Scope

Some controls affect both sides, so they must be agreed before changes are made.
The main shared area is the relationship between the webserver and MongoDB.

Shared areas:

1. VPC, subnet, and route table design.
2. Security group source and destination relationship.
3. Residual risk scoring after controls are proven.
4. Final framework wording and presentation explanation.

## Working Rule

`cfstack.yml` is the weak baseline and should not be overwritten.

`cfstack-secure.yml` is the improved version used for agreed controls.

Do not edit `cfstack-secure.yml` for shared network changes until the design is
agreed by both sides.

## Control Areas

Each person should cover:

1. Network controls.
2. Instance controls.
3. Server or OS controls.
4. Data controls.

## Evidence Rule

Only claim a control is implemented when there is matching evidence. Good
evidence can include:

1. CloudFormation changes.
2. AWS CLI output.
3. AWS screenshots.
4. Application screenshots.
5. Test output.

If evidence is missing, write that the screenshot or test is still needed.
Do not invent screenshots, AWS results, or security controls.

## Current Status

The current security story is simple:

1. The weak baseline has a public webserver and a public MongoDB server.
2. The webserver may need public access, but MongoDB should not be public.
3. `cfstack-secure.yml` already improves part of the webserver side.
4. The main database treatment still needs to be proven with evidence before the
   residual risk can be reduced.

## Repo Rule

GitHub should stay clean. Use GitHub for code, templates, scripts, `README.md`,
and this ownership file. Working notes, evidence dumps, draft reports, and
private coordination files should stay in the shared OneDrive folder.

