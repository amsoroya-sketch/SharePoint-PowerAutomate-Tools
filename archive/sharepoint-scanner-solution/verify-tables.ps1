# Verify Dataverse tables
$token = az account get-access-token --resource https://org3a2a4fe5.crm6.dynamics.com --query accessToken -o tsv
$headers = @{
    "Authorization" = "Bearer $token"
    "OData-MaxVersion" = "4.0"
    "OData-Version" = "4.0"
}

$baseUrl = "https://org3a2a4fe5.crm6.dynamics.com/api/data/v9.2"

Write-Host "Verifying Dataverse tables..." -ForegroundColor Cyan

$entities = (Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions" -Headers $headers).value |
    Where-Object { $_.SchemaName -like 'sp_*' } |
    Select-Object SchemaName, EntitySetName, @{N='DisplayName';E={$_.DisplayName.UserLocalizedLabel.Label}}

Write-Host "`nTables found:" -ForegroundColor Green
$entities | Format-Table -AutoSize

# Check record counts
Write-Host "`nRecord counts:" -ForegroundColor Yellow
foreach ($entity in $entities) {
    try {
        $count = (Invoke-RestMethod -Uri "$baseUrl/$($entity.EntitySetName)?\$count=true" -Headers $headers).value.Count
        Write-Host "  $($entity.SchemaName): $count records"
    } catch {
        Write-Host "  $($entity.SchemaName): 0 records (empty)"
    }
}
