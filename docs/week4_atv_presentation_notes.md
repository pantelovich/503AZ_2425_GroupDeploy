# Week 4 ATV Presentation Notes

## Main Message

This is not just an AWS build. It is a security review of a weak cloud system.

The main risk chain is:

```text
internet -> public webserver -> public MongoDB -> sensitive data
```

## What To Say First

We used the ATV method, which means:

1. Asset.
2. Threat.
3. Vulnerability.

For each risk, we scored consequence and likelihood from 1 to 5. The overall score is consequence multiplied by likelihood.

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
3. Screenshot of the dashboard data.
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

| Rank | Risk | Why It Matters |
|---:|---|---|
| 1 | Public MongoDB access | Direct database access can expose sensitive records |
| 2 | Public web dashboard | Users may see data without proper access control |
| 3 | Weak network separation | Database is easier to reach than it should be |
| 4 | PHP error display | Error output can leak technical details |

## Easy Lines To Memorise

```text
The problem is the exposure chain.
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

Do not say screenshots exist until we actually have them.

Do not say a control is implemented unless it is visible in AWS or the template.

Do not over explain ISO. Only mention it when linking risks to controls.

## Next Step After Week 4

The next step is risk treatment:

1. Choose treatment option.
2. Select controls.
3. Record owner.
4. Add evidence.
5. Score residual risk.

