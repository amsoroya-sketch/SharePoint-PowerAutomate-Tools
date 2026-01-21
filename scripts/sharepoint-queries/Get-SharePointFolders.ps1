<#
.SYNOPSIS
    Query SharePoint for folders with broken permissions.

.DESCRIPTION
    Uses SharePoint REST API to find folders with unique permissions (broken inheritance).

.PARAMETER SiteURL
    SharePoint site URL

.PARAMETER LibraryName
    Document library name

.PARAMETER BasePath
    Base path to filter folders

.PARAMETER ListOnly
    Just list all folders without filtering for broken permissions

.EXAMPLE
    .\Get-SharePointFolders.ps1 -SiteURL "https://tenant.sharepoint.com/sites/test" -LibraryName "Shared Documents"
#>

param(
    [string]$SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test",
    [string]$LibraryName = "Shared Documents",
    [string]$BasePath = "/sites/Permission-Scanner-Test/Shared Documents",
    [switch]$ListOnly,
    [switch]$ShowStructure
)

# Load environment variables
$envFile = "Z:\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^([^#=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

$tenantId = $env:SHAREPOINT_TENANT_ID
$clientId = $env:SHAREPOINT_CLIENT_ID
$clientSecret = $env:SHAREPOINT_CLIENT_SECRET

Write-Host "=== SharePoint Folder Scanner ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Site: $SiteURL" -ForegroundColor White
Write-Host "Library: $LibraryName" -ForegroundColor White
Write-Host "Base Path: $BasePath" -ForegroundColor White
Write-Host ""

# Get Access Token using SharePoint resource
Write-Host "Authenticating to SharePoint..." -ForegroundColor Yellow

$sharePointHost = ([System.Uri]$SiteURL).Host

try {
    # Use Azure AD v2 endpoint with SharePoint resource
    $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $tokenBody = @{
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://$sharePointHost/.default"
        grant_type    = "client_credentials"
    }

    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "  [OK] Authenticated to SharePoint" -ForegroundColor Green
}
catch {
    Write-Host "  [WARNING] v2 endpoint failed, trying v1..." -ForegroundColor Yellow

    # Try Azure AD v1 endpoint
    try {
        $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
        $tokenBody = @{
            client_id     = $clientId
            client_secret = $clientSecret
            resource      = "https://$sharePointHost"
            grant_type    = "client_credentials"
        }

        $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
        $accessToken = $tokenResponse.access_token
        Write-Host "  [OK] Authenticated via v1 endpoint" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] Authentication failed" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual Test Instructions:" -ForegroundColor Yellow
        Write-Host "  1. Open Power Automate and run the flow manually"
        Write-Host "  2. Or use the SharePoint UI to check folder permissions"
        Write-Host ""
        Write-Host "App Registration Requirements:" -ForegroundColor Cyan
        Write-Host "  - API Permissions: SharePoint > Sites.Read.All (Application)"
        Write-Host "  - Admin consent granted"
        exit 1
    }
}

Write-Host ""

# Build query
if ($ListOnly) {
    $filter = "FileSystemObjectType eq 1"
    Write-Host "Querying all folders..." -ForegroundColor Yellow
} else {
    $filter = "HasUniqueRoleAssignments eq true and FileSystemObjectType eq 1 and startswith(FileRef,'$BasePath')"
    Write-Host "Querying folders with broken permissions..." -ForegroundColor Yellow
}

$select = "Id,Title,FileLeafRef,FileRef,FileDirRef,HasUniqueRoleAssignments,ItemChildCount,FolderChildCount"
$apiUrl = "$SiteURL/_api/web/lists/getbytitle('$LibraryName')/items?`$select=$select&`$filter=$filter"

Write-Host "  API URL: $apiUrl" -ForegroundColor Gray
Write-Host ""

try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Accept"        = "application/json;odata=verbose"
    }

    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method GET
    $folders = $response.d.results

    if ($folders.Count -eq 0) {
        Write-Host "No folders found matching criteria." -ForegroundColor Yellow
        Write-Host ""
        if (-not $ListOnly) {
            Write-Host "This could mean:" -ForegroundColor White
            Write-Host "  - No folders have broken permissions"
            Write-Host "  - The base path doesn't exist"
            Write-Host "  - Permission to read the library"
            Write-Host ""
            Write-Host "Try running with -ListOnly to see all folders:" -ForegroundColor Cyan
            Write-Host "  .\Get-SharePointFolders.ps1 -ListOnly"
        }
    } else {
        Write-Host "Found $($folders.Count) folder(s):" -ForegroundColor Green
        Write-Host ""

        $folders | ForEach-Object {
            $level = ($_.FileRef.Split('/').Count) - ($BasePath.Split('/').Count)

            Write-Host "  Folder: $($_.FileLeafRef)" -ForegroundColor White
            Write-Host "    Path: $($_.FileRef)" -ForegroundColor Gray
            Write-Host "    Level: $level" -ForegroundColor Gray
            Write-Host "    Broken Permissions: $($_.HasUniqueRoleAssignments)" -ForegroundColor $(if ($_.HasUniqueRoleAssignments) { "Red" } else { "Green" })
            Write-Host "    Files: $($_.ItemChildCount) | Subfolders: $($_.FolderChildCount)" -ForegroundColor Gray
            Write-Host ""
        }

        # Summary
        Write-Host "Summary:" -ForegroundColor Yellow
        Write-Host "  Total Folders: $($folders.Count)"
        $brokenCount = ($folders | Where-Object { $_.HasUniqueRoleAssignments -eq $true }).Count
        Write-Host "  With Broken Permissions: $brokenCount" -ForegroundColor $(if ($brokenCount -gt 0) { "Red" } else { "Green" })
    }
}
catch {
    Write-Host "[ERROR] API call failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
