# Power Automate UI Plan: Convert to Queue-Based Recursion

## Flow: Recursive Permission ScannerV.01

---

## Goal
Convert from **flat-list** (gets all folders in one API call) to **queue-based breadth-first recursion** (dynamically discovers folders level by level).

---

## Open the Flow
1. Go to **make.powerautomate.com**
2. Navigate to **Solutions** → **Recursive Permission Scanner**
3. Open flow: **Recursive Permission ScannerV.01**
4. Click **Edit**

---

## STEP 1: Add FoldersToProcess Variable ✅ DONE

1. Find the last **Initialize variable** action (should be `Initialize_varDiagnosticLog`)
2. Click **+** below it → **Add an action**
3. Search for **Initialize variable**
4. Configure:
   - **Name**: `FoldersToProcess`
   - **Type**: Array
   - **Value**: `[]` (empty array)

---

## STEP 2: Add Root Folder to Queue ✅ DONE

1. After `DEBUG_InputParameters`, click **+** → **Add an action**
2. Search for **Compose** → Add it
3. Rename to: `Get_Root_Folder_Path`
4. **Inputs**: Click in the field, go to **Expression** tab, enter:
   ```
   triggerBody()['text_2']
   ```

5. Click **+** below → **Add an action**
6. Search for **Append to array variable**
7. Configure:
   - **Name**: Select `FoldersToProcess`
   - **Value**: Click **Dynamic content** → Select `Outputs` from `Get_Root_Folder_Path`

---

## STEP 3: Delete Old Flat-List Actions ✅ DONE

Delete these actions (click **...** → **Delete**):
- `Set_varLastRequestUri_GetFolders`
- `DEBUG_PreRequest_GetFolders`
- `Scope_GetAllFolders` (entire scope including everything inside)
- `Scope_GetAllFolders_Error` (entire scope)
- `Condition_GetFoldersSucceeded` (entire condition including `Apply_to_each_Folder` inside)

---

## STEP 4: Fix Do Until Loop ⚠️ NEEDS FIX

The Do Until loop exists but the expression is wrong.

1. Click on the **Do until** action
2. **Fix the condition:**
   - Click the first field, go to **Expression**, enter:
     ```
     length(variables('FoldersToProcess'))
     ```
   - Operator: **is equal to**
   - Second field: `0`

3. Click **Change limits**:
   - **Count**: `5000`
   - **Timeout**: `PT2H`

---

## STEP 5: Inside Do Until - Add Queue Actions

### 5.1 Get Current Folder
1. Inside Do Until, click **Add an action**
2. Add **Compose**, rename to: `Get_current_Folder`
3. **Inputs** → Expression:
   ```
   first(variables('FoldersToProcess'))
   ```

### 5.2 Add Delay
1. Click **+** → Add **Delay** (under Schedule)
2. Configure: **3 seconds**

### 5.3 Check Permissions (HTTP Request)
1. Click **+** → Add **Send an HTTP request to SharePoint**
2. Configure:
   - **Site Address**: Select your site OR use expression: `triggerBody()['text']`
   - **Method**: GET
   - **Uri** → Expression:
     ```
     concat('_api/web/GetFolderByServerRelativeUrl(''', outputs('Get_current_Folder'), ''')/ListItemAllFields/HasUniqueRoleAssignments')
     ```
     **⚠️ IMPORTANT**: Use `/ListItemAllFields/HasUniqueRoleAssignments` (direct property access), NOT `$select=HasUniqueRoleAssignments`
   - **Headers**:
     - Key: `Accept`
     - Value: `application/json;odata=nometadata`
3. Rename to: `HTTP_Check_Permissions`
4. **Response format**: `{"value": true}` or `{"value": false}`

### 5.4 Add Condition for Broken Permissions
1. Click **+** → Add **Condition**
2. Configure:
   - First field → Expression:
     ```
     body('HTTP_Check_Permissions')?['value']
     ```
   - Operator: **is equal to**
   - Second field → Expression: `true`

### 5.5 Inside "If yes" Branch - Add Reset Logic

#### 5.5.1 Compose Debug
1. Add **Compose**, rename: `DEBUG_BrokenPermission`
2. Inputs (switch to code view or type manually):
   ```
   BROKEN PERMISSIONS FOUND
   ```
   Or for JSON format:
   ```json
   {
     "Step": "BROKEN PERMISSIONS FOUND",
     "FolderPath": "@{outputs('Get_current_Folder')}"
   }
   ```

#### 5.5.2 Append to Broken Folders Array
1. Add **Append to array variable**
2. **Name**: `varFoldersWithBrokenPerms`
3. **Value** → Switch to Expression:
   ```
   outputs('Get_current_Folder')
   ```

#### 5.5.3 Add DryRun Condition
1. Add **Condition**
2. Configure:
   - First field → Expression: `triggerBody()['text_4']`
   - Operator: **is equal to**
   - Second field: `false`

#### 5.5.4 Inside DryRun "If yes" (reset permissions when DryRun=false)
1. Add **Delay**: 3 seconds
2. Add **Send an HTTP request to SharePoint**:
   - **Site Address**: Select your site OR expression: `triggerBody()['text']`
   - **Method**: POST
   - **Uri** → Expression:
     ```
     concat('_api/web/GetFolderByServerRelativeUrl(''', outputs('Get_current_Folder'), ''')/ListItemAllFields/ResetRoleInheritance()')
     ```
   - **Headers**:
     - Key: `Accept`
     - Value: `application/json;odata=nometadata`
3. Rename to: `HTTP_Reset_Inheritance`
4. Add **Increment variable**:
   - **Name**: `varSuccessCount`
   - **Value**: 1

#### 5.5.5 Inside DryRun "If no" (skip reset when DryRun=true)
1. Add **Compose**, rename: `DEBUG_DryRunSkipped`
2. Inputs: `Skipped reset - DryRun mode`

### 5.6 After the Broken Permissions Condition - Get Child Folders

**Important**: This goes AFTER the condition (outside, below it), still inside Do Until

1. Add **Delay**: 2 seconds
2. Add **Send an HTTP request to SharePoint**:
   - **Site Address**: Select your site OR expression: `triggerBody()['text']`
   - **Method**: GET
   - **Uri** → Expression:
     ```
     concat('_api/web/GetFolderByServerRelativeUrl(''', outputs('Get_current_Folder'), ''')/Folders?$select=ServerRelativeUrl')
     ```
   - **Headers**:
     - Key: `Accept`
     - Value: `application/json;odata=nometadata`
3. Rename to: `Get_Child_Folders`

### 5.7 Add Children to Queue
1. Add **Apply to each**
2. **Select an output from previous steps** → Click in field, go to Expression:
   ```
   body('Get_Child_Folders')?['value']
   ```
3. Inside the Apply to each loop, add **Append to array variable**:
   - **Name**: `FoldersToProcess`
   - **Value** → Expression:
     ```
     items('Apply_to_each')?['ServerRelativeUrl']
     ```

### 5.8 Remove Processed Folder from Queue

**Important**: This goes AFTER Apply to each, still inside Do Until

1. Add **Compose**, rename: `RemoveProcessedFolder`
2. **Inputs** → Expression:
   ```
   skip(variables('FoldersToProcess'), 1)
   ```

3. Add **Set variable**:
   - **Name**: `FoldersToProcess`
   - **Value**: Click **Dynamic content** → Select `Outputs` from `RemoveProcessedFolder`

### 5.9 Increment Counter
1. Add **Increment variable**:
   - **Name**: `varProcessedCount`
   - **Value**: 1

---

## STEP 6: Add Final Summary (After Do Until)

After the Do Until loop ends, add:

1. Add **Compose**, rename: `DEBUG_Summary`
2. **Inputs** (use Expression for each value):
   ```json
   {
     "Step": "FINAL SUMMARY",
     "TotalFoldersScanned": "@{variables('varProcessedCount')}",
     "FoldersWithBrokenPermissions": "@{length(variables('varFoldersWithBrokenPerms'))}",
     "SuccessfulResets": "@{variables('varSuccessCount')}",
     "FailedOperations": "@{variables('varFailCount')}",
     "DryRun": "@{triggerBody()['text_4']}",
     "CompletedAt": "@{utcNow()}"
   }
   ```

---

## STEP 7: Save and Test

1. Click **Save**
2. Click **Test** → **Manually**
3. Enter test values:
   - **SiteURL**: `https://abctest179.sharepoint.com/sites/Permission-Scanner-Test`
   - **LibraryName**: `Documents`
   - **BaseLibraryPath**: `/sites/Permission-Scanner-Test/Shared Documents`
   - **MinimumLevel**: `-1`
   - **DryRun**: `true` (scan only first!)
4. Run and check the flow history

---

## Flow Structure After Changes

```
┌─ Initialize Variables (9 total)
│   ├─ varBaseDepth
│   ├─ varFoldersWithBrokenPerms
│   ├─ varProcessedCount
│   ├─ varErrorLog
│   ├─ varSuccessCount
│   ├─ varFailCount
│   ├─ varLastRequestUri
│   ├─ varDiagnosticLog
│   └─ FoldersToProcess ← NEW
│
├─ DEBUG_InputParameters
│
├─ Get_Root_Folder_Path ← NEW
├─ Append_to_array_variable ← NEW
│
├─ Do Until (length(FoldersToProcess) = 0) ← NEW
│   ├─ Get_current_Folder
│   ├─ Delay (3s)
│   ├─ HTTP_Check_Permissions
│   ├─ Condition (HasUniqueRoleAssignments = true)
│   │   ├─ If Yes:
│   │   │   ├─ DEBUG_BrokenPermission
│   │   │   ├─ Append to varFoldersWithBrokenPerms
│   │   │   └─ Condition (DryRun = false)
│   │   │       ├─ If Yes: Delay → Reset → Increment Success
│   │   │       └─ If No: DEBUG_DryRunSkipped
│   │   └─ If No: (empty)
│   ├─ Delay (2s)
│   ├─ Get_Child_Folders
│   ├─ Apply_to_each (append children to queue)
│   ├─ RemoveProcessedFolder (Compose)
│   ├─ Set FoldersToProcess
│   └─ Increment varProcessedCount
│
└─ DEBUG_Summary
```

---

## Queue Logic (Breadth-First)

```
┌─────────────────────────────────────────┐
│  Do Until: FoldersToProcess is empty    │
├─────────────────────────────────────────┤
│  1. Get FIRST folder from queue         │
│  2. Check HasUniqueRoleAssignments      │
│  3. If true & DryRun=false → Reset      │
│  4. Get child folders                   │
│  5. Add children to END of queue        │
│  6. Remove processed folder from FRONT  │
│  7. Increment counter                   │
└─────────────────────────────────────────┘

Example Processing Order:
Root
├── A
│   ├── A1
│   └── A2
└── B
    └── B1

Queue progression:
[Root] → [A, B] → [B, A1, A2] → [A1, A2, B1] → [A2, B1] → [B1] → []
Process: Root → A → B → A1 → A2 → B1 (level by level)
```

---

## Testing Checklist

- [ ] Do Until expression fixed: `length(variables('FoldersToProcess'))` = `0`
- [ ] Flow saves without errors
- [ ] Test with DryRun=true - verify all nested folders discovered
- [ ] Check run history - confirm folders processed level by level
- [ ] Test with DryRun=false on test folder - verify permissions reset
- [ ] Verify counters are accurate

---

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| "Invalid expression" | Check quotes - use `''` (two single quotes) inside concat |
| Loop runs forever | Verify Do Until expression: `length(variables('FoldersToProcess'))` = `0` |
| No child folders found | Check Get_Child_Folders URI - use `Folders?$select=ServerRelativeUrl` |
| Permission reset fails | Ensure method is **POST**, not GET |
| HasUniqueRoleAssignments not found | Use `/ListItemAllFields/HasUniqueRoleAssignments` NOT `$select=...` |
| Apply_to_each error | Expression should be `body('Get_Child_Folders')?['value']` |
