<#
.SYNOPSIS
    Packs a Power Platform solution folder into a deployable .zip file.

.DESCRIPTION
    This script creates a properly structured Power Platform solution zip file
    from an extracted solution folder. It handles the [Content_Types].xml file
    correctly and ensures all files are at the root level of the zip.

.PARAMETER SourceFolder
    The path to the extracted solution folder containing solution.xml,
    customizations.xml, [Content_Types].xml, and Workflows folder.

.PARAMETER OutputZip
    The path where the output .zip file will be created.

.PARAMETER Force
    If specified, overwrites the output file if it already exists.

.EXAMPLE
    .\Pack-Solution.ps1 -SourceFolder ".\solution_extracted" -OutputZip ".\MySolution.zip"

.EXAMPLE
    .\Pack-Solution.ps1 -SourceFolder ".\solution_extracted" -OutputZip ".\MySolution.zip" -Force

.NOTES
    Author: Power Platform DevOps
    Version: 1.0
    Requires: PowerShell 5.1 or later
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceFolder,

    [Parameter(Mandatory=$true)]
    [string]$OutputZip,

    [switch]$Force
)

# Import required assemblies
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

# Validate source folder exists
if (-not (Test-Path $SourceFolder)) {
    Write-Error "Source folder not found: $SourceFolder"
    exit 1
}

# Check for required files
$requiredFiles = @('solution.xml', 'customizations.xml')
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $SourceFolder $file
    if (-not (Test-Path $filePath)) {
        Write-Error "Required file not found: $file"
        exit 1
    }
}

# Check for Content_Types.xml (may have bracket or renamed)
$contentTypesPath = $null
$contentTypesNames = @('[Content_Types].xml', 'Content_Types.xml', '_Content_Types_.xml')
foreach ($name in $contentTypesNames) {
    $testPath = Join-Path $SourceFolder $name
    if (Test-Path $testPath) {
        $contentTypesPath = $testPath
        break
    }
}

if (-not $contentTypesPath) {
    Write-Error "Content_Types.xml not found in any expected format"
    exit 1
}

# Handle existing output file
if (Test-Path $OutputZip) {
    if ($Force) {
        Remove-Item $OutputZip -Force
        Write-Host "Removed existing file: $OutputZip" -ForegroundColor Yellow
    } else {
        Write-Error "Output file already exists: $OutputZip. Use -Force to overwrite."
        exit 1
    }
}

Write-Host "=== Power Platform Solution Packager ===" -ForegroundColor Cyan
Write-Host "Source: $SourceFolder" -ForegroundColor Gray
Write-Host "Output: $OutputZip" -ForegroundColor Gray
Write-Host ""

try {
    # Create new zip file
    $zip = [System.IO.Compression.ZipFile]::Open($OutputZip, [System.IO.Compression.ZipArchiveMode]::Create)

    # Add Content_Types.xml with correct name
    Write-Host "Adding: [Content_Types].xml" -ForegroundColor Green
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $contentTypesPath, '[Content_Types].xml') | Out-Null

    # Add solution.xml
    $solutionPath = Join-Path $SourceFolder 'solution.xml'
    Write-Host "Adding: solution.xml" -ForegroundColor Green
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $solutionPath, 'solution.xml') | Out-Null

    # Add customizations.xml
    $customizationsPath = Join-Path $SourceFolder 'customizations.xml'
    Write-Host "Adding: customizations.xml" -ForegroundColor Green
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $customizationsPath, 'customizations.xml') | Out-Null

    # Add Workflows folder contents
    $workflowsPath = Join-Path $SourceFolder 'Workflows'
    if (Test-Path $workflowsPath) {
        $workflowFiles = Get-ChildItem $workflowsPath -File -Filter "*.json"
        foreach ($wf in $workflowFiles) {
            # Skip backup and debug files unless they are the main file
            if ($wf.Name -match '_BACKUP|_DEBUG|_FIXED' -and $wf.Name -notmatch '^[^_]+\.json$') {
                Write-Host "Skipping: Workflows/$($wf.Name)" -ForegroundColor DarkGray
                continue
            }

            $entryName = "Workflows/$($wf.Name)"
            Write-Host "Adding: $entryName" -ForegroundColor Green
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $wf.FullName, $entryName) | Out-Null
        }
    }

    # Add any other folders (e.g., Entities, WebResources, etc.)
    $otherFolders = @('Entities', 'WebResources', 'PluginAssemblies', 'Reports', 'Dashboards')
    foreach ($folder in $otherFolders) {
        $folderPath = Join-Path $SourceFolder $folder
        if (Test-Path $folderPath) {
            $files = Get-ChildItem $folderPath -File -Recurse
            foreach ($file in $files) {
                $relativePath = $file.FullName.Substring($SourceFolder.Length + 1)
                Write-Host "Adding: $relativePath" -ForegroundColor Green
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relativePath) | Out-Null
            }
        }
    }

    $zip.Dispose()

    Write-Host ""
    Write-Host "Solution packed successfully!" -ForegroundColor Green
    Write-Host "Output: $OutputZip" -ForegroundColor Cyan

    # Show zip contents
    Write-Host ""
    Write-Host "=== Zip Contents ===" -ForegroundColor Cyan
    $zipInfo = [System.IO.Compression.ZipFile]::OpenRead($OutputZip)
    foreach ($entry in $zipInfo.Entries) {
        Write-Host "  $($entry.FullName) ($($entry.Length) bytes)" -ForegroundColor Gray
    }
    $zipInfo.Dispose()

} catch {
    Write-Error "Failed to create solution package: $_"
    if ($zip) { $zip.Dispose() }
    exit 1
}
