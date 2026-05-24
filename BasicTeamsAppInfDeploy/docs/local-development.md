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
| `Approval__Provider` | Use `Logging` locally or `Graph` for real Graph sendMail |
| `Approval__BaseUrl` | Base URL used when generating approval links |
| `Approval__RecipientEmail` | MSP approval recipient |
| `Approval__SenderUserPrincipalName` | Dedicated target tenant mailbox used as the Graph sendMail sender |
| `Approval__TokenSigningKey` | HMAC key used to sign approval tokens |
| `Graph__TenantId` | Target tenant ID for app-only Graph auth |
| `Graph__ClientId` | App registration client ID with Graph permissions |
| `Graph__ClientSecret` | App registration secret for local/manual testing |
| `Storage__OnboardingRequestsTableName` | Azure Table Storage table for onboarding request state |
| `Provisioning__Provider` | Use `Logging` locally or `Graph` for real user creation |
| `Provisioning__DefaultUserDomain` | Target tenant user domain |
| `Provisioning__CreateDisabledUsers` | Whether created users should be disabled by default |
| `Provisioning__LicenseAssignmentMode` | `None`, `DynamicGroup`, or `StaticGroup` |
| `Provisioning__LicenseGroupId` | Required only when `Provisioning__LicenseAssignmentMode=StaticGroup` |

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

Set `Approval__Provider` to `Logging` for local development without sending email. Set it to `Graph` to send approval email through Microsoft Graph `sendMail`.

When using `Graph`, the app registration needs `Mail.Send` application permission and should be restricted to the configured sender mailbox in production.

Set `Provisioning__Provider` to `Logging` for local development without creating users. Set it to `Graph` to create users and optionally add them to the configured licensing group.
