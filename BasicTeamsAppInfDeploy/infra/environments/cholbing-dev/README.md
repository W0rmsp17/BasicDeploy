# Sample Client Environment

This folder is a reusable sample client environment. Copy it or use it as a template when creating a deployment for another target tenant.

The environment deploys the Azure runtime into the selected target tenant and subscription. Tenant-specific values belong in the ignored local `terraform.tfvars` file, not in committed Terraform.

Approval email is sent to the actor-supplied MSP or service desk mailbox.

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

The script signs in through Azure CLI, lets the actor select tenant, subscription, core Azure region, and Static Web Apps region by number, gathers sender/recipient UPN values, generates an approval token signing key, and prints suggested `terraform.tfvars` content.

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

The root deployment wrapper can sequence these steps for the selected environment:

```powershell
cd ..\..\..
.\deploy.ps1
```

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

## Deploy Teams Frontend

The frontend is hosted from Azure Static Web Apps so users access it through Teams without running a local server.

After Terraform apply:

```powershell
.\deploy-teams-frontend.ps1
```

The script builds `teams-app`, deploys the `dist` folder to the Static Web App, and bakes the Function App base URL into the bundle. It does not bake a Function key into the bundle.

Generate a tenant-specific Teams manifest after the Static Web App exists:

```powershell
.\new-teams-manifest.ps1
```

The generated manifest is written under `teams-app\manifest\.generated\manifest.json`.

Package the Teams app manifest and icon assets:

```powershell
.\new-teams-package.ps1
```

The generated package is written under `teams-app\manifest\.generated\m365-onboarding-teams-app.zip`.

Publish the Teams app package and assign a Teams setup policy to the assignment group:

```powershell
.\publish-teams-app.ps1
```

The script uses Microsoft Teams PowerShell with device-code authentication. The signed-in account needs a Teams-capable license and the Teams Administrator role.

## Teams App Assignment Group

Create or update the target tenant Entra group used to scope access to the Teams app:

```powershell
.\ensure-teams-app-group.ps1
```

By default, the script creates `M365 Onboarding Teams App Users` if needed and prompts for the target user UPN to add.

After the Teams app package is uploaded or published, use this group in Teams admin center for the app assignment or setup policy. That policy step is intentionally separate because it depends on the tenant's Teams admin model and the uploaded Teams app package.

## Graph Readiness

Before testing Graph email or Graph user creation, verify the app registration:

```powershell
.\test-graph-app.ps1
```

If admin consent is missing, sign in with a Global Administrator or suitable privileged Entra role and run:

```powershell
.\test-graph-app.ps1 -AttemptAdminConsent
```

Graph approval email also requires the configured `approval_sender_user_principal_name` to have an active Exchange Online mailbox. Graph `sendMail` can fail even when app consent is correct if the mailbox is not provisioned yet.

Use logging mode for validation when Graph consent or mailbox readiness is not complete:

```powershell
cd ..\..\..
.\deploy.ps1 -ApprovalProvider Logging -SkipDiscovery -SkipFunctionDeploy -SkipTeamsFrontendDeploy -SkipTeamsManifest -SkipTeamsAppGroup
```

Set it back to `Graph` before testing real approval email delivery.
