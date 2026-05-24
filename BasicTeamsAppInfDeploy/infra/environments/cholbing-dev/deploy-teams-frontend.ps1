param(
    [string] $TerraformPath = "..\..\..\..\terraform.exe",
    [string] $TeamsAppPath = "..\..\..\teams-app",
    [switch] $SkipBuild
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    $knownAzureCliPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path -LiteralPath (Join-Path $knownAzureCliPath "az.cmd")) {
        $env:Path = "$knownAzureCliPath;$env:Path"
    }
}

if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    throw "Required command 'az' was not found on PATH."
}

if (-not (Test-Path -LiteralPath $TerraformPath)) {
    throw "Terraform executable was not found at '$TerraformPath'."
}

if (-not (Test-Path -LiteralPath $TeamsAppPath)) {
    throw "Teams app path was not found at '$TeamsAppPath'."
}

$staticWebAppName = & $TerraformPath output -raw static_web_app_name
$staticWebAppUrl = & $TerraformPath output -raw static_web_app_url
$resourceGroupName = & $TerraformPath output -raw resource_group_name
$functionAppHostname = & $TerraformPath output -raw function_app_default_hostname

if ([string]::IsNullOrWhiteSpace($staticWebAppName)) {
    throw "Terraform output 'static_web_app_name' was empty."
}

if ([string]::IsNullOrWhiteSpace($staticWebAppUrl)) {
    throw "Terraform output 'static_web_app_url' was empty."
}

if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    throw "Terraform output 'resource_group_name' was empty."
}

if ([string]::IsNullOrWhiteSpace($functionAppHostname)) {
    throw "Terraform output 'function_app_default_hostname' was empty."
}

$teamsAppFullPath = Resolve-Path -LiteralPath $TeamsAppPath
$functionBaseUrl = "https://$functionAppHostname"

if (-not $SkipBuild) {
    Push-Location $teamsAppFullPath
    try {
        $env:VITE_API_BASE_URL = $functionBaseUrl
        npm run build
    }
    finally {
        Pop-Location
        Remove-Item Env:\VITE_API_BASE_URL -ErrorAction SilentlyContinue
    }
}

$deploymentToken = az staticwebapp secrets list `
    --name $staticWebAppName `
    --resource-group $resourceGroupName `
    --query "properties.apiKey" `
    --output tsv

if ([string]::IsNullOrWhiteSpace($deploymentToken)) {
    throw "Could not retrieve Static Web Apps deployment token."
}

Push-Location $teamsAppFullPath
try {
    npx swa deploy ".\dist" `
        --deployment-token $deploymentToken `
        --env production `
        --verbose silly
}
finally {
    Pop-Location
}

Write-Host "Deployed Teams frontend to $staticWebAppUrl"
Write-Host "Function API base URL baked into bundle: $functionBaseUrl"
