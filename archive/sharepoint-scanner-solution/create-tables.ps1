# Create Dataverse Tables for SharePoint Permission Scanner
# Run this script after creating the solution

$ErrorActionPreference = "Stop"

# Get access token
$token = az account get-access-token --resource https://org3a2a4fe5.crm6.dynamics.com --query accessToken -o tsv
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
    "OData-MaxVersion" = "4.0"
    "OData-Version" = "4.0"
}

$baseUrl = "https://org3a2a4fe5.crm6.dynamics.com/api/data/v9.2"

Write-Host "Creating Dataverse tables for SharePoint Permission Scanner..." -ForegroundColor Cyan

# =====================================================
# TABLE 1: Scan Session (sp_scansession)
# =====================================================
Write-Host "`n[1/3] Creating sp_scansession table..." -ForegroundColor Yellow

$scanSessionTable = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.EntityMetadata"
    "SchemaName" = "sp_scansession"
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(
            @{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                "Label" = "Scan Session"
                "LanguageCode" = 1033
            }
        )
    }
    "DisplayCollectionName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(
            @{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                "Label" = "Scan Sessions"
                "LanguageCode" = 1033
            }
        )
    }
    "Description" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(
            @{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                "Label" = "Tracks SharePoint permission scan operations"
                "LanguageCode" = 1033
            }
        )
    }
    "OwnershipType" = "UserOwned"
    "HasNotes" = $false
    "HasActivities" = $false
    "PrimaryNameAttribute" = "sp_name"
    "Attributes" = @(
        @{
            "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
            "SchemaName" = "sp_name"
            "RequiredLevel" = @{ "Value" = "ApplicationRequired" }
            "MaxLength" = 100
            "DisplayName" = @{
                "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                "LocalizedLabels" = @(@{ "Label" = "Name"; "LanguageCode" = 1033 })
            }
            "IsPrimaryName" = $true
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions" -Method Post -Headers $headers -Body $scanSessionTable
    Write-Host "  sp_scansession table created successfully!" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "  sp_scansession may already exist, continuing..." -ForegroundColor Yellow
    } else {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Add additional columns to sp_scansession
Write-Host "  Adding columns to sp_scansession..." -ForegroundColor Yellow

# sp_siteurl column
$siteUrlColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "SchemaName" = "sp_siteurl"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 500
    "FormatName" = @{ "Value" = "Url" }
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Site URL"; "LanguageCode" = 1033 })
    }
    "Description" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "SharePoint site URL"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $siteUrlColumn
    Write-Host "    sp_siteurl added" -ForegroundColor Green
} catch { Write-Host "    sp_siteurl: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_libraryname column
$libraryNameColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "SchemaName" = "sp_libraryname"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 255
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Library Name"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $libraryNameColumn
    Write-Host "    sp_libraryname added" -ForegroundColor Green
} catch { Write-Host "    sp_libraryname: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_status column (Choice/OptionSet)
$statusColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
    "SchemaName" = "sp_status"
    "RequiredLevel" = @{ "Value" = "None" }
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Status"; "LanguageCode" = 1033 })
    }
    "OptionSet" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
        "IsGlobal" = $false
        "OptionSetType" = "Picklist"
        "Options" = @(
            @{ "Value" = 100000000; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "Pending"; "LanguageCode" = 1033 }) } }
            @{ "Value" = 100000001; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "Running"; "LanguageCode" = 1033 }) } }
            @{ "Value" = 100000002; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "Completed"; "LanguageCode" = 1033 }) } }
            @{ "Value" = 100000003; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "Failed"; "LanguageCode" = 1033 }) } }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $statusColumn
    Write-Host "    sp_status added" -ForegroundColor Green
} catch { Write-Host "    sp_status: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_startedon column
$startedOnColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
    "SchemaName" = "sp_startedon"
    "RequiredLevel" = @{ "Value" = "None" }
    "Format" = "DateAndTime"
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Started On"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $startedOnColumn
    Write-Host "    sp_startedon added" -ForegroundColor Green
} catch { Write-Host "    sp_startedon: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_completedon column
$completedOnColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
    "SchemaName" = "sp_completedon"
    "RequiredLevel" = @{ "Value" = "None" }
    "Format" = "DateAndTime"
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Completed On"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $completedOnColumn
    Write-Host "    sp_completedon added" -ForegroundColor Green
} catch { Write-Host "    sp_completedon: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_totalfolders column
$totalFoldersColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
    "SchemaName" = "sp_totalfolders"
    "RequiredLevel" = @{ "Value" = "None" }
    "MinValue" = 0
    "MaxValue" = 2147483647
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Total Folders"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $totalFoldersColumn
    Write-Host "    sp_totalfolders added" -ForegroundColor Green
} catch { Write-Host "    sp_totalfolders: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_folderswithuniqueperms column
$uniquePermsColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
    "SchemaName" = "sp_folderswithuniqueperms"
    "RequiredLevel" = @{ "Value" = "None" }
    "MinValue" = 0
    "MaxValue" = 2147483647
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Folders with Unique Perms"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $uniquePermsColumn
    Write-Host "    sp_folderswithuniqueperms added" -ForegroundColor Green
} catch { Write-Host "    sp_folderswithuniqueperms: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_errormessage column
$errorMessageColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.MemoAttributeMetadata"
    "SchemaName" = "sp_errormessage"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 10000
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Error Message"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_scansession')/Attributes" -Method Post -Headers $headers -Body $errorMessageColumn
    Write-Host "    sp_errormessage added" -ForegroundColor Green
} catch { Write-Host "    sp_errormessage: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "  sp_scansession table completed!" -ForegroundColor Green

# =====================================================
# TABLE 2: Folder Record (sp_folderrecord)
# =====================================================
Write-Host "`n[2/3] Creating sp_folderrecord table..." -ForegroundColor Yellow

$folderRecordTable = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.EntityMetadata"
    "SchemaName" = "sp_folderrecord"
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Folder Record"; "LanguageCode" = 1033 })
    }
    "DisplayCollectionName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Folder Records"; "LanguageCode" = 1033 })
    }
    "Description" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Stores folder information from SharePoint scans"; "LanguageCode" = 1033 })
    }
    "OwnershipType" = "UserOwned"
    "HasNotes" = $false
    "HasActivities" = $false
    "PrimaryNameAttribute" = "sp_name"
    "Attributes" = @(
        @{
            "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
            "SchemaName" = "sp_name"
            "RequiredLevel" = @{ "Value" = "ApplicationRequired" }
            "MaxLength" = 500
            "DisplayName" = @{
                "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                "LocalizedLabels" = @(@{ "Label" = "Folder Name"; "LanguageCode" = 1033 })
            }
            "IsPrimaryName" = $true
        }
    )
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions" -Method Post -Headers $headers -Body $folderRecordTable
    Write-Host "  sp_folderrecord table created successfully!" -ForegroundColor Green
} catch {
    Write-Host "  sp_folderrecord: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Add columns to sp_folderrecord
Write-Host "  Adding columns to sp_folderrecord..." -ForegroundColor Yellow

# sp_folderpath column
$folderPathColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "SchemaName" = "sp_folderpath"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 2000
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Folder Path"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_folderrecord')/Attributes" -Method Post -Headers $headers -Body $folderPathColumn
    Write-Host "    sp_folderpath added" -ForegroundColor Green
} catch { Write-Host "    sp_folderpath: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_hasuniqueperms column
$hasUniquePermsColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.BooleanAttributeMetadata"
    "SchemaName" = "sp_hasuniqueperms"
    "RequiredLevel" = @{ "Value" = "None" }
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Has Unique Permissions"; "LanguageCode" = 1033 })
    }
    "OptionSet" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.BooleanOptionSetMetadata"
        "TrueOption" = @{ "Value" = 1; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "Yes"; "LanguageCode" = 1033 }) } }
        "FalseOption" = @{ "Value" = 0; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "No"; "LanguageCode" = 1033 }) } }
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_folderrecord')/Attributes" -Method Post -Headers $headers -Body $hasUniquePermsColumn
    Write-Host "    sp_hasuniqueperms added" -ForegroundColor Green
} catch { Write-Host "    sp_hasuniqueperms: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_depth column
$depthColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
    "SchemaName" = "sp_depth"
    "RequiredLevel" = @{ "Value" = "None" }
    "MinValue" = 0
    "MaxValue" = 100
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Depth"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_folderrecord')/Attributes" -Method Post -Headers $headers -Body $depthColumn
    Write-Host "    sp_depth added" -ForegroundColor Green
} catch { Write-Host "    sp_depth: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_itemcount column
$itemCountColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
    "SchemaName" = "sp_itemcount"
    "RequiredLevel" = @{ "Value" = "None" }
    "MinValue" = 0
    "MaxValue" = 2147483647
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Item Count"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_folderrecord')/Attributes" -Method Post -Headers $headers -Body $itemCountColumn
    Write-Host "    sp_itemcount added" -ForegroundColor Green
} catch { Write-Host "    sp_itemcount: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_lastmodified column
$lastModifiedColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
    "SchemaName" = "sp_lastmodified"
    "RequiredLevel" = @{ "Value" = "None" }
    "Format" = "DateAndTime"
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Last Modified"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_folderrecord')/Attributes" -Method Post -Headers $headers -Body $lastModifiedColumn
    Write-Host "    sp_lastmodified added" -ForegroundColor Green
} catch { Write-Host "    sp_lastmodified: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "  sp_folderrecord table completed!" -ForegroundColor Green

# =====================================================
# TABLE 3: Permission Entry (sp_permissionentry)
# =====================================================
Write-Host "`n[3/3] Creating sp_permissionentry table..." -ForegroundColor Yellow

$permissionEntryTable = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.EntityMetadata"
    "SchemaName" = "sp_permissionentry"
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Permission Entry"; "LanguageCode" = 1033 })
    }
    "DisplayCollectionName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Permission Entries"; "LanguageCode" = 1033 })
    }
    "Description" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Stores permission assignments for folders"; "LanguageCode" = 1033 })
    }
    "OwnershipType" = "UserOwned"
    "HasNotes" = $false
    "HasActivities" = $false
    "PrimaryNameAttribute" = "sp_name"
    "Attributes" = @(
        @{
            "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
            "SchemaName" = "sp_name"
            "RequiredLevel" = @{ "Value" = "ApplicationRequired" }
            "MaxLength" = 255
            "DisplayName" = @{
                "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                "LocalizedLabels" = @(@{ "Label" = "Name"; "LanguageCode" = 1033 })
            }
            "IsPrimaryName" = $true
        }
    )
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions" -Method Post -Headers $headers -Body $permissionEntryTable
    Write-Host "  sp_permissionentry table created successfully!" -ForegroundColor Green
} catch {
    Write-Host "  sp_permissionentry: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Add columns to sp_permissionentry
Write-Host "  Adding columns to sp_permissionentry..." -ForegroundColor Yellow

# sp_principaltype column
$principalTypeColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
    "SchemaName" = "sp_principaltype"
    "RequiredLevel" = @{ "Value" = "None" }
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Principal Type"; "LanguageCode" = 1033 })
    }
    "OptionSet" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
        "IsGlobal" = $false
        "OptionSetType" = "Picklist"
        "Options" = @(
            @{ "Value" = 100000000; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "User"; "LanguageCode" = 1033 }) } }
            @{ "Value" = 100000001; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "Security Group"; "LanguageCode" = 1033 }) } }
            @{ "Value" = 100000002; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "SharePoint Group"; "LanguageCode" = 1033 }) } }
            @{ "Value" = 100000003; "Label" = @{ "LocalizedLabels" = @(@{ "Label" = "M365 Group"; "LanguageCode" = 1033 }) } }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_permissionentry')/Attributes" -Method Post -Headers $headers -Body $principalTypeColumn
    Write-Host "    sp_principaltype added" -ForegroundColor Green
} catch { Write-Host "    sp_principaltype: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_principalname column
$principalNameColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "SchemaName" = "sp_principalname"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 255
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Principal Name"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_permissionentry')/Attributes" -Method Post -Headers $headers -Body $principalNameColumn
    Write-Host "    sp_principalname added" -ForegroundColor Green
} catch { Write-Host "    sp_principalname: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_principalemail column
$principalEmailColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "SchemaName" = "sp_principalemail"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 255
    "FormatName" = @{ "Value" = "Email" }
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Principal Email"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_permissionentry')/Attributes" -Method Post -Headers $headers -Body $principalEmailColumn
    Write-Host "    sp_principalemail added" -ForegroundColor Green
} catch { Write-Host "    sp_principalemail: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_principalid column
$principalIdColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
    "SchemaName" = "sp_principalid"
    "RequiredLevel" = @{ "Value" = "None" }
    "MinValue" = -2147483648
    "MaxValue" = 2147483647
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Principal ID"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_permissionentry')/Attributes" -Method Post -Headers $headers -Body $principalIdColumn
    Write-Host "    sp_principalid added" -ForegroundColor Green
} catch { Write-Host "    sp_principalid: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_permissionlevel column
$permissionLevelColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "SchemaName" = "sp_permissionlevel"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 100
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Permission Level"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_permissionentry')/Attributes" -Method Post -Headers $headers -Body $permissionLevelColumn
    Write-Host "    sp_permissionlevel added" -ForegroundColor Green
} catch { Write-Host "    sp_permissionlevel: $($_.Exception.Message)" -ForegroundColor Yellow }

# sp_permissionmask column
$permissionMaskColumn = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "SchemaName" = "sp_permissionmask"
    "RequiredLevel" = @{ "Value" = "None" }
    "MaxLength" = 50
    "DisplayName" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        "LocalizedLabels" = @(@{ "Label" = "Permission Mask"; "LanguageCode" = 1033 })
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions(LogicalName='sp_permissionentry')/Attributes" -Method Post -Headers $headers -Body $permissionMaskColumn
    Write-Host "    sp_permissionmask added" -ForegroundColor Green
} catch { Write-Host "    sp_permissionmask: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "  sp_permissionentry table completed!" -ForegroundColor Green

# =====================================================
# Create Relationships
# =====================================================
Write-Host "`n[4/4] Creating relationships..." -ForegroundColor Yellow

# Relationship: sp_scansession -> sp_folderrecord (1:N)
$scanToFolderRelationship = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata"
    "SchemaName" = "sp_scansession_folderrecords"
    "ReferencedEntity" = "sp_scansession"
    "ReferencingEntity" = "sp_folderrecord"
    "Lookup" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.LookupAttributeMetadata"
        "SchemaName" = "sp_scansession"
        "DisplayName" = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{ "Label" = "Scan Session"; "LanguageCode" = 1033 })
        }
    }
    "CascadeConfiguration" = @{
        "Delete" = "Cascade"
        "Assign" = "NoCascade"
        "Share" = "NoCascade"
        "Unshare" = "NoCascade"
        "Reparent" = "NoCascade"
        "Merge" = "NoCascade"
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/RelationshipDefinitions" -Method Post -Headers $headers -Body $scanToFolderRelationship
    Write-Host "  sp_scansession -> sp_folderrecord relationship created" -ForegroundColor Green
} catch { Write-Host "  Relationship sp_scansession_folderrecords: $($_.Exception.Message)" -ForegroundColor Yellow }

# Relationship: sp_folderrecord -> sp_folderrecord (self-referential for parent)
$folderToParentRelationship = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata"
    "SchemaName" = "sp_folderrecord_parentfolder"
    "ReferencedEntity" = "sp_folderrecord"
    "ReferencingEntity" = "sp_folderrecord"
    "Lookup" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.LookupAttributeMetadata"
        "SchemaName" = "sp_parentfolder"
        "DisplayName" = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{ "Label" = "Parent Folder"; "LanguageCode" = 1033 })
        }
    }
    "CascadeConfiguration" = @{
        "Delete" = "RemoveLink"
        "Assign" = "NoCascade"
        "Share" = "NoCascade"
        "Unshare" = "NoCascade"
        "Reparent" = "NoCascade"
        "Merge" = "NoCascade"
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/RelationshipDefinitions" -Method Post -Headers $headers -Body $folderToParentRelationship
    Write-Host "  sp_folderrecord -> sp_parentfolder (self) relationship created" -ForegroundColor Green
} catch { Write-Host "  Relationship sp_folderrecord_parentfolder: $($_.Exception.Message)" -ForegroundColor Yellow }

# Relationship: sp_folderrecord -> sp_permissionentry (1:N)
$folderToPermissionRelationship = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata"
    "SchemaName" = "sp_folderrecord_permissionentries"
    "ReferencedEntity" = "sp_folderrecord"
    "ReferencingEntity" = "sp_permissionentry"
    "Lookup" = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.LookupAttributeMetadata"
        "SchemaName" = "sp_folderrecord"
        "DisplayName" = @{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            "LocalizedLabels" = @(@{ "Label" = "Folder Record"; "LanguageCode" = 1033 })
        }
    }
    "CascadeConfiguration" = @{
        "Delete" = "Cascade"
        "Assign" = "NoCascade"
        "Share" = "NoCascade"
        "Unshare" = "NoCascade"
        "Reparent" = "NoCascade"
        "Merge" = "NoCascade"
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/RelationshipDefinitions" -Method Post -Headers $headers -Body $folderToPermissionRelationship
    Write-Host "  sp_folderrecord -> sp_permissionentry relationship created" -ForegroundColor Green
} catch { Write-Host "  Relationship sp_folderrecord_permissionentries: $($_.Exception.Message)" -ForegroundColor Yellow }

# Publish all customizations
Write-Host "`nPublishing customizations..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$baseUrl/PublishAllXml" -Method Post -Headers $headers
    Write-Host "Customizations published successfully!" -ForegroundColor Green
} catch { Write-Host "Publish error: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Table creation completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tables created:"
Write-Host "  1. sp_scansession (Scan Session)"
Write-Host "  2. sp_folderrecord (Folder Record)"
Write-Host "  3. sp_permissionentry (Permission Entry)"
Write-Host "`nRelationships created:"
Write-Host "  - sp_scansession -> sp_folderrecord (cascade delete)"
Write-Host "  - sp_folderrecord -> sp_parentfolder (self-referential)"
Write-Host "  - sp_folderrecord -> sp_permissionentry (cascade delete)"
Write-Host "`nVerify at: https://make.powerapps.com" -ForegroundColor Yellow
