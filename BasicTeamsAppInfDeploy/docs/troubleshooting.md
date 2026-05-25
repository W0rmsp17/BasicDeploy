# Troubleshooting

## Graph Consent Missing

Symptom:

```text
Missing admin consent for: Mail.Send, User.ReadWrite.All
```

Fix:

```powershell
.\test-graph-app.ps1 -AttemptAdminConsent
.\test-graph-app.ps1
```

The signed-in account must have a tenant role that can grant application consent.

## Graph sendMail Fails After Licensing

If the sender user was just licensed, Exchange Online mailbox provisioning can lag behind Entra license assignment.

Checks:

- Confirm the sender can open Outlook on the web.
- Confirm `test-graph-app.ps1` reports admin consent is present.
- Retry a request after the mailbox becomes accessible.

If the Function App is already set to `Approval__Provider=Graph`, submit requests may return `500` until Graph `sendMail` succeeds. Temporarily use logging mode to keep intake validation working:

```powershell
.\deploy.ps1 -ApprovalProvider Logging -SkipDiscovery -SkipFunctionDeploy -SkipTeamsFrontendDeploy -SkipTeamsManifest -SkipTeamsAppGroup
```

Switch back when ready:

```powershell
.\deploy.ps1 -ApprovalProvider Graph -SkipDiscovery -SkipFunctionDeploy -SkipTeamsFrontendDeploy -SkipTeamsManifest -SkipTeamsAppGroup
```

## External Approval Email Is Rejected

If same-tenant approval email works but external approval email is rejected, treat it as an Exchange Online delivery issue rather than an application failure.

Common signs:

- The submit endpoint returns `202`.
- The sender mailbox receives an NDR.
- The NDR says the remote server returned a `550 5.7.x` delivery error.
- The recipient tenant may not show the message in message trace if Microsoft edge filtering rejected it before tenant-level acceptance.

For new tenants, trial tenants, or `onmicrosoft.com`-only sender domains, external recipients may reject mail because of sender reputation or edge filtering.

Recommended production pattern:

- Use a dedicated approval sender mailbox.
- Use a mature verified client domain rather than relying only on an `onmicrosoft.com` address.
- Verify SPF, DKIM, and DMARC for the sender domain where applicable.
- Keep approval email volume low and operationally normal.
- Ask the recipient/MSP tenant to review mail flow, quarantine, and allow policies only if needed.

For lab testing, use an internal approver mailbox to validate the approval and provisioning workflow without cross-tenant mail reputation affecting the result.

## Static Web Apps Region Is Not Available

Azure Static Web Apps is not available in every Azure region.

Use `discover-prereqs.ps1` to select a supported Static Web Apps region. The sample defaults to `eastasia`.

Known supported regions from the test deployment error were:

- `centralus`
- `eastus2`
- `westus2`
- `westeurope`
- `eastasia`

## Function App Does Not Discover Functions

Run:

```powershell
.\deploy-function.ps1
.\test-function-deployment.ps1
```

The verification restarts the Function App and confirms these functions are discovered:

- `SubmitOnboardingRequest`
- `ApproveOnboardingRequest`
- `DenyOnboardingRequest`
- `CreateUser`

## Approval Links Use The Placeholder URL

The first Terraform apply uses a placeholder approval base URL.

Run:

```powershell
.\post-deploy.ps1
```

`deploy-function.ps1` runs this automatically unless `-SkipPostDeploy` is supplied.

## Terraform Provider Inconsistent Final Plan

If Terraform creates Static Web Apps and then fails while updating Function CORS, rerun the deployment. Once the Static Web Apps hostname exists, a second apply should converge the Function CORS setting.
