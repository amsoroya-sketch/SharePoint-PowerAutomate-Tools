<#
.SYNOPSIS
    Opens the Recursive Permission Scanner flow for testing.

.DESCRIPTION
    This script opens the Power Automate portal to the flow and provides test parameters.

.EXAMPLE
    .\Test-RecursiveScanner.ps1
#>

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "|     Recursive Permission Scanner - Test Guide                 |" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Get flow info
Write-Host "Getting flow information..." -ForegroundColor Yellow
$flowResult = pac org fetch --xml "<fetch><entity name='workflow'><attribute name='name'/><attribute name='workflowid'/><attribute name='statecode'/><filter><condition attribute='name' operator='like' value='%Recursive Permission Scanner%'/></filter></entity></fetch>" 2>&1

Write-Host $flowResult -ForegroundColor Gray
Write-Host ""

# Extract flow ID
$flowGuid = $null
if ($flowResult -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
    $flowGuid = $matches[1]
}

Write-Host "Flow Status:" -ForegroundColor Green
Write-Host "  Name: Recursive Permission Scanner" -ForegroundColor White
Write-Host "  ID: $flowGuid" -ForegroundColor White
Write-Host "  Status: Activated" -ForegroundColor White
Write-Host ""

Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "MANUAL TEST INSTRUCTIONS" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open Power Automate:" -ForegroundColor Cyan
Write-Host "   https://make.powerautomate.com" -ForegroundColor White
Write-Host ""
Write-Host "2. Navigate to:" -ForegroundColor Cyan
Write-Host "   Solutions > Recursive Permission Scanner" -ForegroundColor White
Write-Host "   OR search for 'Recursive Permission Scanner' in My Flows" -ForegroundColor White
Write-Host ""
Write-Host "3. Click 'Test' > 'Manually' > 'Test'" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Enter these test parameters:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   +-----------------+-----------------------------------------------------+" -ForegroundColor Gray
Write-Host "   | Parameter       | Value                                               |" -ForegroundColor Gray
Write-Host "   +-----------------+-----------------------------------------------------+" -ForegroundColor Gray
Write-Host "   | SiteURL         | https://abctest179.sharepoint.com/sites/Permission-Scanner-Test" -ForegroundColor Green
Write-Host "   | LibraryName     | Documents                                           |" -ForegroundColor Green
Write-Host "   | BaseLibraryPath | /sites/Permission-Scanner-Test/Shared Documents     |" -ForegroundColor Green
Write-Host "   | MinimumLevel    | -1                                                  |" -ForegroundColor Green
Write-Host "   | DryRun          | true                                                |" -ForegroundColor Green
Write-Host "   +-----------------+-----------------------------------------------------+" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Expected Results:" -ForegroundColor Cyan
Write-Host "   - Total Folders Scanned: ~13 (all folders under Shared Documents)" -ForegroundColor White
Write-Host "   - Folders with Broken Permissions: 5" -ForegroundColor Red
Write-Host ""
Write-Host "   Folders that SHOULD be detected:" -ForegroundColor Yellow
Write-Host "   1. HR/Policies" -ForegroundColor Red
Write-Host "   2. Projects/Project-Beta" -ForegroundColor Red
Write-Host "   3. TestFolder1" -ForegroundColor Red
Write-Host "   4. TestFolder2/SubFolder2a" -ForegroundColor Red
Write-Host "   5. (check for any nested folders)" -ForegroundColor Red
Write-Host ""
Write-Host "6. Review Run History:" -ForegroundColor Cyan
Write-Host "   - Click on DEBUG_AllFoldersFound to see total folders" -ForegroundColor White
Write-Host "   - Click on DEBUG_BrokenPermission (inside loop) to see each folder found" -ForegroundColor White
Write-Host "   - Click on DEBUG_Summary to see final results" -ForegroundColor White
Write-Host ""

# Try to open browser
$flowUrl = "https://make.powerautomate.com"
Write-Host "Opening Power Automate portal..." -ForegroundColor Yellow
try {
    Start-Process $flowUrl
    Write-Host "  [OK] Browser opened" -ForegroundColor Green
}
catch {
    Write-Host "  [INFO] Please open this URL manually: $flowUrl" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "After testing, the flow will show:" -ForegroundColor Green
Write-Host "  - Total folders scanned in the library" -ForegroundColor White
Write-Host "  - Array of folders with broken permissions" -ForegroundColor White
Write-Host "  - For each broken folder: name, path, and level" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
