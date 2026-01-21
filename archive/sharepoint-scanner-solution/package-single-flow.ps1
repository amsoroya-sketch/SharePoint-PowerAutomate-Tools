# Package solution with only the main SharePoint Permission Scanner flow
$sourceFolder = "Z:\projects\sharepoint-scanner\solution\current_extracted"
$outputZip = "Z:\projects\sharepoint-scanner\solution\SharePointPermissionScanner_HARDCODED.zip"
$tempFolder = "Z:\projects\sharepoint-scanner\solution\temp_package"

Write-Host "=== Packaging Solution (Single Flow) ===" -ForegroundColor Cyan
Write-Host ""

# Clean temp folder
if (Test-Path $tempFolder) {
    Remove-Item $tempFolder -Recurse -Force
}
New-Item $tempFolder -ItemType Directory | Out-Null
New-Item "$tempFolder\Workflows" -ItemType Directory | Out-Null

# Copy only the files we need
Copy-Item "$sourceFolder\solution.xml" $tempFolder
Copy-Item "$sourceFolder\customizations.xml" $tempFolder
Copy-Item -LiteralPath "$sourceFolder\[Content_Types].xml" $tempFolder

# Copy only the main scanner flow
Copy-Item "$sourceFolder\Workflows\SharePointPermissionScanner-17C3F8FE-0FEC-F011-8407-000D3AE1FF22.json" "$tempFolder\Workflows\"

Write-Host "Copied files:"
Get-ChildItem $tempFolder -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" }

# Now we need to update customizations.xml to only reference the one flow
$customizations = Get-Content "$tempFolder\customizations.xml" -Raw

# Check if the other flow is referenced
if ($customizations -match "61B559AC-12F0-F011-8407-000D3AE1FF22") {
    Write-Host ""
    Write-Host "Updating customizations.xml to remove reference to other flow..." -ForegroundColor Yellow
    # Remove the workflow reference for the other flow
    $customizations = $customizations -replace '(?s)<Workflow[^>]*WorkflowId="\{61B559AC-12F0-F011-8407-000D3AE1FF22\}"[^>]*>.*?</Workflow>', ''
    $customizations | Set-Content "$tempFolder\customizations.xml" -NoNewline
    Write-Host "Updated customizations.xml" -ForegroundColor Green
}

# Remove old zip
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

# Create zip
Write-Host ""
Write-Host "Creating solution zip..." -ForegroundColor Cyan
Compress-Archive -Path "$tempFolder\*" -DestinationPath $outputZip -Force

Write-Host ""
Write-Host "Solution packaged: $outputZip" -ForegroundColor Green

# Cleanup
Remove-Item $tempFolder -Recurse -Force
