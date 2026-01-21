# SharePoint & Power Automate Tools

**Centralized repository for SharePoint Permission Scanner and Power Automate workflow tools**

---

## 📁 Directory Structure

```
SharePoint-PowerAutomate-Tools/
├── deployed-flows/          # Production-ready deployed flows
├── scripts/                 # PowerShell automation scripts
│   ├── sharepoint-queries/  # SharePoint REST API & Graph queries
│   ├── test-data/          # Test folder structure creation
│   ├── deployment/         # Flow deployment automation
│   ├── testing/            # Testing & validation scripts
│   └── dataverse/          # Dataverse query scripts
├── solutions/              # Power Platform solution packages
└── documentation/          # Project documentation
```

---

## 🚀 Quick Start

### Prerequisites

1. **PowerShell 7+** installed
2. **PAC CLI** (Power Platform CLI) authenticated
3. **Azure AD App Registration** with SharePoint permissions
4. **Environment variables** configured in `Z:\.env`:
   ```
   SHAREPOINT_TENANT_ID=<your-tenant-id>
   SHAREPOINT_CLIENT_ID=<your-client-id>
   SHAREPOINT_CLIENT_SECRET=<your-client-secret>
   ```

### Typical Workflow

```powershell
# 1. Create test environment
cd scripts/test-data
.\Create-TestFolders.ps1

# 2. Verify SharePoint structure
cd ../sharepoint-queries
.\Get-SharePointFolders.ps1 -ListOnly

# 3. Deploy flow
cd ../deployment
.\Deploy-LinearScannerV02.ps1

# 4. Test the flow
cd ../testing
.\Test-RecursiveScanner.ps1

# 5. Check results
cd ../dataverse
.\Get-ScanResults.ps1 -Latest -ShowFolders
```

---

## 📂 Scripts Reference

### SharePoint Queries (`scripts/sharepoint-queries/`)

#### **Get-SharePointFolders.ps1**
Query SharePoint for folders with broken permissions using REST API.

**Usage:**
```powershell
.\Get-SharePointFolders.ps1 -SiteURL "https://tenant.sharepoint.com/sites/test" `
                            -LibraryName "Shared Documents" `
                            -BasePath "/sites/test/Shared Documents"
```

**Parameters:**
- `-SiteURL`: SharePoint site URL
- `-LibraryName`: Document library name
- `-BasePath`: Server-relative path filter
- `-ListOnly`: List all folders (not just broken permissions)
- `-ShowStructure`: Display folder hierarchy

**Output:**
- Folder paths with broken inheritance
- Permission status
- Child counts
- Folder levels

---

#### **Get-SharePointFolders-Graph.ps1**
Alternative approach using Microsoft Graph API.

**Usage:**
```powershell
.\Get-SharePointFolders-Graph.ps1 -SiteURL "https://tenant.sharepoint.com/sites/test" `
                                  -LibraryName "Documents"
```

**Advantages:**
- Cross-platform compatibility
- Better for modern auth scenarios
- Includes permission inheritance details

---

### Test Data Creation (`scripts/test-data/`)

#### **Create-TestFolders.ps1**
Creates standardized test folder structure with configurable broken permissions.

**Usage:**
```powershell
# Create test folders
.\Create-TestFolders.ps1

# Clean up test folders
.\Create-TestFolders.ps1 -CleanUp
```

**Test Structure Created:**
```
/Documents
  ├── TestFolder1 [UNIQUE PERMISSIONS]
  ├── TestFolder2
  │   ├── SubFolder2a [UNIQUE PERMISSIONS]
  │   └── SubFolder2b
  ├── TestFolder3
  │   └── Level2
  │       └── Level3 [UNIQUE PERMISSIONS]
  ├── HR
  │   ├── Policies [UNIQUE PERMISSIONS]
  │   └── Employees
  └── Projects
      ├── Project-Alpha
      └── Project-Beta [UNIQUE PERMISSIONS]
```

**Expected Results:**
- Total Folders: 13
- Folders with Broken Permissions: 5

---

### Deployment Scripts (`scripts/deployment/`)

#### **Deploy-LinearScannerV02.ps1**
Deploys the Linear Permission Scanner V02 flow.

**Usage:**
```powershell
.\Deploy-LinearScannerV02.ps1
.\Deploy-LinearScannerV02.ps1 -TestAfterDeploy
```

**Process:**
1. Creates solution package
2. Generates unique workflow GUID
3. Packages as .zip
4. Deploys using PAC CLI
5. Optionally runs test

---

#### **Deploy-RecursiveScanner.ps1**
Deploys the Recursive Permission Scanner flow.

**Usage:**
```powershell
.\Deploy-RecursiveScanner.ps1
.\Deploy-RecursiveScanner.ps1 -SkipDeploy  # Package only, no deployment
```

---

#### **Pack-Solution.ps1**
Packages flows into Power Platform solution format.

**Usage:**
```powershell
.\Pack-Solution.ps1 -WorkflowPath "../solutions/workflows/MyFlow.json"
```

---

### Testing Scripts (`scripts/testing/`)

#### **Test-RecursiveScanner.ps1**
Opens Power Automate portal with test guidance and expected results.

**Usage:**
```powershell
.\Test-RecursiveScanner.ps1
```

**Test Parameters Provided:**
- SiteURL
- LibraryName
- BaseLibraryPath
- MinimumLevel
- DryRun flag

**Expected Results:**
- Total Folders: ~13
- Broken Permissions: 5 folders

---

#### **Test-BrokenPermissionsFlow.ps1**
Provides test scenarios and OData query validation.

**Usage:**
```powershell
# List all scenarios
.\Test-BrokenPermissionsFlow.ps1 -Scenario List

# Test query generation
.\Test-BrokenPermissionsFlow.ps1 -Scenario TestQuery -SiteURL "https://..." -LibraryName "Documents"

# Show flow details
.\Test-BrokenPermissionsFlow.ps1 -Scenario ShowFlow
```

**Test Scenarios:**
1. Scan entire library (finds all 5 broken folders)
2. Scan specific folder (/Projects - finds 1)
3. Root level only
4. Up to level 2

---

#### **Add-FlowDebug.ps1**
Adds debug actions to flows for troubleshooting.

**Usage:**
```powershell
.\Add-FlowDebug.ps1 -FlowPath "../solutions/workflows/MyFlow.json"
```

---

#### **Run-FlowQuery.ps1**
Executes custom queries against Power Automate flows.

**Usage:**
```powershell
.\Run-FlowQuery.ps1 -Query "SELECT * FROM workflows WHERE name LIKE '%Scanner%'"
```

---

### Dataverse Scripts (`scripts/dataverse/`)

#### **Get-ScanResults.ps1**
Retrieves scan session results from Dataverse tables.

**Usage:**
```powershell
# Get latest session
.\Get-ScanResults.ps1 -Latest

# Get specific session with details
.\Get-ScanResults.ps1 -SessionId "guid-here" -ShowFolders -ShowPermissions

# Raw output
.\Get-ScanResults.ps1 -Latest -Raw
```

**Queries:**
- `sp_scansession` - Scan session metadata
- `sp_folderrecord` - Folder details
- `sp_permissionentry` - Permission entries

**Status Codes:**
- `100000000` = Completed
- `100000001` = Running
- `100000002` = Failed

---

#### **Get-Flow.ps1**
Retrieves flow metadata from Power Platform.

**Usage:**
```powershell
.\Get-Flow.ps1 -Name "Permission Scanner"
```

---

## 🔧 Deployed Flows

### LinearPermissionScannerV02_1_1
**Location:** `deployed-flows/LinearPermissionScannerV02_1_1/`

**Version:** 1.1
**Status:** Production
**Deployed:** 2026-01-21

**Features:**
- Two-step scanning approach (all folders → filter broken permissions)
- Efficient for large document libraries
- Dataverse integration for result storage
- Configurable folder level filtering

**Flow Definition:**
- `Workflows/LinearPermissionScanner-*.json` - Main workflow
- `solution.xml` - Solution manifest
- `customizations.xml` - Flow metadata

**Test Site:**
- URL: `https://abctest179.sharepoint.com/sites/Permission-Scanner-Test`
- Library: `Shared Documents`
- Path: `/sites/Permission-Scanner-Test/Shared Documents`

---

## 📊 Solution Packages

### sharepoint-scanner-solution
**Location:** `solutions/sharepoint-scanner-solution/`

Contains all solution artifacts:
- Workflow JSON definitions
- Solution XML files
- Build artifacts
- Extracted solution packages

**Key Directories:**
- `workflows/` - Flow definitions
- `current_extracted/` - Latest extracted solution
- `RecursivePermissionScanner/` - Recursive scanner build
- `src/` - Source solution files

---

## 🔐 Security Requirements

### Azure AD App Registration

**API Permissions Required:**
- SharePoint: `Sites.Read.All` (Application)
- Microsoft Graph: `Sites.Read.All` (Application)
- Dataverse: `user_impersonation` (Delegated)

**Admin Consent:** Required

### Service Principal Setup

```powershell
# Register app
az ad app create --display-name "SharePoint Scanner" `
                 --available-to-other-tenants false

# Add permissions
az ad app permission add --id <app-id> `
                         --api 00000003-0000-0ff1-ce00-000000000000 `
                         --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Role

# Grant admin consent
az ad app permission admin-consent --id <app-id>
```

---

## 📝 Environment Configuration

Create `.env` file at `Z:\.env`:

```env
# Azure AD Authentication
SHAREPOINT_TENANT_ID=12345678-1234-1234-1234-123456789abc
SHAREPOINT_CLIENT_ID=87654321-4321-4321-4321-cba987654321
SHAREPOINT_CLIENT_SECRET=your-client-secret-here

# Target Environment
SHAREPOINT_SITE_URL=https://abctest179.sharepoint.com/sites/Permission-Scanner-Test
SHAREPOINT_LIBRARY_NAME=Shared Documents
SHAREPOINT_BASE_PATH=/sites/Permission-Scanner-Test/Shared Documents

# Power Platform
DATAVERSE_ENVIRONMENT_URL=https://org12345678.crm.dynamics.com
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Authentication Failures
**Error:** `Authentication failed`

**Solutions:**
- Verify app registration has correct permissions
- Ensure admin consent is granted
- Check client secret hasn't expired
- Validate tenant ID is correct

---

#### 2. No Folders Found
**Error:** `No folders found matching criteria`

**Solutions:**
- Run with `-ListOnly` to verify library access
- Check base path is correct (server-relative path)
- Verify SharePoint permissions
- Ensure folders exist with broken permissions

---

#### 3. Deployment Failures
**Error:** `Solution import failed`

**Solutions:**
- Check PAC CLI authentication: `pac auth list`
- Verify you're connected to correct environment
- Review solution XML for GUID conflicts
- Check connection references exist

---

#### 4. Flow Not Triggering
**Error:** Flow runs but finds 0 folders

**Solutions:**
- Verify SharePoint connection is configured
- Check trigger parameters are correct
- Review flow run history for errors
- Test REST API query manually

---

## 📚 HTML Documentation (34 Guides)

### Browse Complete HTML Documentation
**Main Index:** `documentation/html-guides/index.html` - Open in browser

**Categories:**
- **Setup Guides** (17) - Complete setup for Power Platform and Azure services
  - Power Automate (3 guides)
  - Dataverse (2 guides)
  - SharePoint (2 guides)
  - Azure Services (7 guides)
  - Power Apps, Power BI, Teams, Functions, Key Vault, Graph API

- **CLI Tools Reference** (6) - Command-line tools documentation
  - PAC CLI, Azure CLI, M365 CLI, PnP PowerShell, Functions Core Tools

- **MCP Servers** (4) - Server configuration and APIs
  - SharePoint, Dataverse, Azure DevOps MCP servers

- **Skills** (3) - Custom skill development guides

- **Phase Guides** (2) - Implementation walkthrough
  - Phase 2: Broken Permissions Scanner
  - Phase 2B: Recursive Permission Scanner

**Quick Access:**
```bash
# Open main documentation index
xdg-open documentation/html-guides/index.html

# Or start local web server
cd documentation/html-guides
python3 -m http.server 8000
# Then browse to: http://localhost:8000
```

**Full HTML Documentation Index:** See `documentation/HTML_DOCUMENTATION_INDEX.md`

---

## 📚 Additional Resources

### Official Documentation
- [Power Automate Documentation](https://docs.microsoft.com/power-automate)
- [SharePoint REST API Reference](https://docs.microsoft.com/sharepoint/dev/sp-add-ins/get-to-know-the-sharepoint-rest-service)
- [Microsoft Graph API](https://docs.microsoft.com/graph)
- [PAC CLI Reference](https://docs.microsoft.com/power-platform/developer/cli/introduction)

### Related Projects
- Original project location: `/home/dev/Development/MSDev/power automate/sharepoint-scanner/`
- Solution artifacts: `solutions/sharepoint-scanner-solution/`

---

## 📅 Version History

### v1.1 (2026-01-21)
- Consolidated all scripts into organized structure
- Added LinearPermissionScannerV02_1_1 deployed flow
- Created comprehensive documentation
- Organized scripts by category (queries, testing, deployment)

### v1.0 (2026-01-14)
- Initial script collection
- Basic deployment automation
- Test folder creation utilities

---

## 🤝 Contributing

When adding new scripts:
1. Place in appropriate category folder
2. Follow naming convention: `Verb-Noun.ps1`
3. Include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
4. Update this README with script details
5. Test with dry-run parameters when possible

---

## 📄 License

Internal use only - Microsoft Development Tools

---

**Last Updated:** 2026-01-21
**Maintainer:** Development Team
**Location:** `/home/dev/Development/SharePoint-PowerAutomate-Tools/`
