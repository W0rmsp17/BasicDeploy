param(
    [string] $EnvironmentName = "cholbing-dev",
    [string] $EnvironmentPath = "",
    [string] $TerraformPath = "",
    [string] $ApprovalProvider = "Graph",
    [string] $TeamsAppUserPrincipalName = "",
    [string] $RepositoryUrl = "",
    [string] $CheckoutPath = "",
    [switch] $WriteTfvars,
    [switch] $SkipDiscovery,
    [switch] $SkipTerraformApply,
    [switch] $SkipFunctionDeploy,
    [switch] $SkipTeamsFrontendDeploy,
    [switch] $SkipTeamsManifest,
    [switch] $SkipTeamsAppGroup,
    [switch] $RunGraphReadiness,
    [switch] $AutoApprove
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

function Resolve-TerraformPath {
    param(
        [string] $RequestedPath
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        if (-not (Test-Path -LiteralPath $RequestedPath)) {
            throw "Terraform executable was not found at '$RequestedPath'."
        }

        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    $repoLocalTerraform = Join-Path $PSScriptRoot "..\terraform.exe"
    if (Test-Path -LiteralPath $repoLocalTerraform) {
        return (Resolve-Path -LiteralPath $repoLocalTerraform).Path
    }

    $terraformCommand = Get-Command "terraform" -ErrorAction SilentlyContinue
    if ($terraformCommand) {
        return $terraformCommand.Source
    }

    throw "Terraform was not found. Install Terraform or pass -TerraformPath."
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)]
        [scriptblock] $Command
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE."
    }
}

if (-not [string]::IsNullOrWhiteSpace($RepositoryUrl)) {
    Assert-Command -Name "git"

    if ([string]::IsNullOrWhiteSpace($CheckoutPath)) {
        throw "CheckoutPath is required when RepositoryUrl is supplied."
    }

    if (Test-Path -LiteralPath $CheckoutPath) {
        Write-Host "Updating source checkout at '$CheckoutPath'."
        Invoke-Checked { git -C $CheckoutPath pull --ff-only }
    }
    else {
        Write-Host "Cloning source repository to '$CheckoutPath'."
        Invoke-Checked { git clone $RepositoryUrl $CheckoutPath }
    }

    $checkedOutDeployScript = Join-Path $CheckoutPath "BasicTeamsAppInfDeploy\deploy.ps1"
    if (-not (Test-Path -LiteralPath $checkedOutDeployScript)) {
        throw "Deploy script was not found after checkout: $checkedOutDeployScript"
    }

    $forwardedArgs = @(
        "-EnvironmentName", $EnvironmentName,
        "-ApprovalProvider", $ApprovalProvider
    )

    if (-not [string]::IsNullOrWhiteSpace($TeamsAppUserPrincipalName)) {
        $forwardedArgs += @("-TeamsAppUserPrincipalName", $TeamsAppUserPrincipalName)
    }

    if (-not [string]::IsNullOrWhiteSpace($TerraformPath)) {
        $forwardedArgs += @("-TerraformPath", $TerraformPath)
    }

    foreach ($switchName in @(
        "WriteTfvars",
        "SkipDiscovery",
        "SkipTerraformApply",
        "SkipFunctionDeploy",
        "SkipTeamsFrontendDeploy",
        "SkipTeamsManifest",
        "SkipTeamsAppGroup",
        "RunGraphReadiness",
        "AutoApprove"
    )) {
        if ((Get-Variable -Name $switchName).Value) {
            $forwardedArgs += "-$switchName"
        }
    }

    & $checkedOutDeployScript @forwardedArgs
    exit $LASTEXITCODE
}

Assert-Command -Name "az"
Assert-Command -Name "dotnet"
Assert-Command -Name "node"
Assert-Command -Name "npm"

$resolvedTerraformPath = Resolve-TerraformPath -RequestedPath $TerraformPath

if ([string]::IsNullOrWhiteSpace($EnvironmentPath)) {
    $EnvironmentPath = Join-Path $PSScriptRoot "infra\environments\$EnvironmentName"
}

if (-not (Test-Path -LiteralPath $EnvironmentPath)) {
    throw "Environment path was not found: $EnvironmentPath"
}

$resolvedEnvironmentPath = (Resolve-Path -LiteralPath $EnvironmentPath).Path

Write-Host "Deployment source: $PSScriptRoot"
Write-Host "Environment path:  $resolvedEnvironmentPath"
Write-Host "Terraform:         $resolvedTerraformPath"
Write-Host "Approval provider: $ApprovalProvider"

Push-Location $resolvedEnvironmentPath
try {
    if (-not $SkipDiscovery) {
        $discoveryArgs = @("-TerraformPath", $resolvedTerraformPath)
        if ($WriteTfvars) {
            $discoveryArgs += "-WriteTfvars"
        }

        & ".\discover-prereqs.ps1" @discoveryArgs
    }

    Invoke-Checked { & $resolvedTerraformPath init }
    Invoke-Checked { & $resolvedTerraformPath validate }

    $planPath = Join-Path $resolvedEnvironmentPath ".terraform\deploy.tfplan"
    Invoke-Checked { & $resolvedTerraformPath plan -out $planPath -var "approval_provider=$ApprovalProvider" }

    if (-not $SkipTerraformApply) {
        if (-not $AutoApprove) {
            $answer = Read-Host "Apply this Terraform plan? Type yes to continue"
            if ($answer -ne "yes") {
                throw "Deployment stopped before Terraform apply."
            }
        }

        Invoke-Checked { & $resolvedTerraformPath apply $planPath }
    }

    if (-not $SkipFunctionDeploy) {
        & ".\deploy-function.ps1" -TerraformPath $resolvedTerraformPath
    }

    if (-not $SkipTeamsFrontendDeploy) {
        & ".\deploy-teams-frontend.ps1" -TerraformPath $resolvedTerraformPath
    }

    if (-not $SkipTeamsManifest) {
        & ".\new-teams-manifest.ps1" -TerraformPath $resolvedTerraformPath
    }

    if (-not $SkipTeamsAppGroup) {
        $groupArgs = @{}
        if (-not [string]::IsNullOrWhiteSpace($TeamsAppUserPrincipalName)) {
            $groupArgs.TargetUserPrincipalName = $TeamsAppUserPrincipalName
        }

        & ".\ensure-teams-app-group.ps1" @groupArgs
    }

    if ($RunGraphReadiness) {
        & ".\test-graph-app.ps1"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Deployment sequence completed."
