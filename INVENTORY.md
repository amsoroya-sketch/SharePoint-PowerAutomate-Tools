# Asset Inventory - SharePoint & Power Automate Tools

**Location:** `/home/dev/Development/SharePoint-PowerAutomate-Tools/`
**Created:** 2026-01-21
**Last Updated:** 2026-01-21

---

## 📦 Complete Asset Listing

### 1. Deployed Flows

#### LinearPermissionScannerV02_1_1
**Path:** `deployed-flows/LinearPermissionScannerV02_1_1/`
**Type:** Power Automate Cloud Flow
**Version:** 1.1
**Status:** Production
**Size:** ~20 KB

**Contents:**
```
LinearPermissionScannerV02_1_1/
├── [Content_Types].xml     (258 bytes)  - MIME type definitions
├── customizations.xml      (2.2 KB)     - Flow metadata
├── solution.xml           (4.3 KB)     - Solution manifest
└── Workflows/
    └── LinearPermissionScanner-[GUID].json  - Main workflow definition
```

**Purpose:** Scans SharePoint document libraries for folders with broken permissions

**Test Environment:**
- Site: `https://abctest179.sharepoint.com/sites/Permission-Scanner-Test`
- Library: `Shared Documents`

---

### 2. PowerShell Scripts (14 total)

#### A. SharePoint Query Scripts (2 scripts)

**Location:** `scripts/sharepoint-queries/`

| Script | Size | Purpose | Auth Method |
|--------|------|---------|-------------|
| Get-SharePointFolders.ps1 | 6.4 KB | Query SharePoint REST API for folders | Azure AD v1/v2 |
| Get-SharePointFolders-Graph.ps1 | 7.4 KB | Query via Microsoft Graph API | Azure AD v2 |

**Total Category Size:** ~14 KB

---

#### B. Test Data Scripts (1 script)

**Location:** `scripts/test-data/`

| Script | Size | Purpose | Creates |
|--------|------|---------|---------|
| Create-TestFolders.ps1 | 12 KB | Create/delete test folder structure | 13 folders, 5 with unique permissions |

**Total Category Size:** ~12 KB

---

#### C. Deployment Scripts (5 scripts)

**Location:** `scripts/deployment/`

| Script | Size | Purpose | Output |
|--------|------|---------|--------|
| Deploy-LinearScannerV02.ps1 | 15 KB | Deploy Linear Scanner V02 | .zip solution |
| Deploy-RecursiveScanner.ps1 | 15 KB | Deploy Recursive Scanner | .zip solution |
| Deploy-DebugFlow.ps1 | 14 KB | Deploy debug flow version | .zip solution |
| Deploy-Solution.ps1 | 4.2 KB | Generic solution deployer | .zip solution |
| Pack-Solution.ps1 | 5.6 KB | Package flows as solution | .zip file |

**Total Category Size:** ~54 KB

---

#### D. Testing Scripts (4 scripts)

**Location:** `scripts/testing/`

| Script | Size | Purpose | Output |
|--------|------|---------|--------|
| Test-RecursiveScanner.ps1 | 5.1 KB | Open PA portal with test guidance | Browser window |
| Test-BrokenPermissionsFlow.ps1 | 7.0 KB | Validate test scenarios | OData queries |
| Add-FlowDebug.ps1 | 7.2 KB | Add debug actions to flows | Modified JSON |
| Run-FlowQuery.ps1 | 12 KB | Execute custom flow queries | Query results |

**Total Category Size:** ~31 KB

---

#### E. Dataverse Scripts (2 scripts)

**Location:** `scripts/dataverse/`

| Script | Size | Purpose | Queries |
|--------|------|---------|---------|
| Get-ScanResults.ps1 | 5.8 KB | Retrieve scan results from Dataverse | sp_scansession, sp_folderrecord, sp_permissionentry |
| Get-Flow.ps1 | 3.2 KB | Retrieve flow metadata | workflow table |

**Total Category Size:** ~9 KB

---

### 3. Solution Artifacts

**Location:** `solutions/sharepoint-scanner-solution/`

#### Directory Structure
```
sharepoint-scanner-solution/
├── workflows/                          - Flow JSON definitions
├── current_extracted/                  - Latest solution extraction
├── RecursivePermissionScanner/         - Recursive scanner build
├── SharePointPermissionScanner_extracted/
├── SharePointPermissionScanner_updated_extracted/
├── review3_extracted/
├── validate_check_extracted/
├── updated_extracted/
├── temp_check/
├── debug_simple/
├── debug_temp/
└── src/
    └── Other/
        ├── Customizations.xml
        ├── Relationships.xml
        └── Solution.xml
```

**Total Size:** ~2.5 MB (includes multiple solution versions)

**Key Files:**
- Solution XML manifests
- Workflow JSON definitions
- Connection reference configurations
- Entity definitions

---

### 4. Documentation (3 files)

**Location:** `documentation/` and root

| File | Size | Purpose |
|------|------|---------|
| README.md | 15 KB | Complete project documentation |
| QUICK_START.md | 6 KB | 5-minute setup guide |
| INVENTORY.md | This file | Asset inventory and manifest |

**Total Size:** ~21 KB

---

## 📊 Statistics Summary

### By File Type
- **PowerShell Scripts:** 14 files (~120 KB)
- **Flow Definitions:** 1 production flow (~20 KB)
- **Solution Packages:** Multiple versions (~2.5 MB)
- **Documentation:** 3 files (~21 KB)
- **XML Configurations:** ~15 files

### By Category
- **SharePoint Queries:** 2 scripts
- **Test Data:** 1 script
- **Deployment:** 5 scripts
- **Testing:** 4 scripts
- **Dataverse:** 2 scripts

### Total Assets
- **Scripts:** 14 PowerShell automation scripts
- **Flows:** 1 deployed production flow
- **Solutions:** 10+ solution package versions
- **Docs:** 3 comprehensive documentation files

---

## 🔑 Key Assets by Use Case

### For Development
```
scripts/sharepoint-queries/Get-SharePointFolders.ps1
scripts/test-data/Create-TestFolders.ps1
scripts/testing/Test-BrokenPermissionsFlow.ps1
```

### For Deployment
```
scripts/deployment/Deploy-LinearScannerV02.ps1
scripts/deployment/Pack-Solution.ps1
deployed-flows/LinearPermissionScannerV02_1_1/
```

### For Testing
```
scripts/testing/Test-RecursiveScanner.ps1
scripts/testing/Add-FlowDebug.ps1
scripts/dataverse/Get-ScanResults.ps1
```

### For Troubleshooting
```
scripts/sharepoint-queries/Get-SharePointFolders-Graph.ps1
scripts/testing/Run-FlowQuery.ps1
scripts/dataverse/Get-Flow.ps1
```

---

## 📁 Source Locations

All assets consolidated from:
- **Original:** `/home/dev/Development/MSDev/power automate/sharepoint-scanner/`
- **Solution:** `/home/dev/Development/MSDev/power automate/solution/`
- **New Location:** `/home/dev/Development/SharePoint-PowerAutomate-Tools/`

---

## 🔄 Version Control

### Script Versions
All scripts are PowerShell 7+ compatible and include:
- Comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
- Parameter validation
- Error handling
- Verbose output options

### Flow Versions
- **LinearPermissionScannerV02_1_1** (Current Production)
  - Date: 2026-01-21
  - Two-step scanning approach
  - Dataverse integration
  - Level filtering support

### Solution Versions
Multiple solution packages available:
- Production: `LinearPermissionScannerV02_1_1`
- Debug: `debug_simple/`, `debug_temp/`
- Review: `review3_extracted/`
- Validation: `validate_check_extracted/`

---

## 🔐 Security Assets

### Required Credentials
Stored in: `Z:\.env`

```env
SHAREPOINT_TENANT_ID=<tenant-guid>
SHAREPOINT_CLIENT_ID=<app-client-id>
SHAREPOINT_CLIENT_SECRET=<secret-value>
```

### Azure AD App Requirements
- **App Registration Name:** SharePoint Scanner
- **Permissions:**
  - SharePoint: `Sites.Read.All` (Application)
  - Microsoft Graph: `Sites.Read.All` (Application)
  - Dataverse: `user_impersonation` (Delegated)
- **Admin Consent:** Required

---

## 🔧 Dependencies

### External Tools Required
1. PowerShell 7+
2. PAC CLI (Power Platform CLI)
3. Azure CLI (optional, for app registration)
4. Modern web browser (for Power Automate portal)

### PowerShell Modules
- No external modules required (uses built-in cmdlets)
- All authentication via REST API calls

### Cloud Services
- SharePoint Online
- Power Automate
- Microsoft Dataverse
- Azure AD

---

## 📈 Usage Metrics

### Test Site Details
- **Site URL:** `https://abctest179.sharepoint.com/sites/Permission-Scanner-Test`
- **Library:** `Shared Documents`
- **Test Folders:** 13 folders created by `Create-TestFolders.ps1`
- **Broken Permissions:** 5 test folders with unique permissions

### Expected Scan Results
- **Total Folders Scanned:** ~13
- **Folders with Broken Permissions:** 5
- **Scan Duration:** ~2-5 minutes (depending on library size)
- **Dataverse Records Created:** 1 scan session + 5 folder records

---

## 🗂️ File Manifest

### Complete File List (47 assets)

#### Scripts (14)
1. Get-SharePointFolders.ps1
2. Get-SharePointFolders-Graph.ps1
3. Create-TestFolders.ps1
4. Deploy-LinearScannerV02.ps1
5. Deploy-RecursiveScanner.ps1
6. Deploy-DebugFlow.ps1
7. Deploy-Solution.ps1
8. Pack-Solution.ps1
9. Test-RecursiveScanner.ps1
10. Test-BrokenPermissionsFlow.ps1
11. Add-FlowDebug.ps1
12. Run-FlowQuery.ps1
13. Get-ScanResults.ps1
14. Get-Flow.ps1

#### Flow Files (4)
1. [Content_Types].xml
2. customizations.xml
3. solution.xml
4. LinearPermissionScanner-[GUID].json

#### Documentation (3)
1. README.md
2. QUICK_START.md
3. INVENTORY.md (this file)

#### Solution Artifacts (26+)
- Multiple solution package versions
- Workflow JSON files
- XML configuration files
- Build artifacts

---

## 🏷️ Asset Tags

### By Technology
- **PowerShell:** 14 scripts
- **Power Automate:** 1 production flow
- **SharePoint:** REST API + Graph API integration
- **Dataverse:** 3 custom tables
- **Azure AD:** OAuth2 authentication

### By Purpose
- **Automation:** 9 scripts
- **Testing:** 5 scripts
- **Deployment:** 5 scripts
- **Documentation:** 3 files
- **Production:** 1 flow

---

## 📝 Change Log

### 2026-01-21
- Initial consolidation of all SharePoint and Power Automate assets
- Created organized directory structure
- Grouped scripts by category
- Added comprehensive documentation
- Copied LinearPermissionScannerV02_1_1 deployed flow
- Created README.md, QUICK_START.md, and INVENTORY.md

---

## 🔮 Future Assets

### Planned Additions
- PowerShell module for common functions
- Additional test scenarios
- Automated deployment pipeline scripts
- Performance monitoring scripts
- Bulk scanning utilities
- Report generation scripts

---

**Asset Count:** 47 files
**Total Size:** ~2.7 MB
**Last Inventory:** 2026-01-21
**Status:** Active Development
