const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Use the original zip as base and just replace the workflow file
const sourceDir = path.join(__dirname, 'validate_check_extracted');
const outputZip = path.join(__dirname, 'SharePointPermissionScanner_FIXED.zip');
const originalZip = path.join(__dirname, 'validate_check.zip');

// Copy original zip to new location
fs.copyFileSync(originalZip, outputZip);

// Now we need to update just the workflow file inside the zip
// Using PowerShell to update the specific entry

const workflowFile = path.join(sourceDir, 'Workflows', 'SharePointPermissionScanner-17C3F8FE-0FEC-F011-8407-000D3AE1FF22.json');
const workflowContent = fs.readFileSync(workflowFile, 'utf8');

// Write the workflow content to a temp file
const tempFile = path.join(__dirname, 'temp_workflow.json');
fs.writeFileSync(tempFile, workflowContent, 'utf8');

console.log('Copied original zip and prepared workflow file');
console.log('Now updating the workflow in the zip...');

// Use PowerShell to update the zip entry
const psScript = `
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = '${outputZip.replace(/\\/g, '\\\\')}'
$entryName = 'Workflows/SharePointPermissionScanner-17C3F8FE-0FEC-F011-8407-000D3AE1FF22.json'
$newContent = Get-Content -Path '${tempFile.replace(/\\/g, '\\\\')}' -Raw

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Update')
$entry = $zip.GetEntry($entryName)
if ($entry) {
    $entry.Delete()
}
$newEntry = $zip.CreateEntry($entryName)
$writer = New-Object System.IO.StreamWriter($newEntry.Open())
$writer.Write($newContent)
$writer.Close()
$zip.Dispose()
`;

fs.writeFileSync(path.join(__dirname, 'update_zip.ps1'), psScript, 'utf8');

try {
    execSync('powershell -ExecutionPolicy Bypass -File update_zip.ps1', {
        cwd: __dirname,
        stdio: 'inherit'
    });
    console.log('Successfully updated zip file!');
} catch (err) {
    console.error('Error updating zip:', err.message);
}

// Clean up temp files
try {
    fs.unlinkSync(tempFile);
    fs.unlinkSync(path.join(__dirname, 'update_zip.ps1'));
} catch (e) {}

console.log('Done! Output: SharePointPermissionScanner_FIXED.zip');
