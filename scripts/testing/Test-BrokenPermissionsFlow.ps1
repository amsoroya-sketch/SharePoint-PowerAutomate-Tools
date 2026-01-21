<#
.SYNOPSIS
    Test scenarios for the "Folders with Broken Permissions by Level" flow.

.DESCRIPTION
    This script helps you prepare and execute test scenarios for the Power Automate flow.
    It provides test configurations and can trigger flow runs via Power Automate.

.PARAMETER Scenario
    The test scenario to run: List, TestQuery, RunFlow

.PARAMETER SiteURL
    SharePoint site URL (e.g., https://yourtenant.sharepoint.com/sites/hr)

.PARAMETER LibraryName
    Document library name (e.g., "Shared Documents")

.PARAMETER BaseLibraryPath
    Server-relative path to filter folders (e.g., /sites/hr/Shared Documents)

.PARAMETER MinimumLevel
    Minimum folder level to include (-1 = all levels)

.EXAMPLE
    .\Test-BrokenPermissionsFlow.ps1 -Scenario List
    Lists available test configurations

.EXAMPLE
    .\Test-BrokenPermissionsFlow.ps1 -Scenario TestQuery -SiteURL "https://contoso.sharepoint.com/sites/hr"
    Shows the OData query that will be generated
#>

param(
    [ValidateSet("List", "TestQuery", "ShowFlow", "CreateTestFolders")]
    [string]$Scenario = "List",

    [string]$SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test",
    [string]$LibraryName = "Shared Documents",
    [string]$BaseLibraryPath = "/sites/Permission-Scanner-Test/Shared Documents",
    [string]$MinimumLevel = "-1"
)

Write-Host "=== Broken Permissions Flow Test Tool ===" -ForegroundColor Cyan
Write-Host ""

# Test Scenarios Configuration
$testScenarios = @(
    @{
        Name = "Scenario 1: Scan Entire Library"
        SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test"
        LibraryName = "Shared Documents"
        BaseLibraryPath = "/sites/Permission-Scanner-Test/Shared Documents"
        MinimumLevel = "-1"
        Description = "Scans all folders with broken permissions in the entire library"
    },
    @{
        Name = "Scenario 2: Scan Specific Folder (Projects)"
        SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test"
        LibraryName = "Shared Documents"
        BaseLibraryPath = "/sites/Permission-Scanner-Test/Shared Documents/Projects"
        MinimumLevel = "-1"
        Description = "Scans only folders under /Projects path"
    },
    @{
        Name = "Scenario 3: Root Level Only"
        SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test"
        LibraryName = "Shared Documents"
        BaseLibraryPath = "/sites/Permission-Scanner-Test/Shared Documents"
        MinimumLevel = "0"
        Description = "Scans only root-level folders with broken permissions"
    },
    @{
        Name = "Scenario 4: Up to Level 2"
        SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test"
        LibraryName = "Shared Documents"
        BaseLibraryPath = "/sites/Permission-Scanner-Test/Shared Documents"
        MinimumLevel = "2"
        Description = "Scans folders at levels 0, 1, and 2 only"
    }
)

switch ($Scenario) {
    "List" {
        Write-Host "Available Test Scenarios:" -ForegroundColor Yellow
        Write-Host ""

        foreach ($test in $testScenarios) {
            Write-Host "  $($test.Name)" -ForegroundColor Green
            Write-Host "    Description: $($test.Description)"
            Write-Host "    SiteURL: $($test.SiteURL)"
            Write-Host "    LibraryName: $($test.LibraryName)"
            Write-Host "    BaseLibraryPath: $($test.BaseLibraryPath)"
            Write-Host "    MinimumLevel: $($test.MinimumLevel)"
            Write-Host ""
        }

        Write-Host "To test a query, run:" -ForegroundColor Cyan
        Write-Host "  .\Test-BrokenPermissionsFlow.ps1 -Scenario TestQuery -SiteURL '<url>' -LibraryName '<lib>' -BaseLibraryPath '<path>'"
        Write-Host ""
    }

    "TestQuery" {
        Write-Host "Generated OData Query:" -ForegroundColor Yellow
        Write-Host ""

        # Build the query
        $selectFields = "Id,Title,FileLeafRef,FileRef,FileDirRef,Created,Modified,AuthorId,EditorId,HasUniqueRoleAssignments,FileSystemObjectType,ItemChildCount,FolderChildCount"
        $filter = "HasUniqueRoleAssignments eq true and FileSystemObjectType eq 1 and startswith(FileRef,'$BaseLibraryPath')"

        $fullUri = "_api/web/lists/getbytitle('$LibraryName')/items?`$select=$selectFields&`$filter=$filter"

        Write-Host "  Site URL: $SiteURL" -ForegroundColor White
        Write-Host ""
        Write-Host "  Relative URI:" -ForegroundColor Green
        Write-Host "  $fullUri"
        Write-Host ""
        Write-Host "  Full URL:" -ForegroundColor Green
        Write-Host "  $SiteURL/$fullUri"
        Write-Host ""

        Write-Host "Filter Breakdown:" -ForegroundColor Yellow
        Write-Host "  - HasUniqueRoleAssignments eq true  -> Folders with broken permissions"
        Write-Host "  - FileSystemObjectType eq 1         -> Folders only (not files)"
        Write-Host "  - startswith(FileRef,'$BaseLibraryPath') -> Only under this path"
        Write-Host ""

        Write-Host "Power Automate Expression:" -ForegroundColor Yellow
        Write-Host ""
        $paExpression = "concat('_api/web/lists/getbytitle(''', triggerBody()['text_1'], ''')/items?`$select=$selectFields&`$filter=HasUniqueRoleAssignments eq true and FileSystemObjectType eq 1 and startswith(FileRef,''', triggerBody()['text_2'], ''')')"
        Write-Host $paExpression -ForegroundColor Cyan
        Write-Host ""
    }

    "ShowFlow" {
        Write-Host "Fetching flow details..." -ForegroundColor Yellow
        & "$PSScriptRoot\Get-Flow.ps1" -Name "Broken"
    }

    "CreateTestFolders" {
        Write-Host "Test Folder Creation Guide:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To properly test the flow, create this folder structure in SharePoint:" -ForegroundColor White
        Write-Host ""
        Write-Host "  /Shared Documents" -ForegroundColor Green
        Write-Host "    |-- TestFolder1 (break inheritance here)"
        Write-Host "    |-- TestFolder2"
        Write-Host "    |     |-- SubFolder2a (break inheritance here)"
        Write-Host "    |     |-- SubFolder2b"
        Write-Host "    |-- TestFolder3"
        Write-Host "          |-- Level2"
        Write-Host "                |-- Level3 (break inheritance here)"
        Write-Host ""
        Write-Host "Steps to break inheritance on a folder:" -ForegroundColor Yellow
        Write-Host "  1. Navigate to the folder in SharePoint"
        Write-Host "  2. Click the (i) icon or 'Manage access'"
        Write-Host "  3. Click 'Advanced' at the bottom"
        Write-Host "  4. Click 'Stop Inheriting Permissions'"
        Write-Host "  5. Click 'OK' to confirm"
        Write-Host ""
        Write-Host "After creating test folders, run the flow with:" -ForegroundColor Cyan
        Write-Host "  SiteURL: Your SharePoint site URL"
        Write-Host "  LibraryName: Shared Documents"
        Write-Host "  BaseLibraryPath: /sites/yoursite/Shared Documents"
        Write-Host "  MinimumLevel: -1 (to get all levels)"
        Write-Host ""
    }
}

Write-Host "=== Done ===" -ForegroundColor Green
