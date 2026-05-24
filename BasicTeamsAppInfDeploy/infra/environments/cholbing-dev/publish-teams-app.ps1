param(
    [string] $TenantId = "",
    [string] $TeamsAppPath = "..\..\..\teams-app",
    [string] $PackagePath = "",
    [string] $AssignmentGroupId = "",
    [string] $AssignmentGroupDisplayName = "M365 Onboarding Teams App Users",
    [string] $TargetUserPrincipalName = "",
    [string] $AppSetupPolicyName = "M365OnboardingSetup",
    [switch] $SkipPolicyAssignment
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

function Import-MicrosoftTeamsModule {
    $installedModule = Get-Module MicrosoftTeams -ListAvailable |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($installedModule) {
        Import-Module $installedModule.Path -Force
        return
    }

    if (-not (Get-Command "Save-Module" -ErrorAction SilentlyContinue)) {
        throw "MicrosoftTeams module is not installed and Save-Module is not available."
    }

    $moduleRoot = Join-Path ([System.IO.Path]::GetTempPath()) "m365-onboarding-modules"
    New-Item -ItemType Directory -Path $moduleRoot -Force | Out-Null
    Save-Module MicrosoftTeams -Path $moduleRoot -Force

    $savedModule = Get-ChildItem -Path $moduleRoot -Recurse -Filter MicrosoftTeams.psd1 |
        Sort-Object FullName -Descending |
        Select-Object -First 1

    if (-not $savedModule) {
        throw "MicrosoftTeams module could not be loaded."
    }

    Import-Module $savedModule.FullName -Force
}

function ConvertTo-ODataStringLiteral {
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    return $Value.Replace("'", "''")
}

Assert-Command -Name "az"
Import-MicrosoftTeamsModule

if ([string]::IsNullOrWhiteSpace($TenantId)) {
    $TenantId = az account show --query tenantId --output tsv
}

if ([string]::IsNullOrWhiteSpace($TenantId)) {
    throw "TenantId is required. Sign in with Azure CLI or pass -TenantId."
}

if (-not (Test-Path -LiteralPath $TeamsAppPath)) {
    throw "Teams app path was not found at '$TeamsAppPath'."
}

$teamsAppFullPath = Resolve-Path -LiteralPath $TeamsAppPath
$generatedDirectory = Join-Path $teamsAppFullPath "manifest\.generated"
$manifestPath = Join-Path $generatedDirectory "manifest.json"

if ([string]::IsNullOrWhiteSpace($PackagePath)) {
    $PackagePath = Join-Path $generatedDirectory "m365-onboarding-teams-app.zip"
}

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Generated Teams manifest was not found at '$manifestPath'. Run new-teams-manifest.ps1 first."
}

if (-not (Test-Path -LiteralPath $PackagePath)) {
    throw "Teams app package was not found at '$PackagePath'. Run new-teams-package.ps1 first."
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$externalId = $manifest.id
if ([string]::IsNullOrWhiteSpace($externalId)) {
    throw "Generated Teams manifest does not contain an app id."
}

if (-not [string]::IsNullOrWhiteSpace($TargetUserPrincipalName)) {
    & (Join-Path $PSScriptRoot "ensure-teams-app-group.ps1") `
        -GroupDisplayName $AssignmentGroupDisplayName `
        -TargetUserPrincipalName $TargetUserPrincipalName
}

if ([string]::IsNullOrWhiteSpace($AssignmentGroupId)) {
    $escapedGroupDisplayName = ConvertTo-ODataStringLiteral -Value $AssignmentGroupDisplayName
    $groupFilter = "displayName eq '$escapedGroupDisplayName'"
    $group = az ad group list --filter $groupFilter --query "[0]" --output json | ConvertFrom-Json

    if ($group) {
        $AssignmentGroupId = $group.id
    }
}

Write-Host "Connecting to Microsoft Teams tenant '$TenantId'."
Connect-MicrosoftTeams -TenantId $TenantId -UseDeviceAuthentication | Out-Host

$teamsApp = Get-TeamsApp -ExternalId $externalId -DistributionMethod organization -ErrorAction SilentlyContinue
if ($teamsApp) {
    Write-Host "Teams app already exists: $($teamsApp.DisplayName) ($($teamsApp.Id))."
}
else {
    try {
        New-TeamsApp -Path (Resolve-Path -LiteralPath $PackagePath) -DistributionMethod organization -ErrorAction Stop | Out-Null
        $teamsApp = Get-TeamsApp -ExternalId $externalId -DistributionMethod organization
        Write-Host "Uploaded Teams app: $($teamsApp.DisplayName) ($($teamsApp.Id))."
    }
    catch {
        if ($_.Exception.Message -match "same id already exists") {
            $teamsApp = Get-TeamsApp -ExternalId $externalId -DistributionMethod organization
            Write-Host "Teams app already exists: $($teamsApp.DisplayName) ($($teamsApp.Id))."
        }
        else {
            throw
        }
    }
}

if ($SkipPolicyAssignment) {
    Write-Host "Skipped Teams setup policy assignment."
    return
}

if ([string]::IsNullOrWhiteSpace($AssignmentGroupId)) {
    throw "AssignmentGroupId could not be resolved. Pass -AssignmentGroupId or create '$AssignmentGroupDisplayName'."
}

$existingPolicy = Get-CsTeamsAppSetupPolicy -Identity $AppSetupPolicyName -ErrorAction SilentlyContinue
if ($existingPolicy) {
    Write-Host "Teams setup policy already exists: $AppSetupPolicyName."
}
else {
    $pinnedApp = New-Object "Microsoft.Teams.Policy.Administration.Cmdlets.Core.PinnedApp"
    $pinnedApp.Id = $teamsApp.Id
    $pinnedApp.Order = 1

    New-CsTeamsAppSetupPolicy `
        -Identity $AppSetupPolicyName `
        -AllowUserPinning $true `
        -PinnedAppBarApps @($pinnedApp) | Out-Null

    Write-Host "Created Teams setup policy: $AppSetupPolicyName."
}

Grant-CsTeamsAppSetupPolicy `
    -Group $AssignmentGroupId `
    -PolicyName $AppSetupPolicyName `
    -Rank 1

Write-Host "Assigned Teams setup policy '$AppSetupPolicyName' to group '$AssignmentGroupId'."
