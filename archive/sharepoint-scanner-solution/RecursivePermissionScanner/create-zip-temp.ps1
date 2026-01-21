Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$srcDir = "extracted_check6_fix"
$zipPath = "check6_trycatch.zip"

if (Test-Path $zipPath) { Remove-Item $zipPath }

$zipStream = [System.IO.File]::Create($zipPath)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

Get-ChildItem -Path $srcDir -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring((Get-Item $srcDir).FullName.Length + 1)
    $entryName = $relativePath.Replace('\', '/')

    Write-Host "Adding: $entryName"
    $entry = $archive.CreateEntry($entryName)
    $fileStream = [System.IO.File]::OpenRead($_.FullName)
    $entryStream = $entry.Open()
    $fileStream.CopyTo($entryStream)
    $entryStream.Close()
    $fileStream.Close()
}

$archive.Dispose()
$zipStream.Close()

Write-Host "Created: $zipPath"
