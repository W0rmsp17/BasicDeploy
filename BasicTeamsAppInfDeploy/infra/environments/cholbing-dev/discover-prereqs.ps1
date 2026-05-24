param(
    [string] $TerraformPath = "..\..\..\..\terraform.exe",
    [string] $DefaultDeploymentAccountUpn = "admin@contoso.onmicrosoft.com",
    [string] $DefaultApprovalRecipientEmail = "approver@msp.example.com",
    [string] $DefaultApprovalSenderUserPrincipalName = "onboarding@contoso.onmicrosoft.com",
    [string] $DefaultEnvironmentName = "contoso-dev",
    [string] $DefaultTargetTenantDomain = "contoso.onmicrosoft.com",
    [string] $DefaultMspTenantDomain = "msp.example.com",
    [string] $DefaultLicenseAssignmentMode = "DynamicGroup",
    [switch] $WriteTfvars
)

$ErrorActionPreference = "Stop"

function Assert-Command {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        return
    }

    $knownAzureCliPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin"
    if ($Name -eq "az" -and (Test-Path -LiteralPath (Join-Path $knownAzureCliPath "az.cmd"))) {
        $env:Path = "$knownAzureCliPath;$env:Path"
        return
    }

    throw "Required command '$Name' was not found on PATH."
}

function Select-ItemFromList {
    param(
        [Parameter(Mandatory)]
        [string] $Prompt,

        [Parameter(Mandatory)]
        [array] $Items,

        [Parameter(Mandatory)]
        [scriptblock] $Display
    )

    if ($Items.Count -eq 0) {
        throw "No items available for selection: $Prompt"
    }

    Write-Host ""
    Write-Host $Prompt

    for ($index = 0; $index -lt $Items.Count; $index++) {
        $number = $index + 1
        Write-Host "$number. $(& $Display $Items[$index])"
    }

    do {
        $selection = Read-Host "Select option number"
        $isNumber = [int]::TryParse($selection, [ref] $selectedNumber)
        $isValid = $isNumber -and $selectedNumber -ge 1 -and $selectedNumber -le $Items.Count

        if (-not $isValid) {
            Write-Host "Enter a number between 1 and $($Items.Count)."
        }
    } until ($isValid)

    return $Items[$selectedNumber - 1]
}

function New-TokenSigningKey {
    $bytes = [byte[]]::new(32)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    return [Convert]::ToBase64String($bytes)
}

function Read-ValueOrDefault {
    param(
        [Parameter(Mandatory)]
        [string] $Prompt,

        [Parameter(Mandatory)]
        [string] $Default
    )

    $value = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value.Trim()
}

Assert-Command -Name "az"

if (-not (Test-Path -LiteralPath $TerraformPath)) {
    throw "Terraform executable was not found at '$TerraformPath'."
}

Write-Host "This script performs discovery only. It does not create Azure or Entra resources."
Write-Host ""

$deploymentAccountUpn = Read-ValueOrDefault `
    -Prompt "Target tenant deployment account UPN (GA or privileged deployment account)" `
    -Default $DefaultDeploymentAccountUpn

$deploymentPaths = @(
    [pscustomobject]@{
        Name = "Bootstrap app registration and deploy runtime"
        Key = "BootstrapAndRuntime"
    },
    [pscustomobject]@{
        Name = "Use manually configured app registration and deploy runtime"
        Key = "ManualAppRegistrationAndRuntime"
    },
    [pscustomobject]@{
        Name = "Bootstrap app registration only"
        Key = "BootstrapOnly"
    },
    [pscustomobject]@{
        Name = "Deploy runtime only from existing app registration values"
        Key = "RuntimeOnly"
    }
)

$deploymentPath = Select-ItemFromList `
    -Prompt "Select deployment path" `
    -Items $deploymentPaths `
    -Display { param($item) $item.Name }

Write-Host ""
Write-Host "Sign in as $deploymentAccountUpn when prompted."
az login --allow-no-subscriptions | Out-Null

$tenants = az account tenant list --output json | ConvertFrom-Json
$tenant = Select-ItemFromList `
    -Prompt "Select the target/client tenant" `
    -Items $tenants `
    -Display { param($item) "$($item.displayName) - $($item.tenantId)" }

$subscriptions = az account list --all --output json `
    | ConvertFrom-Json `
    | Where-Object { $_.tenantId -eq $tenant.tenantId }

$subscription = Select-ItemFromList `
    -Prompt "Select the Azure subscription for the runtime deployment" `
    -Items $subscriptions `
    -Display { param($item) "$($item.name) - $($item.id)" }

az account set --subscription $subscription.id | Out-Null

$approvalRecipientEmail = Read-ValueOrDefault `
    -Prompt "MSP approval recipient email" `
    -Default $DefaultApprovalRecipientEmail

$approvalSenderUserPrincipalName = Read-ValueOrDefault `
    -Prompt "Target tenant approval sender UPN" `
    -Default $DefaultApprovalSenderUserPrincipalName

$environmentName = Read-ValueOrDefault `
    -Prompt "Short environment name used in Azure resource names" `
    -Default $DefaultEnvironmentName

$targetTenantDomain = Read-ValueOrDefault `
    -Prompt "Target tenant default user domain" `
    -Default $DefaultTargetTenantDomain

$mspTenantDomain = Read-ValueOrDefault `
    -Prompt "MSP tenant domain for tags/docs" `
    -Default $DefaultMspTenantDomain

$licenseModes = @(
    $DefaultLicenseAssignmentMode,
    "DynamicGroup",
    "None",
    "StaticGroup"
) | Select-Object -Unique

$selectedLicenseMode = Select-ItemFromList `
    -Prompt "Select license assignment mode" `
    -Items $licenseModes `
    -Display { param($item) $item }

$secretSourceModes = @(
    "Use bootstrap Key Vault secret ID",
    "Provide raw secret value at terraform plan/apply"
)

$selectedSecretSourceMode = Select-ItemFromList `
    -Prompt "Select Graph client secret handoff mode" `
    -Items $secretSourceModes `
    -Display { param($item) $item }

$licenseGroupId = ""
if ($selectedLicenseMode -eq "StaticGroup") {
    $licenseGroupId = Read-Host "Static license group object ID"
}

$approvalTokenSigningKey = New-TokenSigningKey

$tfvars = @"
environment_name = "$environmentName"
target_tenant_domain = "$targetTenantDomain"
msp_tenant_domain = "$mspTenantDomain"

graph_tenant_id = "$($tenant.tenantId)"
graph_client_id = "REPLACE_WITH_BOOTSTRAP_APPLICATION_CLIENT_ID"
"@

if ($selectedSecretSourceMode -eq "Use bootstrap Key Vault secret ID") {
    $tfvars += @"

graph_client_secret_key_vault_secret_id = "REPLACE_WITH_BOOTSTRAP_KEY_VAULT_SECRET_ID"
"@
}
else {
    $tfvars += @"

graph_client_secret_value = "REPLACE_WITH_GRAPH_CLIENT_SECRET"
"@
}

$tfvars += @"

approval_recipient_email = "$approvalRecipientEmail"
approval_sender_user_principal_name = "$approvalSenderUserPrincipalName"
approval_token_signing_key = "$approvalTokenSigningKey"

license_assignment_mode = "$selectedLicenseMode"
license_group_id = "$licenseGroupId"
"@

Write-Host ""
Write-Host "Discovery summary"
Write-Host "Tenant:       $($tenant.displayName) ($($tenant.tenantId))"
Write-Host "Subscription: $($subscription.name) ($($subscription.id))"
Write-Host "Account:      $deploymentAccountUpn"
Write-Host "Path:         $($deploymentPath.Name)"
Write-Host "Environment:  $environmentName"
Write-Host "Target domain:$targetTenantDomain"
Write-Host "MSP domain:   $mspTenantDomain"
Write-Host "Sender UPN:   $approvalSenderUserPrincipalName"
Write-Host "Approver:     $approvalRecipientEmail"
Write-Host "License mode: $selectedLicenseMode"
Write-Host "Secret mode:  $selectedSecretSourceMode"

Write-Host ""
Write-Host "Suggested terraform.tfvars content"
Write-Host "----------------------------------"
Write-Host $tfvars

if ($WriteTfvars) {
    $tfvarsPath = Join-Path $PSScriptRoot "terraform.tfvars"
    Set-Content -LiteralPath $tfvarsPath -Value $tfvars -NoNewline
    Write-Host ""
    Write-Host "Wrote local tfvars file: $tfvarsPath"
}
else {
    Write-Host ""
    Write-Host "Run with -WriteTfvars to write terraform.tfvars locally."
}
