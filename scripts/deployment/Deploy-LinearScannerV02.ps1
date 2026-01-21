<#
.SYNOPSIS
    Deploys the Linear Permission Scanner V02 flow to Power Platform.

.DESCRIPTION
    This script:
    1. Creates a new solution package with the LinearPermissionScannerV02 workflow
    2. Uses $batch API for bulk reset of broken permissions
    3. Deploys the solution using PAC CLI

.PARAMETER SkipDeploy
    If specified, creates the solution but doesn't deploy it.

.EXAMPLE
    .\Deploy-LinearScannerV02.ps1

.EXAMPLE
    .\Deploy-LinearScannerV02.ps1 -SkipDeploy

.NOTES
    Author: Power Platform DevOps
    Version: 1.0
    Requires: PAC CLI installed and authenticated
#>

param(
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot
$sourceWorkflow = "Z:\power automate\Recursive Permission ScannerV.01\solution\export\extracted\Workflows\LinearPermissionScannerV02.json"
$tempFolder = Join-Path $scriptRoot "..\solution\linear_scanner_v02_build"
$outputZip = Join-Path $scriptRoot "..\solution\LinearPermissionScannerV02.zip"

# Generate a new GUID for the workflow
$workflowGuid = [guid]::NewGuid().ToString().ToUpper()
$workflowGuidBraces = "{$($workflowGuid.ToLower())}"

# Banner
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "|     Linear Permission Scanner V02 - Deployment Script        |" -ForegroundColor Cyan
Write-Host "|     (Optimized: $batch API, No Dataverse)                    |" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Validate source workflow
Write-Host "Step 1: Validating source workflow..." -ForegroundColor Cyan
if (-not (Test-Path $sourceWorkflow)) {
    Write-Error "Source workflow not found: $sourceWorkflow"
    exit 1
}
Write-Host "  [OK] Source workflow found" -ForegroundColor Green
Write-Host "  Workflow GUID: $workflowGuid" -ForegroundColor Gray

# Step 2: Clean and create temp folder
Write-Host ""
Write-Host "Step 2: Preparing build folder..." -ForegroundColor Cyan
if (Test-Path $tempFolder) {
    Remove-Item $tempFolder -Recurse -Force
}
New-Item $tempFolder -ItemType Directory | Out-Null
New-Item (Join-Path $tempFolder "Workflows") -ItemType Directory | Out-Null
Write-Host "  [OK] Build folder created" -ForegroundColor Green

# Step 3: Copy and rename workflow file
Write-Host ""
Write-Host "Step 3: Preparing workflow file..." -ForegroundColor Cyan
$workflowFileName = "LinearPermissionScannerV02-$workflowGuid.json"
$destWorkflow = Join-Path $tempFolder "Workflows\$workflowFileName"
Copy-Item $sourceWorkflow $destWorkflow
Write-Host "  [OK] Workflow copied: $workflowFileName" -ForegroundColor Green

# Step 4: Create solution.xml
Write-Host ""
Write-Host "Step 4: Creating solution.xml..." -ForegroundColor Cyan

$solutionXml = @"
<?xml version="1.0" encoding="utf-8"?>
<ImportExportXml version="9.2.25113.161" SolutionPackageVersion="9.2" languagecode="1033" generatedBy="CrmLive" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" OrganizationVersion="9.2.25113.161" OrganizationSchemaType="Full" CRMServerServiceabilityVersion="9.2.25113.00161">
  <SolutionManifest>
    <UniqueName>LinearPermissionScannerV02</UniqueName>
    <LocalizedNames>
      <LocalizedName description="Linear Permission Scanner V02" languagecode="1033" />
    </LocalizedNames>
    <Descriptions>
      <Description description="Scans and resets SharePoint folder broken permissions using batch API - optimized linear approach" languagecode="1033" />
    </Descriptions>
    <Version>1.0</Version>
    <Managed>0</Managed>
    <Publisher>
      <UniqueName>SPScanner</UniqueName>
      <LocalizedNames>
        <LocalizedName description="SPScanner" languagecode="1033" />
      </LocalizedNames>
      <Descriptions>
        <Description description="SPScanner" languagecode="1033" />
      </Descriptions>
      <EMailAddress xsi:nil="true"></EMailAddress>
      <SupportingWebsiteUrl xsi:nil="true"></SupportingWebsiteUrl>
      <CustomizationPrefix>sp</CustomizationPrefix>
      <CustomizationOptionValuePrefix>26592</CustomizationOptionValuePrefix>
      <Addresses>
        <Address>
          <AddressNumber>1</AddressNumber>
          <AddressTypeCode>1</AddressTypeCode>
          <City xsi:nil="true"></City>
          <County xsi:nil="true"></County>
          <Country xsi:nil="true"></Country>
          <Fax xsi:nil="true"></Fax>
          <FreightTermsCode xsi:nil="true"></FreightTermsCode>
          <ImportSequenceNumber xsi:nil="true"></ImportSequenceNumber>
          <Latitude xsi:nil="true"></Latitude>
          <Line1 xsi:nil="true"></Line1>
          <Line2 xsi:nil="true"></Line2>
          <Line3 xsi:nil="true"></Line3>
          <Longitude xsi:nil="true"></Longitude>
          <Name xsi:nil="true"></Name>
          <PostalCode xsi:nil="true"></PostalCode>
          <PostOfficeBox xsi:nil="true"></PostOfficeBox>
          <PrimaryContactName xsi:nil="true"></PrimaryContactName>
          <ShippingMethodCode>1</ShippingMethodCode>
          <StateOrProvince xsi:nil="true"></StateOrProvince>
          <Telephone1 xsi:nil="true"></Telephone1>
          <Telephone2 xsi:nil="true"></Telephone2>
          <Telephone3 xsi:nil="true"></Telephone3>
          <TimeZoneRuleVersionNumber xsi:nil="true"></TimeZoneRuleVersionNumber>
          <UPSZone xsi:nil="true"></UPSZone>
          <UTCOffset xsi:nil="true"></UTCOffset>
          <UTCConversionTimeZoneCode xsi:nil="true"></UTCConversionTimeZoneCode>
        </Address>
        <Address>
          <AddressNumber>2</AddressNumber>
          <AddressTypeCode>1</AddressTypeCode>
          <City xsi:nil="true"></City>
          <County xsi:nil="true"></County>
          <Country xsi:nil="true"></Country>
          <Fax xsi:nil="true"></Fax>
          <FreightTermsCode xsi:nil="true"></FreightTermsCode>
          <ImportSequenceNumber xsi:nil="true"></ImportSequenceNumber>
          <Latitude xsi:nil="true"></Latitude>
          <Line1 xsi:nil="true"></Line1>
          <Line2 xsi:nil="true"></Line2>
          <Line3 xsi:nil="true"></Line3>
          <Longitude xsi:nil="true"></Longitude>
          <Name xsi:nil="true"></Name>
          <PostalCode xsi:nil="true"></PostalCode>
          <PostOfficeBox xsi:nil="true"></PostOfficeBox>
          <PrimaryContactName xsi:nil="true"></PrimaryContactName>
          <ShippingMethodCode>1</ShippingMethodCode>
          <StateOrProvince xsi:nil="true"></StateOrProvince>
          <Telephone1 xsi:nil="true"></Telephone1>
          <Telephone2 xsi:nil="true"></Telephone2>
          <Telephone3 xsi:nil="true"></Telephone3>
          <TimeZoneRuleVersionNumber xsi:nil="true"></TimeZoneRuleVersionNumber>
          <UPSZone xsi:nil="true"></UPSZone>
          <UTCOffset xsi:nil="true"></UTCOffset>
          <UTCConversionTimeZoneCode xsi:nil="true"></UTCConversionTimeZoneCode>
        </Address>
      </Addresses>
    </Publisher>
    <RootComponents>
      <RootComponent type="29" id="$workflowGuidBraces" behavior="0" />
    </RootComponents>
    <MissingDependencies />
  </SolutionManifest>
</ImportExportXml>
"@

$solutionXml | Out-File (Join-Path $tempFolder "solution.xml") -Encoding UTF8
Write-Host "  [OK] solution.xml created" -ForegroundColor Green

# Step 5: Create customizations.xml
Write-Host ""
Write-Host "Step 5: Creating customizations.xml..." -ForegroundColor Cyan

$customizationsXml = @"
<?xml version="1.0" encoding="utf-8"?>
<ImportExportXml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" OrganizationVersion="9.2.25113.161" OrganizationSchemaType="Full" CRMServerServiceabilityVersion="9.2.25113.00161">
  <Entities></Entities>
  <Roles></Roles>
  <Workflows>
    <Workflow WorkflowId="$workflowGuidBraces" Name="Linear Permission Scanner V02">
      <JsonFileName>/Workflows/$workflowFileName</JsonFileName>
      <Type>1</Type>
      <Subprocess>0</Subprocess>
      <Category>5</Category>
      <Mode>0</Mode>
      <Scope>4</Scope>
      <OnDemand>0</OnDemand>
      <TriggerOnCreate>0</TriggerOnCreate>
      <TriggerOnDelete>0</TriggerOnDelete>
      <AsyncAutodelete>0</AsyncAutodelete>
      <SyncWorkflowLogOnFailure>0</SyncWorkflowLogOnFailure>
      <StateCode>1</StateCode>
      <StatusCode>2</StatusCode>
      <RunAs>1</RunAs>
      <IsTransacted>1</IsTransacted>
      <IntroducedVersion>1.0</IntroducedVersion>
      <IsCustomizable>1</IsCustomizable>
      <BusinessProcessType>0</BusinessProcessType>
      <IsCustomProcessingStepAllowedForOtherPublishers>1</IsCustomProcessingStepAllowedForOtherPublishers>
      <ModernFlowType>0</ModernFlowType>
      <PrimaryEntity>none</PrimaryEntity>
      <LocalizedNames>
        <LocalizedName languagecode="1033" description="Linear Permission Scanner V02" />
      </LocalizedNames>
    </Workflow>
  </Workflows>
  <FieldSecurityProfiles></FieldSecurityProfiles>
  <Templates />
  <EntityMaps />
  <EntityRelationships />
  <OrganizationSettings />
  <optionsets />
  <CustomControls />
  <EntityDataProviders />
  <connectionreferences>
    <connectionreference connectionreferencelogicalname="sp_sharedsharepointonline_e7162">
      <connectionreferencedisplayname>SharePoint SharePointPermissionScanner-e7162</connectionreferencedisplayname>
      <connectorid>/providers/Microsoft.PowerApps/apis/shared_sharepointonline</connectorid>
      <iscustomizable>1</iscustomizable>
      <promptingbehavior>0</promptingbehavior>
      <statecode>0</statecode>
      <statuscode>1</statuscode>
    </connectionreference>
  </connectionreferences>
  <Languages>
    <Language>1033</Language>
  </Languages>
</ImportExportXml>
"@

$customizationsXml | Out-File (Join-Path $tempFolder "customizations.xml") -Encoding UTF8
Write-Host "  [OK] customizations.xml created" -ForegroundColor Green

# Step 6: Create [Content_Types].xml
Write-Host ""
Write-Host "Step 6: Creating [Content_Types].xml..." -ForegroundColor Cyan

$contentTypesXml = @"
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="xml" ContentType="application/octet-stream" />
  <Default Extension="json" ContentType="application/octet-stream" />
</Types>
"@

# Use .NET to write the file because Out-File doesn't handle brackets well
$contentTypesPath = Join-Path $tempFolder "[Content_Types].xml"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($contentTypesPath, $contentTypesXml, $utf8NoBom)
Write-Host "  [OK] [Content_Types].xml created" -ForegroundColor Green

# Step 7: Package solution
Write-Host ""
Write-Host "Step 7: Packaging solution..." -ForegroundColor Cyan

# Remove old zip
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

# Create zip - load required assemblies
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::Open($outputZip, [System.IO.Compression.ZipArchiveMode]::Create)

# Add solution files
$filesToAdd = @(
    @{ Source = "solution.xml"; Entry = "solution.xml" },
    @{ Source = "customizations.xml"; Entry = "customizations.xml" },
    @{ Source = "[Content_Types].xml"; Entry = "[Content_Types].xml" },
    @{ Source = "Workflows\$workflowFileName"; Entry = "Workflows/$workflowFileName" }
)

foreach ($file in $filesToAdd) {
    $sourcePath = Join-Path $tempFolder $file.Source
    if (Test-Path -LiteralPath $sourcePath) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $sourcePath, $file.Entry) | Out-Null
        Write-Host "  [OK] Added: $($file.Entry)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Not found: $($file.Source)" -ForegroundColor Yellow
    }
}

$zip.Dispose()
Write-Host "  [OK] Solution packaged: $outputZip" -ForegroundColor Green

# Step 8: Cleanup temp folder
Write-Host ""
Write-Host "Step 8: Cleaning up..." -ForegroundColor Cyan
Remove-Item $tempFolder -Recurse -Force
Write-Host "  [OK] Temp files removed" -ForegroundColor Green

# Step 9: Deploy
if (-not $SkipDeploy) {
    Write-Host ""
    Write-Host "Step 9: Deploying to Power Platform..." -ForegroundColor Cyan

    # Check PAC CLI
    $pacPath = Get-Command pac -ErrorAction SilentlyContinue
    if (-not $pacPath) {
        Write-Host "  [WARN] PAC CLI not found. Please deploy manually." -ForegroundColor Yellow
        Write-Host "  Solution package: $outputZip" -ForegroundColor Gray
    } else {
        # Check authentication
        Write-Host "  Checking authentication..." -ForegroundColor Gray
        $authResult = & pac auth list 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [WARN] PAC CLI not authenticated. Run 'pac auth create' first." -ForegroundColor Yellow
        } else {
            Write-Host "  Importing solution..." -ForegroundColor Gray
            $deployResult = & pac solution import --path $outputZip --async false 2>&1
            $deployExitCode = $LASTEXITCODE

            if ($deployExitCode -ne 0) {
                Write-Host ""
                Write-Host "  [FAIL] Deployment failed:" -ForegroundColor Red
                Write-Host $deployResult -ForegroundColor Red
            } else {
                Write-Host $deployResult -ForegroundColor Green
                Write-Host "  [OK] Solution deployed successfully" -ForegroundColor Green
            }
        }
    }
}

# Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "|                    Deployment Complete!                       |" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Solution Package: $outputZip" -ForegroundColor Cyan
Write-Host "Workflow GUID: $workflowGuid" -ForegroundColor Cyan
Write-Host ""
Write-Host "Flow Features:" -ForegroundColor Yellow
Write-Host "  - Single GET query for all folders with HasUniqueRoleAssignments" -ForegroundColor Gray
Write-Host "  - In-memory filtering (Filter Array)" -ForegroundColor Gray
Write-Host "  - Single `$batch request to reset ALL broken permissions" -ForegroundColor Gray
Write-Host "  - No Dataverse dependency (SharePoint only)" -ForegroundColor Gray
Write-Host "  - Only 2 API calls total" -ForegroundColor Gray
Write-Host ""
Write-Host "To Test:" -ForegroundColor Yellow
Write-Host "  1. Open: https://make.powerautomate.com" -ForegroundColor Gray
Write-Host "  2. Go to Solutions > Linear Permission Scanner V02" -ForegroundColor Gray
Write-Host "  3. Open the flow and click 'Test' > 'Manually'" -ForegroundColor Gray
Write-Host "  4. Enter parameters:" -ForegroundColor Gray
Write-Host "     SiteUrl: https://yourtenant.sharepoint.com/sites/YourSite" -ForegroundColor DarkGray
Write-Host "     LibraryName: Shared Documents" -ForegroundColor DarkGray
Write-Host "     RootFolderPath: /sites/YourSite/Shared Documents/FolderToScan" -ForegroundColor DarkGray
Write-Host ""
