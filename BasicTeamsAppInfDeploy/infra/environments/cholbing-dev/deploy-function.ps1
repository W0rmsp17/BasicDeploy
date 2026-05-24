param(
    [string] $TerraformPath = "..\..\..\..\terraform.exe",
    [string] $ProjectPath = "..\..\..\BasicTeamsAppInfDeploy\BasicTeamsAppInfDeploy.csproj",
    [string] $Configuration = "Release",
    [switch] $SkipPostDeploy
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

if (-not (Test-Path -LiteralPath $ProjectPath)) {
    throw "Function project was not found at '$ProjectPath'."
}

$functionAppName = & $TerraformPath output -raw function_app_name
$resourceGroupName = & $TerraformPath output -raw resource_group_name

if ([string]::IsNullOrWhiteSpace($functionAppName)) {
    throw "Terraform output 'function_app_name' was empty."
}

if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    throw "Terraform output 'resource_group_name' was empty."
}

$publishRoot = Join-Path $PSScriptRoot ".publish"
$publishOutput = Join-Path $publishRoot "function"
$packagePath = Join-Path $publishRoot "function.zip"

if (Test-Path -LiteralPath $publishRoot) {
    Remove-Item -LiteralPath $publishRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $publishOutput -Force | Out-Null

dotnet publish $ProjectPath `
    --configuration $Configuration `
    --output $publishOutput

if (Test-Path -LiteralPath $packagePath) {
    Remove-Item -LiteralPath $packagePath -Force
}

Compress-Archive -Path (Join-Path $publishOutput "*") -DestinationPath $packagePath -Force

az functionapp deployment source config-zip `
    --resource-group $resourceGroupName `
    --name $functionAppName `
    --src $packagePath `
    --output none

Write-Host "Deployed package to Function App '$functionAppName'."

if (-not $SkipPostDeploy) {
    & (Join-Path $PSScriptRoot "post-deploy.ps1") -TerraformPath $TerraformPath
}
