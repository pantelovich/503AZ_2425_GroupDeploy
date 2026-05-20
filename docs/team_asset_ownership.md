# Team Asset Ownership

Short note on who covered what.

Last updated: 2026-05-20

## Ownership

| Person | Area | Work |
|---|---|---|
| Pantelis | Webserver and PHP dashboard | Webserver hardening, dashboard behaviour, health check, web evidence |
| Mike | MongoDB database | Database exposure, access control, backup and database evidence |
| Both | Network and final testing | Security group links, integration checks, final evidence |

## Notes

`cfstack.yml` is the original weak version.

`cfstack-secure.yml` is the improved version.

We only claim controls when we have evidence.

## Current Work

Pantelis:

1. Web EC2 controls.
2. PHP dashboard security.
3. `/health.php` testing.
4. Web evidence.

Mike:

1. MongoDB access controls.
2. MongoDB authentication.
3. Backup and restore evidence.
4. Database evidence.

Shared:

1. Final deploy.
2. Final screenshots.
3. Report evidence table.

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
