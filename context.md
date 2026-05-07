# context.md

## Purpose

This repository supports the 503AZ CivicNexus group deployment project.

## Current State

- Fork cloned locally at `~/Documents/GitHub/503AZ_2425_GroupDeploy`.
- CloudFormation stack and GitHub Actions deployment workflow exist.
- Block 3 ISO 27001 DOCX deliverables copied into `docs/block-3/iso27001/`.
- Large deployment videos remain outside the repository.

## Key Decisions

- Keep raw course videos out of Git because one file is over GitHub's normal 100 MB file limit.
- Keep Block 3 governance documents in a dedicated folder for easier submission review.
- Use GitHub Actions workflow dispatch for deployment once lab credentials are available.

## Next

- Add AWS lab secrets when access is granted.
- Run the deployment workflow.
- Capture screenshots and outputs as evidence.
- Update README with actual stack outputs after deployment.
