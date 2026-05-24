# Serverless Microsoft 365 User Onboarding Teams App

Reusable study and portfolio project for a basic Microsoft 365 user onboarding workflow delivered through Microsoft Teams.

The solution is designed for MSP-style scenarios: a client tenant user submits an onboarding request from Teams, an MSP operator receives an approval email, and tenant-local Azure Functions provision the user in the target Microsoft 365 tenant.

## What This Builds

- Microsoft Teams tab frontend hosted on Azure Static Web Apps.
- .NET isolated Azure Functions backend.
- Azure Table Storage request/audit state.
- Azure Storage Queue handoff from approval to provisioning.
- Microsoft Graph approval email via `sendMail`.
- Microsoft Graph user creation.
- Optional group-based licensing support.
- Terraform runtime deployment per client tenant.
- Setup scripts for discovery, deployment, validation, and Teams app assignment group creation.

## Architecture

```text
Teams tab
  -> Azure Static Web Apps
  -> SubmitOnboardingRequest HTTP Function
  -> Table Storage request record
  -> Graph approval email to MSP

Approval link
  -> Approve/Deny HTTP Function
  -> Storage Queue command
  -> CreateUser queue Function
  -> Microsoft Graph creates user
  -> Optional group assignment for licensing
```

The runtime is deployed into the target/client tenant. The MSP tenant participates only by receiving approval email in the MVP.

## Repository Layout

```text
BasicTeamsAppInfDeploy/
  deploy.ps1                         # Main deployment orchestrator
  BasicTeamsAppInfDeploy.sln          # .NET Functions solution
  BasicTeamsAppInfDeploy/             # Azure Functions app
  BasicTeamsAppInfDeploy.Tests/       # Unit tests
  teams-app/                          # React/Vite Teams frontend and manifest template
  infra/
    bootstrap-app-registration/       # Optional Graph app registration bootstrap
    environments/cholbing-dev/        # Sample client environment
    modules/runtime/                  # Reusable Azure runtime Terraform module
  docs/
    architecture.md
    deployment.md
    local-development.md
    troubleshooting.md
```

## Deployment Model

The intended experience is:

```powershell
cd BasicTeamsAppInfDeploy
.\deploy.ps1
```

The main script can run discovery, plan/apply Terraform, deploy the Function App package, deploy the Teams frontend, generate a Teams manifest, and prepare an Entra group for Teams app assignment.

Implementers can deploy from this repository or from their own fork:

```powershell
.\deploy.ps1 -RepositoryUrl https://github.com/example/m365-onboarding.git -CheckoutPath C:\Deploy\m365-onboarding
```

## Prerequisites

- Azure subscription in the target tenant.
- Azure CLI signed in to the target tenant.
- Terraform.
- .NET 8 SDK.
- Node.js and npm.
- Microsoft 365 account with privileges to grant Graph application consent, or pre-created app registration values.
- Licensed Exchange Online mailbox for the configured approval sender UPN.

## Setup Paths

| Path | Use when |
| --- | --- |
| Bootstrap identity | Lab or MSP setup has enough tenant privileges to create the Graph app registration and consent. |
| Manual identity | Client/security team pre-creates the app registration, secret, consent, and optional groups. |

Manual identity mode is the safer production pattern because privileged Entra changes stay under the client's change-control process.

## Quick Start

1. Clone the repository.
2. Install prerequisites.
3. Copy the sample environment tfvars:

```powershell
Copy-Item .\BasicTeamsAppInfDeploy\infra\environments\cholbing-dev\terraform.tfvars.example `
  .\BasicTeamsAppInfDeploy\infra\environments\cholbing-dev\terraform.tfvars
```

4. Fill in the local `terraform.tfvars` values, or run discovery:

```powershell
cd .\BasicTeamsAppInfDeploy\infra\environments\cholbing-dev
.\discover-prereqs.ps1 -WriteTfvars
```

5. Run the main deployment:

```powershell
cd ..\..\..
.\deploy.ps1
```

For a safe plan-only run:

```powershell
.\deploy.ps1 -SkipTerraformApply -SkipFunctionDeploy -SkipTeamsFrontendDeploy -SkipTeamsManifest -SkipTeamsAppGroup
```

## Important Manual Steps

Some Microsoft 365 tenant actions are intentionally explicit:

- Grant Microsoft Graph admin consent if bootstrap does not complete it.
- Ensure the sender UPN has an active Exchange Online mailbox.
- Upload or publish the generated Teams app package.
- Assign the Teams app to the generated Entra group through Teams admin center or Teams policy tooling.
- Optionally restrict Graph `Mail.Send` to the dedicated sender mailbox with Exchange controls.

## Documentation

- [Architecture](BasicTeamsAppInfDeploy/docs/architecture.md)
- [Deployment Guide](BasicTeamsAppInfDeploy/docs/deployment.md)
- [Local Development](BasicTeamsAppInfDeploy/docs/local-development.md)
- [Troubleshooting](BasicTeamsAppInfDeploy/docs/troubleshooting.md)
- [Implementation Plan](BasicTeamsAppInfDeploy/docs/implementation-plan.md)
- [Teams Frontend](BasicTeamsAppInfDeploy/teams-app/README.md)

## Current Status

This is an MVP/starter solution. It demonstrates a portable serverless onboarding pattern, but production use should add tenant-specific hardening such as stronger Teams authentication, Exchange `Mail.Send` scoping, protected remote Terraform state, and formal operational monitoring.
