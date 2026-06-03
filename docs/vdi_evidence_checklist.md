# VDI Evidence Checklist

This checklist covers the CivicNexus VDI asset in the final team submission.

The VDI control goal is secure private provisioning, not public remote desktop access.

## Code Controls

`cfstack-secure.yml` provisions:

- private Windows VDI EC2 instance
- no public IPv4 address
- no public RDP ingress
- encrypted root EBS volume
- IMDSv2 required
- VDI security group with outbound web/DNS setup access and VPC-only internal access
- optional RDP from the OpenVPN security group only when OpenVPN is enabled

## Evidence To Capture

| Check | Expected result |
|---|---|
| VDI instance exists | EC2 instance tagged `civicnexus-vdi-instance-*` |
| Public IP | Empty / none |
| Private IP | Assigned from private subnet |
| Security group ingress | No `0.0.0.0/0` RDP |
| RDP access path | TCP 3389 allowed only from OpenVPN SG when VPN is enabled |
| Metadata options | `HttpTokens=required` |
| Root volume | EBS encryption enabled |
| Subnet | Private subnet |

## Evidence Command

After the stack is deployed, run:

```bash
scripts/collect_vdi_evidence.sh <stack-name> <output-folder>
```

Do not commit raw evidence output to GitHub.

## Report Wording

Use simple wording:

```text
The VDI asset was provisioned as a private Windows EC2 instance. It had no public IPv4 address and no public RDP exposure. Administrative RDP access was designed to come through the OpenVPN security group only when the VPN evidence path is enabled. The instance used IMDSv2 and an encrypted root volume.
```

Do not claim successful Windows login unless a screenshot or command output proves it.
