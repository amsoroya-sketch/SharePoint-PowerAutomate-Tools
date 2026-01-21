<#
.SYNOPSIS
    Query SharePoint for folders using Microsoft Graph API.

.DESCRIPTION
    Uses Graph API to list folders and their sharing/permissions status.

.PARAMETER SiteURL
    SharePoint site URL

.PARAMETER LibraryName
    Document library name (drive name)

.EXAMPLE
    .\Get-SharePointFolders-Graph.ps1
#>

param(
    [string]$SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test",
    [string]$LibraryName = "Shared Documents"
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

Write-Host "=== SharePoint Folder Scanner (Graph API) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Site: $SiteURL" -ForegroundColor White
Write-Host "Library: $LibraryName" -ForegroundColor White
Write-Host ""

# Parse site info
$siteHost = ([System.Uri]$SiteURL).Host
$sitePath = ([System.Uri]$SiteURL).AbsolutePath

# Get Access Token for Graph API
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
    Write-Host "  [OK] Authenticated to Graph API" -ForegroundColor Green
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

# Step 1: Get Site ID
Write-Host "Getting site information..." -ForegroundColor Yellow
try {
    $siteApiUrl = "https://graph.microsoft.com/v1.0/sites/${siteHost}:${sitePath}"
    $siteResponse = Invoke-RestMethod -Uri $siteApiUrl -Headers $headers -Method GET
    $siteId = $siteResponse.id
    Write-Host "  [OK] Site ID: $siteId" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Failed to get site: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Get Drives (Document Libraries)
Write-Host "Getting document libraries..." -ForegroundColor Yellow
try {
    $drivesUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/drives"
    $drivesResponse = Invoke-RestMethod -Uri $drivesUrl -Headers $headers -Method GET

    $drive = $drivesResponse.value | Where-Object { $_.name -eq $LibraryName -or $_.name -eq "Documents" }

    if ($drive) {
        $driveId = $drive.id
        Write-Host "  [OK] Drive: $($drive.name) (ID: $driveId)" -ForegroundColor Green
    } else {
        Write-Host "  Available drives:" -ForegroundColor Yellow
        $drivesResponse.value | ForEach-Object {
            Write-Host "    - $($_.name)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  [ERROR] Library '$LibraryName' not found" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  [ERROR] Failed to get drives: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Get Root Folder Children
Write-Host "Getting folders from library..." -ForegroundColor Yellow
try {
    $childrenUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/root/children"
    $childrenResponse = Invoke-RestMethod -Uri $childrenUrl -Headers $headers -Method GET

    $folders = $childrenResponse.value | Where-Object { $_.folder -ne $null }

    if ($folders.Count -eq 0) {
        Write-Host "  No folders found in library root." -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Found $($folders.Count) folder(s) in root" -ForegroundColor Green
        Write-Host ""

        Write-Host "Folder Structure:" -ForegroundColor Yellow
        Write-Host ""

        foreach ($folder in $folders) {
            Write-Host "  [$($folder.name)]" -ForegroundColor White
            Write-Host "    ID: $($folder.id)" -ForegroundColor Gray
            Write-Host "    Path: $($folder.parentReference.path)/$($folder.name)" -ForegroundColor Gray
            Write-Host "    Child Count: $($folder.folder.childCount)" -ForegroundColor Gray
            Write-Host "    Web URL: $($folder.webUrl)" -ForegroundColor Gray

            # Check for unique permissions (sharing)
            try {
                $permUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($folder.id)/permissions"
                $permResponse = Invoke-RestMethod -Uri $permUrl -Headers $headers -Method GET

                $inheritedPerms = $permResponse.value | Where-Object { $_.inheritedFrom -ne $null }
                $directPerms = $permResponse.value | Where-Object { $_.inheritedFrom -eq $null }

                if ($directPerms.Count -gt 0) {
                    Write-Host "    Permissions: UNIQUE ($($directPerms.Count) direct)" -ForegroundColor Red
                } else {
                    Write-Host "    Permissions: Inherited" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "    Permissions: Unable to check" -ForegroundColor Yellow
            }

            Write-Host ""

            # Get subfolders (1 level deep)
            try {
                $subUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($folder.id)/children"
                $subResponse = Invoke-RestMethod -Uri $subUrl -Headers $headers -Method GET
                $subFolders = $subResponse.value | Where-Object { $_.folder -ne $null }

                if ($subFolders.Count -gt 0) {
                    foreach ($sub in $subFolders) {
                        Write-Host "      |-- [$($sub.name)]" -ForegroundColor White
                        Write-Host "          Child Count: $($sub.folder.childCount)" -ForegroundColor Gray

                        # Check permissions
                        try {
                            $subPermUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($sub.id)/permissions"
                            $subPermResponse = Invoke-RestMethod -Uri $subPermUrl -Headers $headers -Method GET

                            $subDirectPerms = $subPermResponse.value | Where-Object { $_.inheritedFrom -eq $null }

                            if ($subDirectPerms.Count -gt 0) {
                                Write-Host "          Permissions: UNIQUE" -ForegroundColor Red
                            } else {
                                Write-Host "          Permissions: Inherited" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-Host "          Permissions: Unable to check" -ForegroundColor Yellow
                        }
                        Write-Host ""
                    }
                }
            }
            catch {
                # Ignore subfolder errors
            }
        }
    }
}
catch {
    Write-Host "  [ERROR] Failed to get folders: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
