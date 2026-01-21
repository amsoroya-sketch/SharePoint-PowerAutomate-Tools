$sourceFolder = "Z:\projects\sharepoint-scanner\solution\current_extracted"
$outputZip = "Z:\projects\sharepoint-scanner\solution\SharePointPermissionScanner_HARDCODED.zip"

Write-Host "Packaging solution..."
Write-Host "Source: $sourceFolder"
Write-Host "Output: $outputZip"
Write-Host ""

# Remove old zip if exists
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
    Write-Host "Removed existing zip"
}

# Use Compress-Archive
Compress-Archive -Path "$sourceFolder\*" -DestinationPath $outputZip -Force

Write-Host ""
Write-Host "Solution packaged successfully!" -ForegroundColor Green
Write-Host "Output: $outputZip"

# List contents
Write-Host ""
Write-Host "Contents:"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipContents = [System.IO.Compression.ZipFile]::OpenRead($outputZip)
$zipContents.Entries | ForEach-Object { Write-Host "  $_" }
$zipContents.Dispose()
