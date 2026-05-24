# Serverless Microsoft 365 User Onboarding

Reusable starter solution for a target-tenant Microsoft Teams onboarding app backed by Azure Functions, Azure Storage, Key Vault, Static Web Apps, and Microsoft Graph.

## Portable Deployment Model

The intended flow is:

```powershell
.\deploy.ps1
```

The deployment script sequences discovery, Terraform runtime deployment, Function deployment, Teams frontend deployment, manifest generation, and the Teams app assignment group setup.

For a client or MSP fork, run the same script from that fork. A wrapper can also pull a specific repo first:

```powershell
.\deploy.ps1 -RepositoryUrl https://github.com/example/m365-onboarding.git -CheckoutPath C:\Deploy\m365-onboarding
```

The reusable deployment values belong in the selected environment's ignored `terraform.tfvars` file, not in committed Terraform. Start from:

```powershell
Copy-Item .\infra\environments\cholbing-dev\terraform.tfvars.example .\infra\environments\cholbing-dev\terraform.tfvars
```

The current `cholbing-dev` environment is a sample environment. Override these values for a real client:

- `environment_name`
- `location`
- `target_tenant_domain`
- `msp_tenant_domain`
- `static_web_app_location`
- `graph_tenant_id`
- `graph_client_id`
- Graph client secret source
- Approval sender and recipient
- Licensing mode and optional static group ID

## Main Commands

Validate and plan only:

```powershell
.\deploy.ps1 -SkipTerraformApply -SkipFunctionDeploy -SkipTeamsFrontendDeploy -SkipTeamsManifest -SkipTeamsAppGroup
```

Deploy with logging approvals while Graph consent or mailbox licensing is pending:

```powershell
.\deploy.ps1 -ApprovalProvider Logging
```

Assign a known target user to the Teams app group during deployment:

```powershell
.\deploy.ps1 -TeamsAppUserPrincipalName user@contoso.onmicrosoft.com
```

Run Graph readiness checks after deployment:

```powershell
.\deploy.ps1 -RunGraphReadiness
```

## Manual Tenant Steps

Some tenant controls remain intentionally explicit:

- Grant Microsoft Graph admin consent when required.
- Ensure the configured sender UPN has an Exchange Online mailbox.
- Upload or publish the generated Teams app package.
- Use the generated Entra group for Teams app availability or setup policy assignment.

See [Deployment Guide](docs/deployment.md) for the full setup sequence and [Troubleshooting](docs/troubleshooting.md) for common tenant/runtime issues.
