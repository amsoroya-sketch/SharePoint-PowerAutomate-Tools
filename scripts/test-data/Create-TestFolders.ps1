<#
.SYNOPSIS
    Creates test folders with broken permissions in SharePoint for testing the flow.

.DESCRIPTION
    Creates a folder structure and breaks inheritance on specific folders
    to test the "Folders with Broken Permissions by Level" flow.

.PARAMETER SiteURL
    SharePoint site URL

.PARAMETER CleanUp
    Remove all test folders instead of creating them

.EXAMPLE
    .\Create-TestFolders.ps1
    Creates test folder structure with broken permissions

.EXAMPLE
    .\Create-TestFolders.ps1 -CleanUp
    Removes all test folders
#>

param(
    [string]$SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test",
    [string]$LibraryName = "Documents",
    [switch]$CleanUp
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

Write-Host "=== SharePoint Test Folder Creator ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Site: $SiteURL" -ForegroundColor White
Write-Host "Library: $LibraryName" -ForegroundColor White
Write-Host ""

# Parse site info
$siteHost = ([System.Uri]$SiteURL).Host
$sitePath = ([System.Uri]$SiteURL).AbsolutePath

# Get Access Token
Write-Host "Authenticating to Microsoft Graph..." -ForegroundColor Yellow

try {
    $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $tokenBody = @{
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }

    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "  [OK] Authenticated" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Authentication failed: $_" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

Write-Host ""

# Get Site ID
Write-Host "Getting site information..." -ForegroundColor Yellow
try {
    $siteApiUrl = "https://graph.microsoft.com/v1.0/sites/${siteHost}:${sitePath}"
    $siteResponse = Invoke-RestMethod -Uri $siteApiUrl -Headers $headers -Method GET
    $siteId = $siteResponse.id
    Write-Host "  [OK] Site found" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Failed to get site: $_" -ForegroundColor Red
    exit 1
}

# Get Drive ID
Write-Host "Getting document library..." -ForegroundColor Yellow
try {
    $drivesUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/drives"
    $drivesResponse = Invoke-RestMethod -Uri $drivesUrl -Headers $headers -Method GET
    $drive = $drivesResponse.value | Where-Object { $_.name -eq $LibraryName -or $_.name -eq "Shared Documents" -or $_.name -eq "Documents" } | Select-Object -First 1

    if ($drive) {
        $driveId = $drive.id
        Write-Host "  [OK] Drive: $($drive.name)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Library not found" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  [ERROR] Failed to get drives: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Function to create a folder
function New-SharePointFolder {
    param(
        [string]$ParentPath,
        [string]$FolderName
    )

    $createUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/root:/${ParentPath}:/children"
    if ($ParentPath -eq "") {
        $createUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/root/children"
    }

    $body = @{
        name = $FolderName
        folder = @{}
        "@microsoft.graph.conflictBehavior" = "replace"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $createUrl -Headers $headers -Method POST -Body $body
        return $response
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            # Folder exists, get it
            $getUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/root:/${ParentPath}/${FolderName}"
            if ($ParentPath -eq "") {
                $getUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/root:/${FolderName}"
            }
            $response = Invoke-RestMethod -Uri $getUrl -Headers $headers -Method GET
            return $response
        }
        throw $_
    }
}

# Function to break inheritance (add unique permission)
function Set-UniquePermission {
    param(
        [string]$ItemId,
        [string]$FolderName
    )

    # Get current user/app info to add as permission
    # We'll add a "view" link which creates unique permissions
    $permUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$ItemId/createLink"

    $body = @{
        type = "view"
        scope = "organization"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $permUrl -Headers $headers -Method POST -Body $body
        return $true
    }
    catch {
        Write-Host "      [WARNING] Could not create sharing link: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to delete a folder
function Remove-SharePointFolder {
    param(
        [string]$FolderPath
    )

    $deleteUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/root:/${FolderPath}"

    try {
        Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method DELETE
        return $true
    }
    catch {
        return $false
    }
}

if ($CleanUp) {
    # Clean up mode - remove test folders
    Write-Host "Cleaning up test folders..." -ForegroundColor Yellow
    Write-Host ""

    $foldersToDelete = @(
        "TestFolder1",
        "TestFolder2",
        "TestFolder3",
        "HR",
        "Projects"
    )

    foreach ($folder in $foldersToDelete) {
        Write-Host "  Deleting $folder..." -NoNewline
        if (Remove-SharePointFolder -FolderPath $folder) {
            Write-Host " [DELETED]" -ForegroundColor Green
        } else {
            Write-Host " [NOT FOUND]" -ForegroundColor Gray
        }
    }

} else {
    # Create test folder structure
    Write-Host "Creating test folder structure..." -ForegroundColor Yellow
    Write-Host ""

    # Test structure:
    # /TestFolder1 (break inheritance)
    # /TestFolder2
    #   /SubFolder2a (break inheritance)
    #   /SubFolder2b
    # /TestFolder3
    #   /Level2
    #     /Level3 (break inheritance)
    # /HR
    #   /Policies (break inheritance)
    #   /Employees
    # /Projects
    #   /Project-Alpha
    #   /Project-Beta (break inheritance)

    $foldersToCreate = @(
        @{ Path = ""; Name = "TestFolder1"; BreakInheritance = $true },
        @{ Path = ""; Name = "TestFolder2"; BreakInheritance = $false },
        @{ Path = "TestFolder2"; Name = "SubFolder2a"; BreakInheritance = $true },
        @{ Path = "TestFolder2"; Name = "SubFolder2b"; BreakInheritance = $false },
        @{ Path = ""; Name = "TestFolder3"; BreakInheritance = $false },
        @{ Path = "TestFolder3"; Name = "Level2"; BreakInheritance = $false },
        @{ Path = "TestFolder3/Level2"; Name = "Level3"; BreakInheritance = $true },
        @{ Path = ""; Name = "HR"; BreakInheritance = $false },
        @{ Path = "HR"; Name = "Policies"; BreakInheritance = $true },
        @{ Path = "HR"; Name = "Employees"; BreakInheritance = $false },
        @{ Path = ""; Name = "Projects"; BreakInheritance = $false },
        @{ Path = "Projects"; Name = "Project-Alpha"; BreakInheritance = $false },
        @{ Path = "Projects"; Name = "Project-Beta"; BreakInheritance = $true }
    )

    $createdCount = 0
    $brokenCount = 0

    foreach ($folder in $foldersToCreate) {
        $fullPath = if ($folder.Path -eq "") { $folder.Name } else { "$($folder.Path)/$($folder.Name)" }

        Write-Host "  Creating: /$fullPath" -NoNewline

        try {
            $result = New-SharePointFolder -ParentPath $folder.Path -FolderName $folder.Name
            $createdCount++
            Write-Host " [OK]" -ForegroundColor Green -NoNewline

            if ($folder.BreakInheritance) {
                Write-Host " Breaking inheritance..." -NoNewline -ForegroundColor Yellow
                if (Set-UniquePermission -ItemId $result.id -FolderName $folder.Name) {
                    $brokenCount++
                    Write-Host " [UNIQUE]" -ForegroundColor Red
                } else {
                    Write-Host " [INHERITED]" -ForegroundColor Green
                }
            } else {
                Write-Host "" # New line
            }
        }
        catch {
            Write-Host " [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  Folders Created: $createdCount"
    Write-Host "  With Unique Permissions: $brokenCount" -ForegroundColor Red
    Write-Host ""

    # Show the structure
    Write-Host "Created Structure:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  /Documents" -ForegroundColor White
    Write-Host "    |-- TestFolder1 [UNIQUE PERMISSIONS]" -ForegroundColor Red
    Write-Host "    |-- TestFolder2" -ForegroundColor White
    Write-Host "    |     |-- SubFolder2a [UNIQUE PERMISSIONS]" -ForegroundColor Red
    Write-Host "    |     |-- SubFolder2b" -ForegroundColor White
    Write-Host "    |-- TestFolder3" -ForegroundColor White
    Write-Host "    |     |-- Level2" -ForegroundColor White
    Write-Host "    |           |-- Level3 [UNIQUE PERMISSIONS]" -ForegroundColor Red
    Write-Host "    |-- HR" -ForegroundColor White
    Write-Host "    |     |-- Policies [UNIQUE PERMISSIONS]" -ForegroundColor Red
    Write-Host "    |     |-- Employees" -ForegroundColor White
    Write-Host "    |-- Projects" -ForegroundColor White
    Write-Host "          |-- Project-Alpha" -ForegroundColor White
    Write-Host "          |-- Project-Beta [UNIQUE PERMISSIONS]" -ForegroundColor Red
    Write-Host ""

    Write-Host "Test Scenarios:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Scan entire library (should find 5 folders with broken permissions)"
    Write-Host "     BaseLibraryPath: /sites/Permission-Scanner-Test/Shared Documents"
    Write-Host ""
    Write-Host "  2. Scan only /Projects folder (should find 1: Project-Beta)"
    Write-Host "     BaseLibraryPath: /sites/Permission-Scanner-Test/Shared Documents/Projects"
    Write-Host ""
    Write-Host "  3. Scan only /HR folder (should find 1: Policies)"
    Write-Host "     BaseLibraryPath: /sites/Permission-Scanner-Test/Shared Documents/HR"
    Write-Host ""
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
