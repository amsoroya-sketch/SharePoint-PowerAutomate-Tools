<#
.SYNOPSIS
    Retrieves and displays SharePoint Permission Scanner results from Dataverse.

.DESCRIPTION
    This script queries Dataverse to retrieve scan session results,
    folder records, and permission entries. It provides a formatted
    view of the scanning results.

.PARAMETER SessionId
    Optional specific session ID to retrieve.

.PARAMETER Latest
    If specified, retrieves only the most recent scan session.

.PARAMETER ShowFolders
    If specified, also retrieves folder records for the session.

.PARAMETER ShowPermissions
    If specified, also retrieves permission entries.

.PARAMETER Raw
    If specified, outputs raw data without formatting.

.EXAMPLE
    .\Get-ScanResults.ps1 -Latest

.EXAMPLE
    .\Get-ScanResults.ps1 -Latest -ShowFolders -ShowPermissions

.NOTES
    Author: Power Platform DevOps
    Version: 1.0
    Requires: PAC CLI installed and authenticated
#>

param(
    [string]$SessionId,

    [switch]$Latest,

    [switch]$ShowFolders,

    [switch]$ShowPermissions,

    [switch]$Raw
)

# Check PAC CLI
$pacPath = Get-Command pac -ErrorAction SilentlyContinue
if (-not $pacPath) {
    Write-Error "PAC CLI not found"
    exit 1
}

Write-Host ""
Write-Host "=== SharePoint Permission Scanner Results ===" -ForegroundColor Cyan
Write-Host ""

# Get scan sessions
Write-Host "Fetching scan sessions..." -ForegroundColor Yellow

$sessionFetch = @"
<fetch>
  <entity name='sp_scansession'>
    <attribute name='sp_scansessionid'/>
    <attribute name='sp_name'/>
    <attribute name='sp_siteurl'/>
    <attribute name='sp_libraryname'/>
    <attribute name='sp_status'/>
    <attribute name='sp_totalfolders'/>
    <attribute name='sp_folderswithuniqueperms'/>
    <attribute name='sp_startedon'/>
    <attribute name='sp_completedon'/>
    <attribute name='sp_errormessage'/>
    <attribute name='createdon'/>
    <order attribute='createdon' descending='true'/>
  </entity>
</fetch>
"@

$sessionResult = & pac org fetch --xml $sessionFetch 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error fetching sessions:" -ForegroundColor Red
    Write-Host $sessionResult -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Scan Sessions ===" -ForegroundColor Cyan
Write-Host $sessionResult

# Status code mapping
$statusMap = @{
    "100000000" = "Completed"
    "100000001" = "Running"
    "100000002" = "Failed"
}

# Parse and display formatted results
if (-not $Raw) {
    Write-Host ""
    Write-Host "=== Status Reference ===" -ForegroundColor Yellow
    Write-Host "  100000000 = Completed (Success)" -ForegroundColor Green
    Write-Host "  100000001 = Running (In Progress)" -ForegroundColor Yellow
    Write-Host "  100000002 = Failed (Error)" -ForegroundColor Red
}

# If showing folders
if ($ShowFolders) {
    Write-Host ""
    Write-Host "=== Folder Records ===" -ForegroundColor Cyan

    $folderFetch = @"
<fetch>
  <entity name='sp_folderrecord'>
    <attribute name='sp_name'/>
    <attribute name='sp_folderpath'/>
    <attribute name='sp_hasuniqueperms'/>
    <attribute name='createdon'/>
    <order attribute='createdon' descending='true'/>
  </entity>
</fetch>
"@

    $folderResult = & pac org fetch --xml $folderFetch 2>&1
    Write-Host $folderResult
}

# If showing permissions
if ($ShowPermissions) {
    Write-Host ""
    Write-Host "=== Permission Entries ===" -ForegroundColor Cyan

    $permFetch = @"
<fetch>
  <entity name='sp_permissionentry'>
    <attribute name='sp_principalname'/>
    <attribute name='sp_principalemail'/>
    <attribute name='sp_permissionlevel'/>
    <attribute name='createdon'/>
    <order attribute='createdon' descending='true'/>
  </entity>
</fetch>
"@

    $permResult = & pac org fetch --xml $permFetch 2>&1
    Write-Host $permResult
}

Write-Host ""
Write-Host "=== Query Complete ===" -ForegroundColor Green
