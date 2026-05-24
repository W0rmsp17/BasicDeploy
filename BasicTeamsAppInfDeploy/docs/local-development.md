# Local Development

## Prerequisites

- .NET 8 SDK or newer.
- Azure Functions Core Tools v4 for local function hosting.
- Azurite or a real Azure Storage account for queue-trigger execution.

## Local Settings

Create a local settings file from the sample:

```text
BasicTeamsAppInfDeploy/BasicTeamsAppInfDeploy/local.settings.sample.json
```

The real local file should be named:

```text
BasicTeamsAppInfDeploy/BasicTeamsAppInfDeploy/local.settings.json
```

`local.settings.json` is intentionally ignored by git.

Required values:

| Setting | Purpose |
| --- | --- |
| `AzureWebJobsStorage` | Storage connection for Functions runtime and queue trigger |
| `FUNCTIONS_WORKER_RUNTIME` | Must be `dotnet-isolated` |
| `Approval__BaseUrl` | Base URL used when generating approval links |
| `Approval__RecipientEmail` | MSP approval recipient |
| `Approval__TokenSigningKey` | HMAC key used to sign approval tokens |
| `Storage__OnboardingRequestsTableName` | Azure Table Storage table for onboarding request state |
| `Provisioning__DefaultUserDomain` | Target tenant user domain |
| `Provisioning__CreateDisabledUsers` | Whether created users should be disabled by default |
| `Provisioning__LicenseGroupId` | Optional group for group-based licensing |

## Current Local Endpoints

The initial implementation exposes these Azure Functions:

| Function | Method | Route |
| --- | --- | --- |
| `SubmitOnboardingRequest` | `POST` | `/api/onboarding-requests` |
| `ApproveOnboardingRequest` | `GET` | `/api/onboarding-requests/approve?token=...` |
| `DenyOnboardingRequest` | `GET` | `/api/onboarding-requests/deny?token=...` |
| `CreateUser` | Queue trigger | `create-user` queue |

## Sample Submit Payload

```json
{
  "firstName": "Alex",
  "lastName": "Wilber",
  "jobTitle": "Support Analyst",
  "department": "Operations",
  "managerEmail": "manager@CholbingDevoutlook.onmicrosoft.com",
  "startDate": "2026-06-01",
  "requestedProfile": "Standard",
  "notes": "Test onboarding request"
}
```

The current notifier and provisioner are logging stubs. Storage persistence, real email delivery, and Microsoft Graph provisioning will be added in later phases.
