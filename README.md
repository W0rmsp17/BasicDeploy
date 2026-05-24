# Basic Teams App Infrastructure Deployment

This repository contains a study and portfolio project for a serverless Microsoft 365 user onboarding solution.

The intended scenario is an MSP-managed onboarding workflow where a client tenant user submits a request from Microsoft Teams, an MSP operator approves the request by email, and tenant-local Azure Functions create the user in the target Microsoft 365 tenant.

## Current Design

- Target tenant owns the Azure runtime and Microsoft Graph provisioning permissions.
- MSP tenant receives approval email only in the MVP.
- Azure Functions handle request intake, approval callbacks, and provisioning.
- Azure Table Storage stores request state and audit metadata.
- Azure Storage Queue decouples approval from user creation.
- Group-based licensing is preferred over direct license assignment.
- Terraform will provide reusable per-client infrastructure deployment.

## Test Tenants

| Role | Tenant |
| --- | --- |
| Target/client tenant | `CholbingDevoutlook.onmicrosoft.com` |
| MSP/approver tenant | `plutonix.onmicrosoft.com` |

## Repository Layout

```text
BasicTeamsAppInfDeploy/
  BasicTeamsAppInfDeploy.sln
  docs/
    architecture.md
    implementation-plan.md
  teams-app/
    README.md
    src/
    manifest/
  BasicTeamsAppInfDeploy/
    BasicTeamsAppInfDeploy.csproj
```

## Documentation

- [Architecture](BasicTeamsAppInfDeploy/docs/architecture.md)
- [Implementation Plan](BasicTeamsAppInfDeploy/docs/implementation-plan.md)
- [Local Development](BasicTeamsAppInfDeploy/docs/local-development.md)
- [Teams Frontend](BasicTeamsAppInfDeploy/teams-app/README.md)

## Deployment Modes

The solution will support two setup paths:

- **Bootstrap mode:** Terraform/setup scripts create Azure resources and privileged Entra configuration during deployment.
- **Manual identity mode:** privileged app registrations, Graph consent, groups, and secrets are pre-created and passed into the deployment as configuration.

Manual identity mode is the preferred production path for clients that require change control over privileged identity resources.
