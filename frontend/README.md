# CivicNexus Operator Frontend

This is the optional 402-style add-on.

It uses:

- React frontend
- Amplify UI/Auth
- Cognito user pool from `cfstack-402-serverless.yml`
- API Gateway HTTP API
- Lambda
- DynamoDB

## Configure

Deploy `cfstack-402-serverless.yml`, then copy the `AmplifyEnvExample` output into `.env.local`.

Example:

```bash
cp .env.example .env.local
```

Update `.env.local` with the real CloudFormation outputs.

## Run

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

The final static files are created in `dist/`.
