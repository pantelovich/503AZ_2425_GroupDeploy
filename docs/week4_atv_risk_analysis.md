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

This draft covers the first risk analysis for the CivicNexus AWS deployment. It is based on the CloudFormation template and the database load script in this repository.

The analysis uses the ATV method:

1. Asset.
2. Threat.
3. Vulnerability.

The aim is to identify the main risks before the controls are applied. The treatment work comes after this, using the risk scores and evidence from this document.

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

The current evidence is from the repository files:

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

AWS console screenshots still need to be collected after deployment.

## Draft ATV Matrix

| Asset ID | Asset | Consequence | Threat ID | Threat | Vulnerability ID | Vulnerability | Likelihood | Overall | Action | Owner |
|---|---|---:|---|---|---|---|---:|---:|---|---|
| A1 | Public webserver and application | 5 | A1T1 | Unauthorised access to public application data | A1T1V1 | The dashboard is public over HTTP and displays operational data | 4 | 20 | Treat | Pantelis |
| A1 | Public webserver and application | 5 | A1T2 | Disclosure of personnel information | A1T2V1 | Personnel data is displayed in the web application | 4 | 20 | Treat | Pantelis |
| A1 | Public webserver and application | 4 | A1T3 | Webserver information leakage | A1T3V1 | PHP errors are displayed to users | 4 | 16 | Treat | Pantelis |
| A1 | Public webserver and application | 4 | A1T4 | Application layer denial of service | A1T4V1 | Public HTTP service has no visible WAF, rate limit, or CloudFront layer | 3 | 12 | Treat | Pantelis |
| A2 | MongoDB database | 5 | A2T1 | Unauthorised database access | A2T1V1 | MongoDB port 27017 is open to `0.0.0.0/0` | 5 | 25 | Treat | Mike |
| A2 | MongoDB database | 5 | A2T2 | Direct database connection from the internet | A2T2V1 | MongoDB is placed in a public subnet and uses a public IP | 5 | 25 | Treat | Mike |
| A2 | MongoDB database | 5 | A2T3 | Data breach of employee and operational data | A2T3V1 | Database contains personnel and operational data | 4 | 20 | Treat | Mike |
| A2 | MongoDB database | 4 | A2T4 | Data loss or weak recovery | A2T4V1 | No backup or recovery process is shown in the template | 3 | 12 | Treat | Mike |
| A3 | VPC and network | 5 | A3T1 | Internet exposure of internal services | A3T1V1 | Public subnets assign public IPs and route to the internet gateway | 4 | 20 | Treat | Shared |
| A3 | VPC and network | 4 | A3T2 | Weak network separation | A3T2V1 | Web and database resources are both in the public subnet area | 4 | 16 | Treat | Shared |
| A3 | VPC and network | 4 | A3T3 | Over permissive inbound access | A3T3V1 | Security groups allow public access to important services | 4 | 16 | Treat | Shared |
| A4 | Deployment and configuration | 4 | A4T1 | Insecure default deployment | A4T1V1 | Template deploys intentionally insecure resources unless changed | 4 | 16 | Treat | Shared |
| A4 | Deployment and configuration | 4 | A4T2 | Configuration drift after deployment | A4T2V1 | No monitoring or change review process is shown in the repo | 3 | 12 | Treat | Shared |
| A5 | Optional VDI | 4 | A5T1 | Remote desktop compromise | A5T1V1 | Optional RDP access allows port 3389 from `0.0.0.0/0` | 4 | 16 | Treat if used | Shared |

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

Webserver evidence needed:

1. Screenshot of the webserver security group inbound rules.
2. Screenshot showing the web application is reachable from the public internet.
3. Screenshot or page capture showing what data the dashboard displays.
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

This is a starting draft. The scores are based on the template and need to be checked against the deployed AWS environment.

The Week 4 submission should not claim that controls are finished. It should clearly show the starting risk picture and what evidence was used.

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

