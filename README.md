# 503AZ 2425 GroupDeploy

Coursework repository for the 503AZ group deployment project.

The project deploys a CivicNexus smart-city lab environment to AWS with CloudFormation, seeds a MongoDB dataset, and stores Block 3 ISO 27001 governance documentation.

## Repository Structure

```text
.
├── .github/workflows/main.yml      # Manual GitHub Actions deployment workflow
├── cfstack.yml                     # AWS CloudFormation infrastructure template
├── DBLoad.js                       # MongoDB seed data
├── docs/
│   ├── block-3/iso27001/           # Block 3 ISO 27001 document set
│   └── course-notes/               # Lightweight notes/reference files
└── evidence/                       # Screenshots and supporting evidence
```

## Deployment

The stack is deployed manually through GitHub Actions.

Required repository secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `GROUP_NAME`
- `GROUP_SIZE`
- `KEY_NAME`

Workflow:

1. Open **Actions** in GitHub.
2. Select **Deploy CivicNexus CloudFormation Stack**.
3. Run the workflow manually.
4. The workflow deploys `cfstack.yml`, finds the MongoDB EC2 public IP, and loads `DBLoad.js`.

## Block 3 Documentation

The ISO 27001 document set is stored in `docs/block-3/iso27001/`:

- Access Control Policy
- Business Continuity
- Configuration Document
- Employee Training Policy
- Framework Scope
- General Security Objectives
- Monitoring and Maintenance
- Risk Analysis
- Statement of Applicability
- Treatment Plans

## Notes

Large lecture videos and raw course materials are kept out of Git. Store those locally or use Git LFS only if the module requires them in the repository.
