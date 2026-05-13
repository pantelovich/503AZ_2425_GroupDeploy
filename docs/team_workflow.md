# Team Workflow

## Purpose

This file explains how we are splitting the 503AZ project work and how we will keep the repository organised.

The aim is to work in small steps, check evidence properly, and avoid large unexplained changes.

## Work Split

Pantelis is responsible for the webservers and application tier.

Mike is responsible for the database and MongoDB work.

Both of us are responsible for the shared parts:

1. VPC and network design.
2. Security groups and access paths.
3. Deployment process.
4. Risk matrix consistency.
5. Statement of Applicability.
6. Treatment plans.
7. Final framework.
8. Presentation.

## Branches

Use `main` only for reviewed work.

Pantelis works on:

```bash
pantelis/webserver-work
```

Mike works on:

```bash
mike/database-work
```

Do not push unfinished work directly to `main`.

## How To Work

Start by updating your branch:

```bash
git switch main
git pull --ff-only origin main
git switch mike/database-work
git merge main
```

For Pantelis, replace `mike/database-work` with `pantelis/webserver-work`.

Make one small change at a time. A commit should normally cover one task, for example:

1. Add database risk notes.
2. Update MongoDB security group evidence.
3. Add webserver exposure findings.
4. Update one section of the risk matrix.

Avoid commits that change many unrelated files at once.

## Commit Style

Use simple commit messages.

Good examples:

```bash
git commit -m "Add MongoDB exposure notes"
git commit -m "Update webserver risk entries"
git commit -m "Add database backup evidence"
```

Avoid vague messages such as:

```bash
git commit -m "big update"
git commit -m "fix everything"
git commit -m "final"
```

## Evidence Rules

Do not write that something was checked unless we have evidence for it.

Useful evidence includes:

1. AWS console screenshots.
2. Security group settings.
3. CloudFormation lines.
4. Command output.
5. Application behaviour.
6. Database connection tests.

If evidence is missing, write what evidence still needs to be collected.

## Mike Database Checklist

Mike should focus on:

1. Whether MongoDB is reachable from the internet.
2. Whether MongoDB requires authentication.
3. Which security group rules allow database access.
4. Whether only the webserver should connect to MongoDB.
5. Whether sensitive data is stored in the database.
6. Whether backups and recovery are covered.
7. Which ISO 27001 or ISO 27017 controls match the database risks.
8. What the residual risk is after controls are applied.

## Pantelis Webserver Checklist

Pantelis should focus on:

1. Which webserver ports are open.
2. Whether the application is publicly reachable.
3. Whether the webserver exposes sensitive information.
4. Whether access should be restricted or protected.
5. Whether WAF, rate limiting, or logging is needed.
6. Whether the webserver can reach the database safely.
7. Which ISO 27001 or ISO 27017 controls match the webserver risks.
8. What the residual risk is after controls are applied.

## Review Before Merge

Before anything is merged to `main`, check:

1. The change matches the task.
2. The wording is clear and simple.
3. There is no invented evidence.
4. The risk scores make sense.
5. The owner is correct.
6. The references are reliable.
7. The work can be explained in the presentation.

## File Hygiene

Keep coursework files tidy.

Do not add temporary notes, copied prompts, screenshots with unclear names, or random exports to the repo.

Use clear file names and keep drafts separate from final files.

