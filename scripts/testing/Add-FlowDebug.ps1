<#
.SYNOPSIS
    Adds debug Compose actions to a Power Automate flow JSON file.

.DESCRIPTION
    This script modifies a Power Automate flow definition to add debug
    Compose actions after each step. It also allows limiting loop iterations
    for testing purposes.

.PARAMETER FlowFile
    Path to the flow JSON file to modify.

.PARAMETER OutputFile
    Path where the modified flow will be saved. If not specified,
    creates a _DEBUG version of the input file.

.PARAMETER MaxLoopIterations
    Maximum number of loop iterations (default: 1 for debugging).
    Set to 0 to use the original limit.

.PARAMETER AddDebugToLoop
    If specified, adds debug Compose actions inside Do_until loops.

.PARAMETER Backup
    If specified, creates a backup of the original file.

.EXAMPLE
    .\Add-FlowDebug.ps1 -FlowFile ".\flow.json" -MaxLoopIterations 1

.EXAMPLE
    .\Add-FlowDebug.ps1 -FlowFile ".\flow.json" -OutputFile ".\flow_debug.json" -AddDebugToLoop -Backup

.NOTES
    Author: Power Platform DevOps
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$FlowFile,

    [string]$OutputFile,

    [int]$MaxLoopIterations = 1,

    [switch]$AddDebugToLoop,

    [switch]$Backup
)

# Validate input file
if (-not (Test-Path $FlowFile)) {
    Write-Error "Flow file not found: $FlowFile"
    exit 1
}

# Set default output file
if (-not $OutputFile) {
    $directory = Split-Path $FlowFile -Parent
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($FlowFile)
    $extension = [System.IO.Path]::GetExtension($FlowFile)
    $OutputFile = Join-Path $directory "$($filename)_DEBUG$extension"
}

Write-Host "=== Power Automate Flow Debug Modifier ===" -ForegroundColor Cyan
Write-Host "Input:  $FlowFile" -ForegroundColor Gray
Write-Host "Output: $OutputFile" -ForegroundColor Gray
Write-Host "Max Loop Iterations: $MaxLoopIterations" -ForegroundColor Gray
Write-Host ""

# Create backup if requested
if ($Backup) {
    $backupFile = $FlowFile -replace '\.json$', '_BACKUP.json'
    Copy-Item $FlowFile $backupFile -Force
    Write-Host "Backup created: $backupFile" -ForegroundColor Yellow
}

try {
    # Read and parse JSON
    $jsonContent = Get-Content $FlowFile -Raw
    $flow = $jsonContent | ConvertFrom-Json -Depth 100

    # Track modifications
    $modifications = @()

    # Function to add debug action
    function Add-DebugAction {
        param(
            [string]$Name,
            [string]$Step,
            [hashtable]$DebugData,
            [string]$RunAfter
        )

        return @{
            runAfter = @{
                $RunAfter = @("Succeeded")
            }
            metadata = @{
                operationMetadataId = "debug-$($Name.ToLower())"
            }
            type = "Compose"
            inputs = @{
                Step = $Step
            } + $DebugData
        }
    }

    # Modify Do_until loop limit
    $definition = $flow.properties.definition
    $actions = $definition.actions

    # Find and modify Try_Scope
    if ($actions.Try_Scope -and $actions.Try_Scope.actions.Do_until) {
        $doUntil = $actions.Try_Scope.actions.Do_until

        # Modify loop limit
        if ($MaxLoopIterations -gt 0) {
            $originalLimit = $doUntil.limit.count
            $doUntil.limit.count = $MaxLoopIterations
            $modifications += "Changed Do_until loop limit from $originalLimit to $MaxLoopIterations"
            Write-Host "Modified: Loop limit set to $MaxLoopIterations iterations" -ForegroundColor Green
        }

        # Add debug actions if requested
        if ($AddDebugToLoop) {
            $loopActions = $doUntil.actions

            # Define debug points to add
            $debugPoints = @(
                @{
                    Name = "DEBUG_CurrentFolder"
                    After = "Get_current_Folder"
                    Step = "Current Folder Being Processed"
                    Data = @{
                        CurrentFolder = "@outputs('Get_current_Folder')"
                        QueueLength = "@length(variables('FoldersToProcess'))"
                    }
                },
                @{
                    Name = "DEBUG_InheritanceResult"
                    After = "check_Inheritence"
                    Step = "Inheritance Check Result"
                    Data = @{
                        HasUniquePermissions = "@body('check_Inheritence')?['value']"
                        Folder = "@outputs('Get_current_Folder')"
                    }
                },
                @{
                    Name = "DEBUG_ChildFolders"
                    After = "Get_Child_Folders"
                    Step = "Child Folders Retrieved"
                    Data = @{
                        ChildCount = "@length(body('Get_Child_Folders')?['value'])"
                        Children = "@body('Get_Child_Folders')?['value']"
                    }
                },
                @{
                    Name = "DEBUG_IterationEnd"
                    After = "Set_variable_3"
                    Step = "Iteration Complete"
                    Data = @{
                        ProcessedFolder = "@outputs('Get_current_Folder')"
                        TotalProcessed = "@variables('TotalFolders')"
                        RemainingQueue = "@length(variables('FoldersToProcess'))"
                    }
                }
            )

            foreach ($debug in $debugPoints) {
                if ($loopActions.PSObject.Properties.Name -contains $debug.After) {
                    # Check if debug action already exists
                    if (-not ($loopActions.PSObject.Properties.Name -contains $debug.Name)) {
                        $debugAction = Add-DebugAction -Name $debug.Name -Step $debug.Step -DebugData $debug.Data -RunAfter $debug.After
                        $loopActions | Add-Member -NotePropertyName $debug.Name -NotePropertyValue $debugAction -Force
                        $modifications += "Added debug action: $($debug.Name)"
                        Write-Host "Added: $($debug.Name) after $($debug.After)" -ForegroundColor Green
                    }
                }
            }
        }
    }

    # Update session name to indicate debug mode
    if ($actions.Add_a_new_row -and $actions.Add_a_new_row.inputs.parameters.'item/sp_name') {
        $originalName = $actions.Add_a_new_row.inputs.parameters.'item/sp_name'
        if ($originalName -notmatch 'DEBUG') {
            $actions.Add_a_new_row.inputs.parameters.'item/sp_name' = "DEBUG $originalName"
            $modifications += "Added DEBUG prefix to scan session name"
            Write-Host "Modified: Added DEBUG prefix to session name" -ForegroundColor Green
        }
    }

    # Convert back to JSON and save
    $outputJson = $flow | ConvertTo-Json -Depth 100 -Compress:$false
    $outputJson | Out-File $OutputFile -Encoding UTF8

    Write-Host ""
    Write-Host "=== Modifications Summary ===" -ForegroundColor Cyan
    foreach ($mod in $modifications) {
        Write-Host "  - $mod" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Debug flow created successfully!" -ForegroundColor Green
    Write-Host "Output: $OutputFile" -ForegroundColor Cyan

} catch {
    Write-Error "Failed to modify flow: $_"
    exit 1
}
