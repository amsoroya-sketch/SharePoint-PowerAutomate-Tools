# PowerShell Scripts Reference

This document provides a reference for all PowerShell scripts used in the Power Automate SharePoint Permission Scanner project.

## Scripts Location

All scripts are located at: `Z:/power automate/sharepoint-scanner/scripts/`

---

## Core Scripts

### 1. Get-SharePointFolders.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Get-SharePointFolders.ps1`

**Purpose:** Query SharePoint for folders with broken permissions using REST API.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| SiteURL | string | `https://abctest179.sharepoint.com/sites/Permission-Scanner-Test` | SharePoint site URL |
| LibraryName | string | `Shared Documents` | Document library name |
| BasePath | string | `/sites/Permission-Scanner-Test/Shared Documents` | Base path to filter |
| ListOnly | switch | false | List all folders without filtering |
| ShowStructure | switch | false | Show folder structure |

**Usage:**
```powershell
# Find folders with broken permissions
.\Get-SharePointFolders.ps1 -SiteURL "https://tenant.sharepoint.com/sites/test" -LibraryName "Shared Documents"

# List all folders
.\Get-SharePointFolders.ps1 -ListOnly
```

---

### 2. Get-SharePointFolders-Graph.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Get-SharePointFolders-Graph.ps1`

**Purpose:** Query SharePoint folders using Microsoft Graph API (alternative to REST API).

**Usage:**
```powershell
.\Get-SharePointFolders-Graph.ps1
```

---

### 3. Get-ScanResults.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Get-ScanResults.ps1`

**Purpose:** Retrieve and display scan results from Dataverse.

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| SessionId | string | Specific session ID to retrieve |
| Latest | switch | Retrieve only most recent scan |
| ShowFolders | switch | Include folder records |
| ShowPermissions | switch | Include permission entries |
| Raw | switch | Output raw data without formatting |

**Usage:**
```powershell
# Get latest scan results
.\Get-ScanResults.ps1 -Latest

# Get full details
.\Get-ScanResults.ps1 -Latest -ShowFolders -ShowPermissions
```

---

### 4. Test-RecursiveScanner.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Test-RecursiveScanner.ps1`

**Purpose:** Opens Power Automate portal and provides test parameters for the Recursive Permission Scanner flow.

**Test Parameters:**
| Parameter | Value |
|-----------|-------|
| SiteURL | `https://abctest179.sharepoint.com/sites/Permission-Scanner-Test` |
| LibraryName | `Documents` |
| BaseLibraryPath | `/sites/Permission-Scanner-Test/Shared Documents` |
| MinimumLevel | `-1` |
| DryRun | `true` |

**Usage:**
```powershell
.\Test-RecursiveScanner.ps1
```

---

### 5. Deploy-RecursiveScanner.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Deploy-RecursiveScanner.ps1`

**Purpose:** Deploy the Recursive Permission Scanner flow to Power Platform.

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| SkipDeploy | switch | Create solution without deploying |
| TestAfterDeploy | switch | Run test after deployment |

**Usage:**
```powershell
# Full deployment
.\Deploy-RecursiveScanner.ps1

# Create package only
.\Deploy-RecursiveScanner.ps1 -SkipDeploy

# Deploy and test
.\Deploy-RecursiveScanner.ps1 -TestAfterDeploy
```

---

### 6. Create-TestFolders.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Create-TestFolders.ps1`

**Purpose:** Create test folder structure in SharePoint for testing the scanner.

**Usage:**
```powershell
.\Create-TestFolders.ps1
```

---

## Utility Scripts

### 7. Deploy-Solution.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Deploy-Solution.ps1`

**Purpose:** General solution deployment script using PAC CLI.

---

### 8. Pack-Solution.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Pack-Solution.ps1`

**Purpose:** Package solution files into a deployable zip.

---

### 9. Get-Flow.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Get-Flow.ps1`

**Purpose:** Query flow information from Dataverse.

---

### 10. Run-FlowQuery.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Run-FlowQuery.ps1`

**Purpose:** Execute FetchXML queries against Dataverse for flow data.

---

### 11. Add-FlowDebug.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Add-FlowDebug.ps1`

**Purpose:** Add debug actions to flow JSON for troubleshooting.

---

### 12. Deploy-DebugFlow.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Deploy-DebugFlow.ps1`

**Purpose:** Deploy a debug version of the flow with enhanced logging.

---

### 13. Test-BrokenPermissionsFlow.ps1
**Path:** `Z:/power automate/sharepoint-scanner/scripts/Test-BrokenPermissionsFlow.ps1`

**Purpose:** Test the broken permissions detection logic.

---

## Windows PowerShell Utility Scripts

Located at: `Z:/power automate/scripts/windows-powershell/`

| Script | Purpose |
|--------|---------|
| Check-DataverseTables.ps1 | Verify Dataverse tables exist |
| Check-Tables-Simple.ps1 | Simple table check |
| Check-Tables-FetchXML.ps1 | Check tables using FetchXML |
| Check-Tables-Alternative.ps1 | Alternative table verification |
| Verify-Tables.ps1 | Full table verification |
| Test-Connection.ps1 | Test Power Platform connection |
| Fix-PowerPlatformConfig.ps1 | Fix configuration issues |
| Upgrade-PowerPlatformCLI.ps1 | Upgrade PAC CLI |
| Start-MCP-Inspector.ps1 | Start MCP Inspector |
| Launch-MCP-Inspector.ps1 | Launch MCP Inspector UI |

---

## Environment Configuration

Scripts use environment variables from `Z:\.env`:

```env
SHAREPOINT_TENANT_ID=ded5a2b7-531c-4cc9-9473-7563570120ae
SHAREPOINT_CLIENT_ID=b7b5f2a9-ed34-469d-af0f-bcb0ee557500
SHAREPOINT_CLIENT_SECRET=<your-secret>
```

---

## Prerequisites

1. **PAC CLI** - Power Platform CLI
   ```powershell
   winget install Microsoft.PowerPlatformCLI
   ```

2. **Authentication**
   ```powershell
   pac auth create --environment "https://org3a2a4fe5.crm6.dynamics.com"
   ```

3. **SharePoint App Registration** with permissions:
   - `Sites.Read.All` (Application)
   - Admin consent granted

---

## Quick Reference

```powershell
# Check connection
pac auth list

# Get scan results
Z:\power automate\sharepoint-scanner\scripts\Get-ScanResults.ps1 -Latest

# Query SharePoint folders
Z:\power automate\sharepoint-scanner\scripts\Get-SharePointFolders.ps1

# Test the flow
Z:\power automate\sharepoint-scanner\scripts\Test-RecursiveScanner.ps1

# Deploy solution
Z:\power automate\sharepoint-scanner\scripts\Deploy-RecursiveScanner.ps1
```

---

**Last Updated:** January 2025
