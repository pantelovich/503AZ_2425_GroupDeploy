# Week 4 ATV Risk Analysis Draft

## Quick Presentation Version

Our deployment has three main risk areas:

1. The webserver is public.
2. The database is exposed.
3. The network design makes the exposure worse.

The biggest issue is not one single setting. It is the chain:

```text
public internet -> webserver -> public MongoDB -> personnel and operational data
```

This is why the highest risks are linked to public access, MongoDB exposure, and displayed personnel data.

## One Minute Summary

CivicNexus is deployed as a smart city dashboard on AWS. The current template is deliberately insecure for coursework. The webserver is open to the internet, MongoDB is also reachable from the internet, and the application displays operational and personnel data. Because of this, an attacker may not need to compromise many layers to reach sensitive information.

Our Week 4 work is the first risk picture. We are not claiming the system is fixed yet. We are identifying the assets, threats, vulnerabilities, scores, and evidence needed before moving into treatment plans.

## Scope

This draft covers the first risk analysis for the CivicNexus AWS deployment. We use the CloudFormation YAML to deploy the baseline, then use the template, AWS screenshots, and the database load script as evidence for the risk assessment.

The analysis uses the ATV method:

1. Asset.
2. Threat.
3. Vulnerability.

The aim is to identify the main risks before the controls are applied. The treatment work comes after this, using the risk scores and evidence from this document.

## Context

The system is a cloud-hosted dashboard with a public webserver, a MongoDB database, and sample personnel and operational data. This means the assessment is not only about whether the AWS resources deploy successfully. It is about whether the design exposes data or services that should be controlled.

The main "crown jewels" for this assessment are:

1. Personnel data in MongoDB.
2. Operational dashboard data.
3. MongoDB itself.
4. The public web dashboard.
5. Security groups, subnets, and route tables that control access.

Because the system includes personal data, the risk appetite is low for public database access, personal data exposure, weak authentication, and missing recovery evidence. Medium technical risks can be accepted only if there is a clear reason and the evidence is recorded.

The legal context is also relevant. UK GDPR and the Data Protection Act 2018 apply where personal data is processed. The Data (Use and Access) Act 2025 updates parts of the UK data protection framework, but it does not remove the need to protect personal data. For this Week 4 task, this supports treating personnel data exposure as high consequence.

## Simple System View

```text
Internet users
     |
     v
Public subnet
     |
     v
Webserver on port 80
     |
     v
MongoDB on port 27017
     |
     v
Operational data and personnel data
```

This view helps explain the risk in class. The webserver and database should not both be easy to reach from outside.

## Team Split

Pantelis is covering the public webserver and application tier.

Mike is covering the MongoDB database.

The network, deployment process, risk scoring checks, and final write up are shared.

## Scoring Method

Consequence and likelihood are scored from 1 to 5.

1 means low.

3 means medium.

5 means high.

Overall risk score is:

```text
consequence score x likelihood score
```

Action guide:

1 to 6 means low. Monitor or accept if justified.

7 to 14 means medium. Treat or justify acceptance.

15 to 25 means high. Treat.

## Risk Heat Map

| Score Range | Meaning | What We Do |
|---|---|---|
| 1 to 6 | Low | Monitor or accept if there is a reason |
| 7 to 14 | Medium | Treat or explain why it is accepted |
| 15 to 25 | High | Treat as a priority |

Current high risk areas:

1. Public MongoDB access.
2. Public database subnet and public IP.
3. Public web application showing sensitive data.
4. Public network route and weak separation.
5. PHP errors visible to users.

## Main Evidence Used So Far

The current evidence is from the repository files and one live AWS deployment check:

1. `cfstack.yml` lines 49 to 68 show public subnets with public IP assignment.
2. `cfstack.yml` lines 109 to 115 show the public route to the internet gateway.
3. `cfstack.yml` lines 154 to 164 show MongoDB port 27017 open to `0.0.0.0/0`.
4. `cfstack.yml` lines 170 to 195 show MongoDB running on EC2 and listening on `0.0.0.0`.
5. `cfstack.yml` lines 205 to 215 show the webserver allowing public HTTP traffic on port 80.
6. `cfstack.yml` lines 267 to 278 show PHP error display enabled.
7. `cfstack.yml` lines 282 to 283 show the web application using the MongoDB public IP.
8. `cfstack.yml` lines 326 to 337 show personnel data displayed by the web application.
9. `cfstack.yml` lines 391 to 401 show public RDP if the optional VDI is used.
10. `DBLoad.js` lines 38 to 54 show employee names, contact details, and clearance level data.
11. Live stack output showed the webserver public IP `54.198.175.207` and MongoDB public IP `18.207.229.107`.
12. Live AWS check showed the webserver instance running and reachable.
13. Live web check returned `HTTP/1.1 200 OK` from the public dashboard.
14. A dashboard screenshot was saved as `web_dashboard_live_2026-05-15.png`.

AWS console screenshots are still useful for the final report because they are easier to present than command output.

## How This Matches Week 4

The Week 4 task is a starting ATV risk assessment. The workbook keeps the full working matrix, but the presentation should focus on the main risks instead of reading every row.

The matrix matches the task because it records:

1. Assets, including the webserver, MongoDB, data, VPC, deployment files, and optional VDI.
2. Threats, such as unauthorised access, data disclosure, information leakage, service failure, and weak monitoring.
3. Vulnerabilities, such as public MongoDB access, public web access, weak tier separation, missing backup evidence, and error display.
4. Consequence, likelihood, overall score, owner, action, and evidence.

## Full ATV Matrix

The full working matrix is in:

```text
docs/week4_atv_risk_matrix.xlsx
```

It has 49 evidence-backed risk entries across:

1. Public webserver and application.
2. MongoDB database.
3. VPC and network.
4. Deployment and configuration.
5. Monitoring and logging.
6. Optional VDI.

The table below is only the short version for explaining the main risks in the report or presentation.

The workbook starts with the same style as the tutor/example spreadsheet, then adds owner, evidence and control columns:

```text
Asset ID | Asset | Consequence Score | Threat ID | Threat | Vulnerability ID | Vulnerability | Likelihood Score | Overall Score | Action | Risk Source | Event / Incident | Risk Owner | ISO 27001 / ISO 27017 Control | Status | Evidence / Notes | Likelihood Justification
```

This is the before-controls assessment. The after-controls version should update control status and residual risk.

## Top Risk Summary

This table is the short presentation version. The full 49-row matrix stays as supporting evidence.

| Rank | Asset | Threat | Main Vulnerability | Score | Owner | Evidence Status |
|---:|---|---|---|---:|---|---|
| 1 | MongoDB | Unauthorised database access | Port `27017` open to `0.0.0.0/0` and MongoDB binds to all interfaces | 25 | Mike | Template evidence found, AWS screenshot needed |
| 2 | MongoDB | Public database exposure | MongoDB is in `PublicSubnet1` and the stack outputs the database public IP | 25 | Mike / Shared | Template evidence found, AWS screenshot needed |
| 3 | MongoDB | Weak authentication | No MongoDB user or `security.authorization` setting is shown | 20 | Mike | Template evidence found, live test needed |
| 4 | Web dashboard | Unauthorised dashboard viewing | The webserver is public and the dashboard displays operational/personnel data | 20 | Pantelis | Template and live dashboard evidence found |
| 5 | Data | Personnel data disclosure | Seed data includes names, contacts, roles and clearance levels | 20 | Pantelis / Mike | Template, seed and live page evidence found |
| 6 | Network | Weak tier separation | Webserver and MongoDB are both placed in the public tier | 20 | Shared | Template and stack output evidence found |
| 7 | Web app | Information leakage | PHP errors and database exceptions are shown to users | 16 | Pantelis | Template evidence found |
| 8 | MongoDB | Weak recovery after data loss | No backup, snapshot or restore process is shown | 15 | Mike | Missing evidence, AWS check needed |
| 9 | Monitoring | Late detection | No clear VPC Flow Logs, CloudWatch alarms or database log collection shown | 12 | Shared | Missing evidence, AWS check needed |
| 10 | Optional VDI | Remote desktop exposure | RDP allows `3389` from `0.0.0.0/0` if deployed | 16 | Shared | Only applies if VDI is used |

## Top Risks Explained Simply

### 1. Public MongoDB Access

MongoDB uses port 27017. The template opens this port to `0.0.0.0/0`, which means any internet address can attempt to connect. This is high risk because the database holds personnel and operational data.

Evidence:

1. `cfstack.yml` lines 154 to 164.
2. `cfstack.yml` lines 193 to 195.
3. `DBLoad.js` lines 38 to 54.

### 2. Public Web Application Data

The webserver allows HTTP from the internet. The dashboard then displays city operations data and personnel data. If the page is public, a person does not need a special account to view information that should be controlled.

Evidence:

1. `cfstack.yml` lines 205 to 215.
2. `cfstack.yml` lines 326 to 337.
3. `DBLoad.js` lines 38 to 54.
4. Live dashboard screenshot `web_dashboard_live_2026-05-15.png`.
5. Live HTTP headers in `2026-05-15_dashboard_http_headers.txt`.

### 3. Weak Network Separation

The public subnet assigns public IP addresses and has a route to the internet gateway. MongoDB is placed in the public subnet. This makes the database easier to reach than it should be.

Evidence:

1. `cfstack.yml` lines 49 to 68.
2. `cfstack.yml` lines 109 to 115.
3. `cfstack.yml` lines 170 to 177.

### 4. Error Information Leakage

PHP errors are enabled in the template. If the application breaks, error messages may show paths, connection details, or technical information that helps an attacker.

Evidence:

1. `cfstack.yml` lines 267 to 278.
2. `cfstack.yml` lines 363 to 365.

## Notes For Pantelis

Webserver evidence collected:

1. Security group command output showing port `80` open to `0.0.0.0/0`.
2. Stack output showing the webserver public IP.
3. Live dashboard HTTP headers.
4. Live dashboard HTML capture.
5. Live dashboard screenshot.

Webserver evidence still useful:

1. AWS console screenshot showing the webserver security group inbound rules.
2. AWS console screenshot showing subnet and public IP.
3. Expanded dashboard screenshots for personnel data and operational logs.
4. Evidence of whether HTTP only is used or HTTPS is enabled.
5. Evidence of webserver logging, WAF, CloudFront, or lack of those controls.

The main webserver risks are public access, exposed personnel data, no visible protection layer, and error messages shown to users.

## Notes For Mike

Database evidence needed:

1. Screenshot of the MongoDB security group inbound rules.
2. Screenshot showing the database instance is in a public subnet.
3. Confirmation of whether authentication is enabled.
4. Confirmation of whether MongoDB is reachable from outside the VPC.
5. Evidence of backup or recovery settings, if any.

The main database risks are public database exposure, open MongoDB port, public IP use, weak access restriction, and lack of recovery evidence.

## Shared Checks

Shared evidence needed:

1. VPC diagram or AWS screenshot showing public and private subnets.
2. Route table screenshot showing internet gateway route.
3. Security group screenshots for webserver, MongoDB, and optional VDI.
4. A short note explaining which risks are accepted and which are treated.
5. A later residual risk score after controls are added.

## Current Position

This is a developed starting matrix. It is a realistic prototype for Week 4 without padding the same issue repeatedly, but the scores still need to be checked against the deployed AWS environment and screenshots.

The Week 4 submission should not claim that controls are finished. It should clearly show the starting risk picture and what evidence was used.

## Sources To Keep With The Notes

1. GOV.UK, Data Protection Act 2018 collection: https://www.gov.uk/government/collections/data-protection-act-2018
2. GOV.UK, Data (Use and Access) Act 2025 collection: https://www.gov.uk/government/collections/data-use-and-access-act-2025
3. GOV.UK, Data (Use and Access) Act 2025: data protection and privacy changes: https://www.gov.uk/guidance/data-use-and-access-act-2025-data-protection-and-privacy-changes
4. `cfstack.yml` and `DBLoad.js` in the project repository.

## How To Present This

Use this order:

1. Start with the simple system view.
2. Explain that the risk is a chain, not just one mistake.
3. Show the ATV matrix.
4. Talk through the top four risks.
5. Explain who owns each part.
6. End by saying the next step is treatment plans and residual risk.

Short speaking version:

```text
We looked at the deployment before controls were applied. The main issue is that both the webserver and MongoDB are exposed in a public design. The webserver is open on port 80 and the database is open on port 27017. The application also shows personnel data, so the consequence is high. Our ATV matrix shows the highest risks around MongoDB exposure, public application data, and weak network separation. Pantelis is covering the webserver risks, Mike is covering the database risks, and we will handle the network and final treatment plan together.
```
