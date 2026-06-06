# CivicNexus Final Demo Steps

Use this as the quick guide for finding and showing the final work.

## 1. Repo And Branch

1. Open the repo:
   `/Users/pantelos/Documents/GitHub/503AZ_2425_GroupDeploy`
2. Use branch:
   `week6-team-submission-merge`
3. Important files:
   - `cfstack-secure.yml` - main secure stack with PublicVPC, PrivateVPC, Transit Gateway, web, OpenVPN, MongoDB and VDI.
   - `cfstack-402-serverless.yml` - Cognito, API Gateway and Lambda add-on.
   - `docs/team_asset_ownership.md` - who owns which asset.
   - `docs/manual_mongodb_openvpn_runbook.md` - Mike's MongoDB/OpenVPN manual setup steps.
   - `docs/final_demo_steps.md` - this guide.

## 2. AWS Console: Main Stack

1. Open AWS Console.
2. Go to CloudFormation.
3. Open stack:
   `pantelis-civicnexus-stack`
4. Show `CREATE_COMPLETE`.
5. Open Outputs and show:
   - `PublicVpcId`
   - `PrivateVpcId`
   - `TransitGatewayId`
   - `WebServerPublicIP`
   - `MongoReplicaPrivateIPs`
   - `OpenVPNServerPublicIP`
   - `VDIPrivateIP`

## 3. AWS Console: Two VPCs

1. Go to VPC > Your VPCs.
2. Show:
   - `civicnexus-public-vpc-pantelis` = `10.0.0.0/16`
   - `civicnexus-private-vpc-pantelis` = `192.168.0.0/16`
3. Explain:
   - PublicVPC holds web, NAT and OpenVPN/bastion.
   - PrivateVPC holds MongoDB and VDI.

## 4. AWS Console: Transit Gateway

1. Go to VPC > Transit Gateways.
2. Show:
   `civicnexus-tgw-pantelis`
3. Open Transit Gateway Attachments and show:
   - PublicVPC attachment
   - PrivateVPC attachment
4. Open Transit Gateway Route Tables and show:
   - Public side route to `192.168.0.0/16`
   - Private side route to `10.0.0.0/16`

## 5. AWS Console: EC2 Instances

1. Go to EC2 > Instances.
2. Search `civicnexus`.
3. Show:
   - Web server in PublicVPC with public IP.
   - OpenVPN/bastion in PublicVPC with Elastic IP.
   - MongoDB 1, 2 and 3 in PrivateVPC with no public IP.
   - VDI in PrivateVPC with no public IP.

## 6. Security Groups

Show these points:

1. Web SG:
   - inbound HTTP `80` from public internet.
   - egress MongoDB `27017` only to `192.168.0.0/16`.
2. MongoDB SG:
   - no public inbound.
   - MongoDB `27017` only from internal trusted paths.
   - SSH only from PublicVPC/OpenVPN path.
3. OpenVPN SG:
   - admin access restricted to current public IP `/32`.
4. VDI SG:
   - no public RDP.
   - RDP only from internal/admin path.

## 7. Web Demo

1. Use CloudFormation output:
   `WebServerPublicIP`
2. Open:
   `http://<WebServerPublicIP>`
3. Show the CivicNexus dashboard.
4. Show that `/health.php` reports `status: ok` and `database: reachable`.
5. Show the city records in the table and the restricted personnel/log fields.

## 8. Serverless/API Demo

1. Open CloudFormation stack:
   `pantelis-402-serverless-addon`
2. Show Outputs:
   - `ServerlessApiUrl`
   - `ItemsApiUrl`
   - `CognitoUserPoolId`
   - `CognitoUserPoolClientId`
3. Explain:
   - Cognito protects the API.
   - API Gateway calls Lambda.
   - Lambda uses VPC ENIs in the PublicVPC transit subnets.
   - Lambda reaches the web server private endpoint, and the web tier reaches MongoDB through the Transit Gateway.

## 9. Evidence Folder

Fresh AWS evidence is here:

`/Users/pantelos/Library/CloudStorage/OneDrive-CoventryUniversity/Michalis Nicolaou's files - 503 Cloud Security/503AZ Shared Work/Evidence/Raw AWS Output/2026-06-06_final_tgw_live`

Main subfolders:

- `network` - CloudFormation and audit evidence.
- `mongodb` - MongoDB private IP and SG evidence.
- `web` - web server, headers and dashboard evidence.
- `serverless` - Cognito/API Gateway/Lambda evidence.
- `vdi` - VDI private instance and encryption evidence.

## 10. Presentation PDF

Ready-to-read guide:

`/Users/pantelos/Downloads/503AZ_CivicNexus_Ready_To_Present_Guide.pdf`

Use it to revise the story from simple to advanced:

1. Baseline problem.
2. Risk assessment.
3. Public/private separation.
4. Two VPCs and Transit Gateway.
5. Web, API, MongoDB, OpenVPN and VDI controls.
6. What to say in the presentation.
