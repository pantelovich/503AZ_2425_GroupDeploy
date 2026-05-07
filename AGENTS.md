# AGENTS.md

## Project

503AZ group deployment coursework repository.

## Stack

- AWS CloudFormation
- GitHub Actions
- MongoDB shell seed script
- ISO 27001 coursework documentation

## Rules

- Keep deployment code and coursework evidence clearly separated.
- Do not commit AWS credentials, session tokens, SSH keys, or lab-only secrets.
- Do not commit large raw lecture videos. Use local storage or Git LFS if required.
- Keep documentation filenames readable and submission-friendly.
- Validate YAML before changing GitHub Actions or CloudFormation.

## Agent Routing

- Infrastructure: CloudFormation template changes in `cfstack.yml`.
- Deployment: GitHub Actions workflow changes in `.github/workflows/main.yml`.
- Data: MongoDB seed changes in `DBLoad.js`.
- Documentation: ISO 27001 and coursework evidence under `docs/` and `evidence/`.

## Ruflo

Use Ruflo only for multi-file planning, review, or parallel agent work.

```bash
ruflo
```

## Commands

```bash
git status --short
```

Manual deployment runs from GitHub Actions, not from local credentials.
