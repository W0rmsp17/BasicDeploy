# Cholbing Dev Environment

This environment deploys the Azure runtime for the target test tenant:

```text
CholbingDevoutlook.onmicrosoft.com
```

Approval email is sent to an actor-supplied mailbox, expected to be in:

```text
plutonix.onmicrosoft.com
```

## Required Inputs

Copy `terraform.tfvars.example` to a local `terraform.tfvars` file and provide:

- `graph_tenant_id`
- `graph_client_id`
- `graph_client_secret_value` or `graph_client_secret_key_vault_secret_id`
- `approval_recipient_email`
- `approval_sender_user_principal_name`
- `approval_token_signing_key`

`terraform.tfvars` is ignored by git.

## Discovery

Run the discovery script before bootstrap/runtime deployment:

```powershell
.\discover-prereqs.ps1
```

The script signs in through Azure CLI, lets the actor select tenant and subscription by number, gathers sender/recipient UPN values, generates an approval token signing key, and prints suggested `terraform.tfvars` content.

It also asks for the target tenant deployment account UPN and one of four deployment paths:

1. Bootstrap app registration and deploy runtime
2. Use manually configured app registration and deploy runtime
3. Bootstrap app registration only
4. Deploy runtime only from existing app registration values

To write the local ignored `terraform.tfvars` file:

```powershell
.\discover-prereqs.ps1 -WriteTfvars
```

## Commands

```powershell
..\..\..\..\terraform.exe init
..\..\..\..\terraform.exe validate
..\..\..\..\terraform.exe plan
```

Do not run `apply` until the plan and input values have been reviewed.

## Deploy Function Code

After Terraform apply:

```powershell
.\deploy-function.ps1
```

The script builds the .NET Azure Functions project, creates a zip package, deploys it to the Function App from Terraform outputs, and runs `post-deploy.ps1` unless `-SkipPostDeploy` is supplied.

It also runs `test-function-deployment.ps1` unless `-SkipVerification` is supplied. The verification restarts the Function App, checks the host state, and confirms Azure discovered the expected Functions.

To run verification on its own:

```powershell
.\test-function-deployment.ps1
```

## Post-Deploy Approval URL

The first Terraform apply uses a placeholder `Approval__BaseUrl` to avoid a dependency cycle with the generated Function App hostname.

After apply, update the app setting to the generated Function App URL:

```powershell
.\post-deploy.ps1
```

The script reads Terraform outputs, builds `https://<function-app-hostname>`, updates `Approval__BaseUrl`, and prints the final value.

## Graph Readiness

Before testing Graph email or Graph user creation, verify the app registration:

```powershell
.\test-graph-app.ps1
```

If admin consent is missing, sign in with a Global Administrator or suitable privileged Entra role and run:

```powershell
.\test-graph-app.ps1 -AttemptAdminConsent
```

Graph approval email also requires the configured `approval_sender_user_principal_name` to have an Exchange Online mailbox. If that user is unlicensed or has no mailbox, Graph `sendMail` will fail even when app consent is correct.

While waiting for mailbox licensing or admin consent, you can smoke-test request storage and approval-link generation by temporarily setting approval notifications to logging:

```powershell
az functionapp config appsettings set `
  --resource-group rg-onboard-cholbing-dev `
  --name <function-app-name> `
  --settings Approval__Provider=Logging
```

Set it back to `Graph` before testing real approval email delivery.
