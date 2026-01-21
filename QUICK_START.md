# Quick Start Guide - SharePoint Permission Scanner

## 🎯 Goal
Scan SharePoint folders for broken permissions and store results in Dataverse.

---

## ⚡ 5-Minute Setup

### 1. Prerequisites Check
```powershell
# Verify PowerShell version (need 7+)
$PSVersionTable.PSVersion

# Check PAC CLI
pac --version

# Verify authentication
pac auth list
```

### 2. Configure Environment
Create `Z:\.env` with your credentials:
```env
SHAREPOINT_TENANT_ID=your-tenant-id
SHAREPOINT_CLIENT_ID=your-app-client-id
SHAREPOINT_CLIENT_SECRET=your-client-secret
```

### 3. Create Test Data (Optional)
```powershell
cd /home/dev/Development/SharePoint-PowerAutomate-Tools/scripts/test-data
.\Create-TestFolders.ps1
```

This creates:
- 13 test folders
- 5 with broken permissions
- Realistic folder hierarchy

### 4. Verify Setup
```powershell
cd ../sharepoint-queries
.\Get-SharePointFolders.ps1 -ListOnly
```

Expected output:
- List of all folders in your SharePoint library
- Permission status for each folder

---

## 🚀 Deploy & Test Flow

### Step 1: Deploy the Flow
```powershell
cd ../deployment
.\Deploy-LinearScannerV02.ps1
```

### Step 2: Open Power Automate
```powershell
cd ../testing
.\Test-RecursiveScanner.ps1
```

This will:
- Open Power Automate portal
- Show test parameters
- Display expected results

### Step 3: Manual Test
In Power Automate:
1. Navigate to **Solutions** → **RecursivePermissionScanner**
2. Click **Test** → **Manually** → **Test**
3. Enter parameters:
   ```
   SiteURL:         https://abctest179.sharepoint.com/sites/Permission-Scanner-Test
   LibraryName:     Documents
   BaseLibraryPath: /sites/Permission-Scanner-Test/Shared Documents
   MinimumLevel:    -1
   DryRun:          true
   ```
4. Click **Run flow**

### Step 4: Check Results
```powershell
cd ../dataverse
.\Get-ScanResults.ps1 -Latest -ShowFolders
```

---

## 📊 Expected Results

### Test Scenario
- **Total Folders Scanned:** ~13
- **Folders with Broken Permissions:** 5

### Broken Permission Folders
1. `TestFolder1` (root level)
2. `TestFolder2/SubFolder2a` (level 1)
3. `TestFolder3/Level2/Level3` (level 2)
4. `HR/Policies` (level 1)
5. `Projects/Project-Beta` (level 1)

---

## 🎓 Common Commands

### Query SharePoint
```powershell
# List all folders
.\Get-SharePointFolders.ps1 -ListOnly

# Find broken permissions only
.\Get-SharePointFolders.ps1

# Use Graph API
.\Get-SharePointFolders-Graph.ps1
```

### Test Scenarios
```powershell
# Show available test scenarios
.\Test-BrokenPermissionsFlow.ps1 -Scenario List

# Validate OData query
.\Test-BrokenPermissionsFlow.ps1 -Scenario TestQuery
```

### Check Dataverse
```powershell
# Latest scan results
.\Get-ScanResults.ps1 -Latest

# With folder details
.\Get-ScanResults.ps1 -Latest -ShowFolders

# With permissions
.\Get-ScanResults.ps1 -Latest -ShowFolders -ShowPermissions
```

---

## 🔧 Troubleshooting

### Issue: "PAC CLI not authenticated"
```powershell
pac auth create --environment https://org12345678.crm.dynamics.com
```

### Issue: "No folders found"
```powershell
# Verify base path is correct
.\Get-SharePointFolders.ps1 -ListOnly -SiteURL "your-url" -BasePath "your-path"
```

### Issue: "Authentication failed"
```powershell
# Check environment variables
Get-Content Z:\.env

# Verify app permissions in Azure Portal
# Required: Sites.Read.All (Application)
```

### Issue: "Flow deployment failed"
```powershell
# Re-authenticate to Power Platform
pac auth clear
pac auth create

# Try deployment again
.\Deploy-LinearScannerV02.ps1
```

---

## 📚 Next Steps

1. **Read Full Documentation:** See [README.md](README.md)
2. **Explore Scripts:** Browse `scripts/` folders
3. **Review Deployed Flow:** Check `deployed-flows/LinearPermissionScannerV02_1_1/`
4. **Customize:** Modify parameters in scripts for your environment

---

## 🆘 Need Help?

1. Check [README.md](README.md) Troubleshooting section
2. Review script comments (each has `.SYNOPSIS` and `.EXAMPLE`)
3. Check Power Automate flow run history for errors
4. Verify Azure AD app registration permissions

---

**Quick Reference Card**

| Task | Command | Location |
|------|---------|----------|
| Create test data | `.\Create-TestFolders.ps1` | `scripts/test-data/` |
| Query SharePoint | `.\Get-SharePointFolders.ps1` | `scripts/sharepoint-queries/` |
| Deploy flow | `.\Deploy-LinearScannerV02.ps1` | `scripts/deployment/` |
| Test flow | `.\Test-RecursiveScanner.ps1` | `scripts/testing/` |
| Check results | `.\Get-ScanResults.ps1 -Latest` | `scripts/dataverse/` |
| Clean up tests | `.\Create-TestFolders.ps1 -CleanUp` | `scripts/test-data/` |

---

**Last Updated:** 2026-01-21
