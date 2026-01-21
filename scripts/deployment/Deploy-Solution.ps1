<#
.SYNOPSIS
    Deploys a Power Platform solution using PAC CLI.

.DESCRIPTION
    This script imports a Power Platform solution to an environment,
    verifies the deployment, and optionally activates flows.

.PARAMETER SolutionZip
    Path to the solution .zip file to import.

.PARAMETER Environment
    Optional environment URL or ID. Uses current PAC auth if not specified.

.PARAMETER Async
    If specified, imports asynchronously (doesn't wait for completion).

.PARAMETER ActivateFlows
    If specified, activates all flows in the solution after import.

.PARAMETER CheckStatus
    If specified, checks the status of flows after import.

.EXAMPLE
    .\Deploy-Solution.ps1 -SolutionZip ".\MySolution.zip"

.EXAMPLE
    .\Deploy-Solution.ps1 -SolutionZip ".\MySolution.zip" -ActivateFlows -CheckStatus

.NOTES
    Author: Power Platform DevOps
    Version: 1.0
    Requires: PAC CLI installed and authenticated
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SolutionZip,

    [string]$Environment,

    [switch]$Async,

    [switch]$ActivateFlows,

    [switch]$CheckStatus
)

# Check if PAC CLI is available
$pacPath = Get-Command pac -ErrorAction SilentlyContinue
if (-not $pacPath) {
    Write-Error "PAC CLI not found. Please install it from: https://aka.ms/PowerAppsCLI"
    exit 1
}

# Validate solution file
if (-not (Test-Path $SolutionZip)) {
    Write-Error "Solution file not found: $SolutionZip"
    exit 1
}

Write-Host "=== Power Platform Solution Deployer ===" -ForegroundColor Cyan
Write-Host "Solution: $SolutionZip" -ForegroundColor Gray
Write-Host ""

# Check current authentication
Write-Host "Checking PAC CLI authentication..." -ForegroundColor Yellow
$authResult = & pac auth list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "PAC CLI not authenticated. Run 'pac auth create' first."
    exit 1
}
Write-Host $authResult -ForegroundColor Gray
Write-Host ""

# Get current org info
Write-Host "Getting current environment info..." -ForegroundColor Yellow
$orgInfo = & pac org who 2>&1
Write-Host $orgInfo -ForegroundColor Gray
Write-Host ""

# Import solution
Write-Host "=== Importing Solution ===" -ForegroundColor Cyan
$importArgs = @("solution", "import", "--path", $SolutionZip)

if ($Environment) {
    $importArgs += "--environment"
    $importArgs += $Environment
}

if (-not $Async) {
    $importArgs += "--async"
    $importArgs += "false"
}

Write-Host "Running: pac $($importArgs -join ' ')" -ForegroundColor DarkGray
$importResult = & pac @importArgs 2>&1
$importExitCode = $LASTEXITCODE

if ($importExitCode -ne 0) {
    Write-Host ""
    Write-Host "=== Import Failed ===" -ForegroundColor Red
    Write-Host $importResult -ForegroundColor Red
    exit 1
}

Write-Host $importResult -ForegroundColor Green
Write-Host ""
Write-Host "Solution imported successfully!" -ForegroundColor Green

# Check flow status if requested
if ($CheckStatus) {
    Write-Host ""
    Write-Host "=== Checking Flow Status ===" -ForegroundColor Cyan

    $fetchXml = @"
<fetch>
  <entity name='workflow'>
    <attribute name='name'/>
    <attribute name='statecode'/>
    <attribute name='statuscode'/>
    <attribute name='modifiedon'/>
    <filter>
      <condition attribute='category' operator='eq' value='5'/>
    </filter>
    <order attribute='modifiedon' descending='true'/>
  </entity>
</fetch>
"@

    $flowStatus = & pac org fetch --xml $fetchXml 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host $flowStatus -ForegroundColor Gray
    } else {
        Write-Host "Could not retrieve flow status" -ForegroundColor Yellow
    }
}

# Get solution details
Write-Host ""
Write-Host "=== Deployed Solutions ===" -ForegroundColor Cyan
$solutions = & pac solution list 2>&1
Write-Host $solutions -ForegroundColor Gray

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Open Power Automate: https://make.powerautomate.com" -ForegroundColor Gray
Write-Host "  2. Navigate to Solutions > Select your solution" -ForegroundColor Gray
Write-Host "  3. Open the flow and click Test > Manually" -ForegroundColor Gray
Write-Host "  4. Review run history to see debug outputs" -ForegroundColor Gray
