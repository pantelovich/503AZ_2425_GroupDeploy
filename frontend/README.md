# CivicNexus Operator Frontend

This is the optional 402-style add-on.

It uses:

- React frontend
- Amplify UI/Auth
- Cognito user pool from `cfstack-402-serverless.yml`
- API Gateway HTTP API
- Lambda
- the existing private MongoDB-backed CivicNexus web tier

## Configure

Deploy `cfstack-secure.yml` first, then deploy `cfstack-402-serverless.yml`.

Copy the `AmplifyEnvExample` output from the 402 stack into `.env.local`.

Example:

```bash
cp .env.example .env.local
```

Update `.env.local` with the real CloudFormation outputs.

The frontend calls the Cognito-protected `/items` API route. A request without a valid JWT should be rejected by API Gateway.

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
