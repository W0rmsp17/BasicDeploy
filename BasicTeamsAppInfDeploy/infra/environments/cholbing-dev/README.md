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

## Post-Deploy Approval URL

The first Terraform apply uses a placeholder `Approval__BaseUrl` to avoid a dependency cycle with the generated Function App hostname.

After apply, update the app setting to the generated Function App URL:

```powershell
.\post-deploy.ps1
```

The script reads Terraform outputs, builds `https://<function-app-hostname>`, updates `Approval__BaseUrl`, and prints the final value.
