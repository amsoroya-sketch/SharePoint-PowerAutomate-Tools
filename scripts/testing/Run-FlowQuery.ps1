<#
.SYNOPSIS
    Simulates the Power Automate flow query to show expected results.

.DESCRIPTION
    Runs the same OData query that the flow uses to find folders with broken permissions.

.PARAMETER LibraryName
    Document library name (use "Documents" not "Shared Documents")

.PARAMETER BaseLibraryPath
    Server-relative path to filter folders

.EXAMPLE
    .\Run-FlowQuery.ps1
#>

param(
    [string]$SiteURL = "https://abctest179.sharepoint.com/sites/Permission-Scanner-Test",
    [string]$LibraryName = "Documents",
    [string]$BaseLibraryPath = "/sites/Permission-Scanner-Test/Shared Documents",
    [string]$MinimumLevel = "-1"
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

Write-Host "=== Power Automate Flow Query Simulator ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Simulating: Folders with Broken Permissions by Level" -ForegroundColor Yellow
Write-Host ""
Write-Host "Input Parameters:" -ForegroundColor White
Write-Host "  SiteURL: $SiteURL"
Write-Host "  LibraryName: $LibraryName"
Write-Host "  BaseLibraryPath: $BaseLibraryPath"
Write-Host "  MinimumLevel: $MinimumLevel"
Write-Host ""

# Get Access Token
$sharePointHost = ([System.Uri]$SiteURL).Host

Write-Host "Step 1: Authenticating..." -ForegroundColor Yellow
try {
    $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $tokenBody = @{
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://$sharePointHost/.default"
        grant_type    = "client_credentials"
    }
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "  [OK] Authenticated" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Auth failed - trying user context via Graph..." -ForegroundColor Yellow

    # Fallback to Graph API approach
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

        Write-Host "  [OK] Using Graph API fallback" -ForegroundColor Green
        Write-Host ""
        Write-Host "Note: Direct SharePoint REST API requires delegated permissions." -ForegroundColor Yellow
        Write-Host "The Power Automate flow uses user context (invoker connection)." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Showing expected results based on Graph API scan:" -ForegroundColor Cyan
        Write-Host ""

        # Use Graph API to get folders with permissions
        $siteHost = ([System.Uri]$SiteURL).Host
        $sitePath = ([System.Uri]$SiteURL).AbsolutePath

        $headers = @{
            "Authorization" = "Bearer $accessToken"
            "Content-Type"  = "application/json"
        }

        # Get site
        $siteApiUrl = "https://graph.microsoft.com/v1.0/sites/${siteHost}:${sitePath}"
        $siteResponse = Invoke-RestMethod -Uri $siteApiUrl -Headers $headers -Method GET
        $siteId = $siteResponse.id

        # Get drive
        $drivesUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/drives"
        $drivesResponse = Invoke-RestMethod -Uri $drivesUrl -Headers $headers -Method GET
        $drive = $drivesResponse.value | Where-Object { $_.name -eq $LibraryName } | Select-Object -First 1
        $driveId = $drive.id

        # Recursively get all folders
        function Get-AllFolders {
            param($parentId, $parentPath, $level)

            $results = @()
            $url = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$parentId/children"
            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET

            foreach ($item in $response.value) {
                if ($item.folder) {
                    $folderPath = "$parentPath/$($item.name)"

                    # Check permissions
                    $permUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($item.id)/permissions"
                    try {
                        $permResponse = Invoke-RestMethod -Uri $permUrl -Headers $headers -Method GET
                        $directPerms = $permResponse.value | Where-Object { $_.inheritedFrom -eq $null }
                        $hasUniquePerms = $directPerms.Count -gt 0
                    } catch {
                        $hasUniquePerms = $false
                    }

                    $results += @{
                        Name = $item.name
                        Path = $folderPath
                        Level = $level
                        HasUniquePermissions = $hasUniquePerms
                        ChildCount = $item.folder.childCount
                    }

                    # Recurse into subfolders
                    if ($item.folder.childCount -gt 0 -and $level -lt 5) {
                        $results += Get-AllFolders -parentId $item.id -parentPath $folderPath -level ($level + 1)
                    }
                }
            }
            return $results
        }

        Write-Host "Scanning all folders..." -ForegroundColor Yellow
        $allFolders = Get-AllFolders -parentId "root" -parentPath "" -level 0

        # Filter by path
        $filteredFolders = $allFolders | Where-Object { $_.HasUniquePermissions -eq $true }

        Write-Host ""
        Write-Host "=== FLOW OUTPUT (Simulated) ===" -ForegroundColor Cyan
        Write-Host ""

        # Simulate DEBUG_ParsedFolders output
        Write-Host "DEBUG_ParsedFolders:" -ForegroundColor Yellow
        Write-Host "{" -ForegroundColor White
        Write-Host "  `"Step`": `"Folders with Broken Permissions Found`"," -ForegroundColor White
        Write-Host "  `"TotalCount`": $($filteredFolders.Count)," -ForegroundColor White
        Write-Host "  `"SiteURL`": `"$SiteURL`"," -ForegroundColor White
        Write-Host "  `"LibraryName`": `"$LibraryName`"" -ForegroundColor White
        Write-Host "}" -ForegroundColor White
        Write-Host ""

        # Show folders found
        Write-Host "Folders with Broken Permissions:" -ForegroundColor Yellow
        Write-Host ""

        if ($filteredFolders.Count -eq 0) {
            Write-Host "  (No folders with broken permissions found)" -ForegroundColor Gray
        } else {
            $i = 1
            foreach ($folder in $filteredFolders) {
                Write-Host "  [$i] $($folder.Name)" -ForegroundColor Red
                Write-Host "      Path: /Shared Documents$($folder.Path)"
                Write-Host "      Level: $($folder.Level)"
                Write-Host "      HasUniqueRoleAssignments: true"
                Write-Host ""
                $i++
            }
        }

        # Simulate Select_Add_Level output
        Write-Host "Select_Add_Level Output:" -ForegroundColor Yellow
        Write-Host "[" -ForegroundColor White
        $filteredFolders | ForEach-Object {
            Write-Host "  {" -ForegroundColor White
            Write-Host "    `"FileLeafRef`": `"$($_.Name)`"," -ForegroundColor White
            Write-Host "    `"FileRef`": `"/sites/Permission-Scanner-Test/Shared Documents$($_.Path)`"," -ForegroundColor White
            Write-Host "    `"Level`": $($_.Level)," -ForegroundColor White
            Write-Host "    `"HasUniqueRoleAssignments`": true" -ForegroundColor White
            Write-Host "  }," -ForegroundColor White
        }
        Write-Host "]" -ForegroundColor White

        Write-Host ""
        Write-Host "=== Summary ===" -ForegroundColor Green
        Write-Host "Total Folders Scanned: $($allFolders.Count)"
        Write-Host "Folders with Broken Permissions: $($filteredFolders.Count)" -ForegroundColor Red

        exit 0
    }
    catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Build the exact query the flow uses
$select = "Id,Title,FileLeafRef,FileRef,FileDirRef,Created,Modified,AuthorId,EditorId,HasUniqueRoleAssignments,FileSystemObjectType,ItemChildCount,FolderChildCount"
$filter = "HasUniqueRoleAssignments eq true and FileSystemObjectType eq 1 and startswith(FileRef,'$BaseLibraryPath')"
$apiUrl = "$SiteURL/_api/web/lists/getbytitle('$LibraryName')/items?`$select=$select&`$filter=$filter"

Write-Host "Step 2: Executing OData Query..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Query URL:" -ForegroundColor Gray
Write-Host "  $apiUrl" -ForegroundColor Gray
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Accept"        = "application/json;odata=verbose"
    "Content-Type"  = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method GET
    $folders = $response.d.results

    Write-Host "  [OK] Query successful" -ForegroundColor Green
    Write-Host ""

    # Calculate base depth
    $baseDepth = $BaseLibraryPath.Split('/').Count

    Write-Host "=== FLOW OUTPUT ===" -ForegroundColor Cyan
    Write-Host ""

    # Simulate DEBUG_ParsedFolders
    Write-Host "DEBUG_ParsedFolders:" -ForegroundColor Yellow
    Write-Host "{" -ForegroundColor White
    Write-Host "  `"Step`": `"Folders with Broken Permissions Found`"," -ForegroundColor White
    Write-Host "  `"TotalCount`": $($folders.Count)," -ForegroundColor White
    Write-Host "  `"SiteURL`": `"$SiteURL`"," -ForegroundColor White
    Write-Host "  `"LibraryName`": `"$LibraryName`"" -ForegroundColor White
    Write-Host "}" -ForegroundColor White
    Write-Host ""

    # Show folders
    Write-Host "Folders Found:" -ForegroundColor Yellow
    Write-Host ""

    if ($folders.Count -eq 0) {
        Write-Host "  (No folders with broken permissions found)" -ForegroundColor Gray
    } else {
        $i = 1
        foreach ($folder in $folders) {
            $level = $folder.FileRef.Split('/').Count - $baseDepth

            Write-Host "  [$i] $($folder.FileLeafRef)" -ForegroundColor Red
            Write-Host "      Path: $($folder.FileRef)"
            Write-Host "      Level: $level"
            Write-Host "      HasUniqueRoleAssignments: $($folder.HasUniqueRoleAssignments)"
            Write-Host ""
            $i++
        }
    }

    Write-Host "=== Summary ===" -ForegroundColor Green
    Write-Host "Folders with Broken Permissions: $($folders.Count)"
}
catch {
    Write-Host "  [ERROR] Query failed: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        Write-Host "  Response: $errorBody" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
