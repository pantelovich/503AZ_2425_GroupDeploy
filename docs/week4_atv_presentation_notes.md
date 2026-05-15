# Week 4 ATV Presentation Notes

## Main Message

This is not just an AWS build. We deploy the baseline with CloudFormation, then review the AWS resources and template evidence like a weak cloud system.

The main risk chain is:

```text
internet -> public webserver -> public MongoDB -> sensitive data
```

The full Excel matrix has 49 evidence-backed risk entries. In the presentation, we only explain the main pattern and the highest risks.

## What To Say First

We used the ATV method, which means:

1. Asset.
2. Threat.
3. Vulnerability.

For each risk, we scored consequence and likelihood from 1 to 5. The overall score is consequence multiplied by likelihood.

Also say:

```text
Before scoring, we looked at the context. The system handles personnel and operational data, so our risk appetite is low for public database access and personal data exposure.
```

If the tutor asks about the "crown jewels", say:

```text
The crown jewels are the personnel data, the operational dashboard data, MongoDB, the web dashboard, and the network controls around them.
```

If the tutor asks about law, say:

```text
UK GDPR and the Data Protection Act 2018 still matter because the system may hold personal data. The Data Use and Access Act 2025 updates parts of the law, but it does not remove the need to protect personal data.
```

## Slide Or Report Order

1. Scope.
2. System view.
3. Scoring method.
4. Risk heat map.
5. ATV matrix.
6. Top webserver risks.
7. Top database risks.
8. Shared network risks.
9. Evidence still needed.
10. Next step.

## Pantelis Part

Say:

```text
My part is the webserver and application tier. The webserver is public on port 80 and the dashboard displays operational and personnel data. That creates a high consequence because the data should not be available without proper control. I also found that PHP errors are enabled, which can leak technical information if the app fails.
```

Evidence to show:

1. Webserver security group inbound rule.
2. Public IP or public URL of the dashboard.
3. Screenshot of the live dashboard data.
4. Template lines for port 80 and error display.

## Mike Part

Mike can say:

```text
My part is the MongoDB database. The main issue is that MongoDB is open on port 27017 to the internet. The database instance is also placed in a public subnet. Since the database contains personnel and operational data, this creates the highest risk score in our matrix.
```

Evidence to show:

1. MongoDB security group inbound rule.
2. MongoDB instance subnet and public IP.
3. MongoDB bind setting from the template.
4. Database contents from `DBLoad.js`.

## Shared Part

Say:

```text
Together we looked at the network design. The public subnets assign public IPs and route traffic to the internet gateway. This is expected for a public webserver, but not for the database. The shared network risk is that the design does not separate public and private services enough.
```

Evidence to show:

1. Public subnet settings.
2. Route table to internet gateway.
3. Security group rules.
4. Resource placement.

## Top Four Risks To Remember

| Rank | Risk | Owner | Score |
|---:|---|---|---:|
| 1 | MongoDB open to the internet on port `27017` | Mike | 25 |
| 2 | MongoDB in public subnet / public addressing | Mike / Shared | 25 |
| 3 | No clear MongoDB authentication in template | Mike | 20 |
| 4 | Public dashboard displays personnel and operational data | Pantelis | 20 |
| 5 | Weak separation between webserver and database tiers | Shared | 20 |
| 6 | No clear backup or restore process | Mike | 15 |
| 7 | PHP errors shown to users | Pantelis | 16 |
| 8 | No clear monitoring or alerting | Shared | 12 |

Say:

```text
The full matrix has more rows, but these are the main risks we would explain first.
```

## Easy Lines To Memorise

```text
The problem is the exposure chain.
```

```text
The crown jewels are the data and the systems that expose or protect that data.
```

```text
The webserver is public, which may be acceptable, but the database should not be public.
```

```text
The risk score is high because the data includes personnel and operational information.
```

```text
Week 4 is the risk picture. Week 5 is where controls become more important.
```

## What Not To Say

Do not say the system is fully secured yet.

Do not say AWS console screenshots exist until we actually have them.

Do not say a control is implemented unless it is visible in AWS or the template.

Do not over explain ISO. Only mention it when linking risks to controls.

If the tutor challenges the evidence, say:

```text
At this stage, we have template evidence, seed-data evidence, and live webserver evidence. The live dashboard responds from the public IP. We still need some AWS console screenshots because they are clearer for the report than command output.
```

## Next Step After Week 4

The next step is risk treatment:

1. Choose treatment option.
2. Select controls.
3. Record owner.
4. Add evidence.
5. Score residual risk.
