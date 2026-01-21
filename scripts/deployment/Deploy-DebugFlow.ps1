<#
.SYNOPSIS
    Master script to create and deploy a debug version of the SharePoint Permission Scanner flow.

.DESCRIPTION
    This script orchestrates the complete debug deployment workflow:
    1. Extracts the original solution
    2. Modifies the flow with debug statements
    3. Limits loop iterations for testing
    4. Packages the solution
    5. Deploys to Power Platform

.PARAMETER BaseSolution
    Path to the base solution .zip file (default: SharePointPermissionScanner_FIXED.zip)

.PARAMETER MaxIterations
    Maximum loop iterations for debugging (default: 1)

.PARAMETER DeployOnly
    If specified, only deploys existing debug solution without rebuilding

.PARAMETER SkipDeploy
    If specified, creates the debug solution but doesn't deploy it

.EXAMPLE
    .\Deploy-DebugFlow.ps1

.EXAMPLE
    .\Deploy-DebugFlow.ps1 -MaxIterations 3

.EXAMPLE
    .\Deploy-DebugFlow.ps1 -SkipDeploy

.NOTES
    Author: Power Platform DevOps
    Version: 1.0
#>

param(
    [string]$BaseSolution = "$PSScriptRoot\..\solution\SharePointPermissionScanner_FIXED.zip",

    [int]$MaxIterations = 1,

    [switch]$DeployOnly,

    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot
$solutionRoot = Join-Path $scriptRoot "..\solution"
$tempFolder = Join-Path $solutionRoot "debug_build"
$outputZip = Join-Path $solutionRoot "SharePointPermissionScanner_DEBUG.zip"

# Banner
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "|     SharePoint Permission Scanner - Debug Deployment         |" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration summary
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Base Solution:    $BaseSolution" -ForegroundColor Gray
Write-Host "  Max Iterations:   $MaxIterations" -ForegroundColor Gray
Write-Host "  Output:           $outputZip" -ForegroundColor Gray
Write-Host "  Temp Folder:      $tempFolder" -ForegroundColor Gray
Write-Host ""

if (-not $DeployOnly) {
    # Step 1: Validate base solution
    Write-Host "Step 1: Validating base solution..." -ForegroundColor Cyan
    if (-not (Test-Path $BaseSolution)) {
        Write-Error "Base solution not found: $BaseSolution"
        exit 1
    }
    Write-Host "  [OK] Base solution found" -ForegroundColor Green

    # Step 2: Clean and create temp folder
    Write-Host ""
    Write-Host "Step 2: Preparing build folder..." -ForegroundColor Cyan
    if (Test-Path $tempFolder) {
        Remove-Item $tempFolder -Recurse -Force
    }
    New-Item $tempFolder -ItemType Directory | Out-Null
    Write-Host "  [OK] Build folder created" -ForegroundColor Green

    # Step 3: Extract base solution
    Write-Host ""
    Write-Host "Step 3: Extracting base solution..." -ForegroundColor Cyan
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($BaseSolution, $tempFolder)
    Write-Host "  [OK] Solution extracted" -ForegroundColor Green

    # Step 4: Find and read flow file
    Write-Host ""
    Write-Host "Step 4: Loading flow definition..." -ForegroundColor Cyan
    $workflowsPath = Join-Path $tempFolder "Workflows"
    $flowFiles = Get-ChildItem $workflowsPath -Filter "*.json"

    if ($flowFiles.Count -eq 0) {
        Write-Error "No flow files found in Workflows folder"
        exit 1
    }

    $flowFile = $flowFiles[0].FullName
    Write-Host "  [OK] Found flow: $($flowFiles[0].Name)" -ForegroundColor Green

    # Step 5: Read and modify flow JSON
    Write-Host ""
    Write-Host "Step 5: Adding debug modifications..." -ForegroundColor Cyan

    $flowJson = Get-Content $flowFile -Raw | ConvertFrom-Json

    # 5a: Modify loop limit
    $doUntil = $flowJson.properties.definition.actions.Try_Scope.actions.Do_until
    if ($doUntil) {
        $originalLimit = $doUntil.limit.count
        $doUntil.limit.count = $MaxIterations
        Write-Host "  [OK] Loop limit: $originalLimit -> $MaxIterations" -ForegroundColor Green
    }

    # 5b: Add DEBUG prefix to session name
    $addRow = $flowJson.properties.definition.actions.Add_a_new_row
    if ($addRow -and $addRow.inputs.parameters.'item/sp_name') {
        $originalName = $addRow.inputs.parameters.'item/sp_name'
        if ($originalName -notmatch '^DEBUG') {
            $addRow.inputs.parameters.'item/sp_name' = "DEBUG $originalName"
            Write-Host "  [OK] Added DEBUG prefix to session name" -ForegroundColor Green
        }
    }

    # 5c: Add debug Compose actions in loop
    $loopActions = $doUntil.actions

    # Create debug actions as ordered hashtable
    $debugActions = [ordered]@{
        "DEBUG_3_CurrentFolder" = @{
            runAfter = @{ Get_current_Folder = @("Succeeded") }
            metadata = @{ operationMetadataId = "debug-3-current-folder" }
            type = "Compose"
            inputs = @{
                Step = "3. Processing Current Folder"
                CurrentFolder = "@outputs('Get_current_Folder')"
                RemainingInQueue = "@length(variables('FoldersToProcess'))"
                TotalFoldersSoFar = "@variables('TotalFolders')"
            }
        }
        "DEBUG_4_InheritanceCheck" = @{
            runAfter = @{ check_Inheritence = @("Succeeded") }
            metadata = @{ operationMetadataId = "debug-4-inheritance" }
            type = "Compose"
            inputs = @{
                Step = "4. Inheritance Check Result"
                Folder = "@outputs('Get_current_Folder')"
                HasUniqueRoleAssignments = "@body('check_Inheritence')?['value']"
                FullResponse = "@body('check_Inheritence')"
            }
        }
        "DEBUG_9_ChildFolders" = @{
            runAfter = @{ Get_Child_Folders = @("Succeeded") }
            metadata = @{ operationMetadataId = "debug-9-children" }
            type = "Compose"
            inputs = @{
                Step = "9. Child Folders Retrieved"
                ParentFolder = "@outputs('Get_current_Folder')"
                NumberOfChildren = "@length(body('Get_Child_Folders')?['value'])"
                ChildFolders = "@body('Get_Child_Folders')?['value']"
            }
        }
        "DEBUG_11_IterationComplete" = @{
            runAfter = @{ Set_variable_3 = @("Succeeded") }
            metadata = @{ operationMetadataId = "debug-11-iteration-done" }
            type = "Compose"
            inputs = @{
                Step = "11. ITERATION COMPLETE"
                ProcessedFolder = "@outputs('Get_current_Folder')"
                TotalFoldersProcessed = "@variables('TotalFolders')"
                FoldersWithBrokenInheritance = "@variables('FoldersWithUniquePerms')"
                RemainingInQueue = "@length(variables('FoldersToProcess'))"
            }
        }
    }

    # Add debug actions to loop
    foreach ($debugName in $debugActions.Keys) {
        if (-not ($loopActions.PSObject.Properties.Name -contains $debugName)) {
            $loopActions | Add-Member -NotePropertyName $debugName -NotePropertyValue $debugActions[$debugName] -Force
            Write-Host "  [OK] Added: $debugName" -ForegroundColor Green
        }
    }

    # Update runAfter for existing actions to chain through debug actions
    # After Get_current_Folder → DEBUG_3 → check_Inheritence
    if ($loopActions.check_Inheritence) {
        $loopActions.check_Inheritence.runAfter = @{ DEBUG_3_CurrentFolder = @("Succeeded") }
    }

    # After check_Inheritence → DEBUG_4 → Increment_variable
    if ($loopActions.Increment_variable) {
        $loopActions.Increment_variable.runAfter = @{ DEBUG_4_InheritanceCheck = @("Succeeded") }
    }

    # After Get_Child_Folders → DEBUG_9 → Apply_to_each_2
    if ($loopActions.Apply_to_each_2) {
        $loopActions.Apply_to_each_2.runAfter = @{ DEBUG_9_ChildFolders = @("Succeeded") }
    }

    Write-Host "  [OK] Debug action chain configured" -ForegroundColor Green

    # Step 6: Save modified flow
    Write-Host ""
    Write-Host "Step 6: Saving modified flow..." -ForegroundColor Cyan
    # Save without BOM using .NET to avoid encoding issues
    $jsonOutput = $flowJson | ConvertTo-Json -Depth 100
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($flowFile, $jsonOutput, $utf8NoBom)
    Write-Host "  [OK] Flow saved" -ForegroundColor Green

    # Step 7: Package solution
    Write-Host ""
    Write-Host "Step 7: Packaging solution..." -ForegroundColor Cyan

    # Remove old zip
    if (Test-Path $outputZip) {
        Remove-Item $outputZip -Force
    }

    # Create zip with proper structure
    Add-Type -AssemblyName System.IO.Compression

    $zip = [System.IO.Compression.ZipFile]::Open($outputZip, [System.IO.Compression.ZipArchiveMode]::Create)

    # Add standard files
    $standardFiles = @("solution.xml", "customizations.xml")
    foreach ($fileName in $standardFiles) {
        $sourcePath = Join-Path $tempFolder $fileName
        if (Test-Path $sourcePath) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $sourcePath, $fileName) | Out-Null
            Write-Host "  [OK] Added: $fileName" -ForegroundColor Green
        }
    }

    # Add Content_Types.xml with special bracket handling
    $contentTypesPath = Join-Path $tempFolder "[Content_Types].xml"
    if (Test-Path -LiteralPath $contentTypesPath) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $contentTypesPath, "[Content_Types].xml") | Out-Null
        Write-Host "  [OK] Added: [Content_Types].xml" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] [Content_Types].xml not found!" -ForegroundColor Yellow
    }

    # Add workflows
    $workflowFiles = Get-ChildItem (Join-Path $tempFolder "Workflows") -Filter "*.json"
    foreach ($wf in $workflowFiles) {
        $entryName = "Workflows/$($wf.Name)"
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $wf.FullName, $entryName) | Out-Null
        Write-Host "  [OK] Added: $entryName" -ForegroundColor Green
    }

    $zip.Dispose()
    Write-Host "  [OK] Solution packaged: $outputZip" -ForegroundColor Green

    # Cleanup
    Write-Host ""
    Write-Host "Step 8: Cleaning up..." -ForegroundColor Cyan
    Remove-Item $tempFolder -Recurse -Force
    Write-Host "  [OK] Temp files removed" -ForegroundColor Green
}

# Step 9: Deploy
if (-not $SkipDeploy) {
    Write-Host ""
    Write-Host "Step 9: Deploying to Power Platform..." -ForegroundColor Cyan

    if (-not (Test-Path $outputZip)) {
        Write-Error "Debug solution not found: $outputZip"
        exit 1
    }

    $deployResult = & pac solution import --path $outputZip --async false 2>&1
    $deployExitCode = $LASTEXITCODE

    if ($deployExitCode -ne 0) {
        Write-Host ""
        Write-Host "  [FAIL] Deployment failed:" -ForegroundColor Red
        Write-Host $deployResult -ForegroundColor Red
        exit 1
    }

    Write-Host $deployResult -ForegroundColor Green
    Write-Host "  [OK] Solution deployed successfully" -ForegroundColor Green

    # Step 10: Verify flow status
    Write-Host ""
    Write-Host "Step 10: Verifying flow status..." -ForegroundColor Cyan

    $fetchXml = "<fetch><entity name='workflow'><attribute name='name'/><attribute name='statecode'/><filter><condition attribute='name' operator='like' value='%SharePoint Permission Scanner%'/></filter></entity></fetch>"
    $flowStatus = & pac org fetch --xml $fetchXml 2>&1
    Write-Host $flowStatus -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "|                    Deployment Complete!                       |" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Debug Features Added:" -ForegroundColor Cyan
Write-Host "  * Loop limited to $MaxIterations iteration(s)" -ForegroundColor Gray
Write-Host "  * DEBUG prefix added to scan session names" -ForegroundColor Gray
Write-Host "  * Debug Compose actions added at key steps:" -ForegroundColor Gray
Write-Host "    - DEBUG_3_CurrentFolder (after getting folder)" -ForegroundColor DarkGray
Write-Host "    - DEBUG_4_InheritanceCheck (after checking permissions)" -ForegroundColor DarkGray
Write-Host "    - DEBUG_9_ChildFolders (after getting children)" -ForegroundColor DarkGray
Write-Host "    - DEBUG_11_IterationComplete (end of iteration)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "To Test:" -ForegroundColor Cyan
Write-Host "  1. Open: https://make.powerautomate.com" -ForegroundColor Gray
Write-Host "  2. Go to Solutions → SharePoint Permission Scanner" -ForegroundColor Gray
Write-Host "  3. Open the flow and click 'Test' → 'Manually'" -ForegroundColor Gray
Write-Host "  4. Enter test parameters:" -ForegroundColor Gray
Write-Host "     SiteUrl: https://abctest179.sharepoint.com/sites/Permission-Scanner-Test" -ForegroundColor DarkGray
Write-Host "     LibraryName: TestLibrary_Basic" -ForegroundColor DarkGray
Write-Host "  5. Click each step in run history to see debug outputs" -ForegroundColor Gray
Write-Host ""
