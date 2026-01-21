# Upgrade Plan: Convert RecursivePermissionScannerV01 to Queue-Based Recursion

## Overview
Convert the flow from **flat-list** (gets all folders in one API call) to **queue-based breadth-first recursion** (dynamically discovers folders level by level).

---

## File to Modify
```
Z:\power automate\sharepoint-scanner\solution\RecursivePermissionScanner\extracted\Workflows\RecursivePermissionScannerV01-F2E3AB22-E2BC-4920-AF40-8887A2ED6119.json
```

## Reference Flow (copy patterns from)
```
Z:\power automate\sharepoint-scanner\solution\RecursivePermissionScanner\extracted\Workflows\SharePointPermissionScanner-Recursive-17C3F8FE-0FEC-F011-8407-000D3AE1FF22.json
```

---

## Step 1: Add FoldersToProcess Variable

**Location**: After `Initialize_varDiagnosticLog` (around line 240)

**Add this action**:
```json
"Initialize_FoldersToProcess": {
  "runAfter": {
    "Initialize_varDiagnosticLog": [
      "Succeeded"
    ]
  },
  "metadata": {
    "operationMetadataId": "init-folders-to-process-001"
  },
  "type": "InitializeVariable",
  "inputs": {
    "variables": [
      {
        "name": "FoldersToProcess",
        "type": "array",
        "value": []
      }
    ]
  }
}
```

**Update**: Change `DEBUG_InputParameters` to run after `Initialize_FoldersToProcess` instead of `Initialize_varDiagnosticLog`.

---

## Step 2: Add Root Folder Initialization

**Location**: After `DEBUG_InputParameters` (replace `Set_varLastRequestUri_GetFolders` and `DEBUG_PreRequest_GetFolders`)

**Add these actions**:
```json
"Get_Root_Folder_Path": {
  "runAfter": {
    "DEBUG_InputParameters": [
      "Succeeded"
    ]
  },
  "metadata": {
    "operationMetadataId": "get-root-folder-path-001"
  },
  "type": "Compose",
  "inputs": "@triggerBody()['text_2']"
},
"Append_Root_To_Queue": {
  "runAfter": {
    "Get_Root_Folder_Path": [
      "Succeeded"
    ]
  },
  "metadata": {
    "operationMetadataId": "append-root-to-queue-001"
  },
  "type": "AppendToArrayVariable",
  "inputs": {
    "name": "FoldersToProcess",
    "value": "@outputs('Get_Root_Folder_Path')"
  }
}
```

---

## Step 3: Delete Obsolete Actions

**Remove these entire action blocks**:
- `Set_varLastRequestUri_GetFolders` (lines 263-277)
- `DEBUG_PreRequest_GetFolders` (lines 278-298)
- `Scope_GetAllFolders` (lines 299-363)
- `Scope_GetAllFolders_Error` (lines 364-475)
- `Condition_GetFoldersSucceeded` (lines 476-848) - This contains `Apply_to_each_Folder`

---

## Step 4: Add Do_until Loop

**Location**: After `Append_Root_To_Queue`, before `DEBUG_Summary`

**Add this structure** (this is the main recursive loop):

```json
"Do_until": {
  "actions": {
    "Get_current_Folder": {
      "metadata": {
        "operationMetadataId": "get-current-folder-001"
      },
      "type": "Compose",
      "inputs": "@first(variables('FoldersToProcess'))"
    },
    "DEBUG_ProcessingFolder": {
      "runAfter": {
        "Get_current_Folder": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "debug-processing-folder-001"
      },
      "type": "Compose",
      "inputs": {
        "Step": "PROCESSING FOLDER",
        "CurrentFolder": "@outputs('Get_current_Folder')",
        "QueueLength": "@length(variables('FoldersToProcess'))",
        "ProcessedSoFar": "@variables('varProcessedCount')",
        "Timestamp": "@utcNow()"
      }
    },
    "Delay_Before_Check": {
      "runAfter": {
        "DEBUG_ProcessingFolder": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "delay-before-check-001"
      },
      "type": "Wait",
      "inputs": {
        "interval": {
          "count": 3,
          "unit": "Second"
        }
      }
    },
    "HTTP_Check_Permissions": {
      "runAfter": {
        "Delay_Before_Check": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "http-check-permissions-001"
      },
      "type": "OpenApiConnection",
      "inputs": {
        "parameters": {
          "dataset": "@triggerBody()['text']",
          "parameters/method": "GET",
          "parameters/uri": "@concat('_api/web/GetFolderByServerRelativeUrl(''', outputs('Get_current_Folder'), ''')/ListItemAllFields?$select=HasUniqueRoleAssignments')",
          "parameters/headers": {
            "Accept": "application/json;odata=nometadata"
          }
        },
        "host": {
          "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
          "operationId": "HttpRequest",
          "connectionName": "shared_sharepointonline"
        }
      },
      "retryPolicy": {
        "type": "exponential",
        "count": 5,
        "interval": "PT10S",
        "minimumInterval": "PT5S",
        "maximumInterval": "PT5M"
      }
    },
    "Condition_HasBrokenPerms": {
      "actions": {
        "DEBUG_BrokenPermission": {
          "metadata": {
            "operationMetadataId": "debug-broken-permission-001"
          },
          "type": "Compose",
          "inputs": {
            "Step": "BROKEN PERMISSIONS FOUND",
            "FolderPath": "@outputs('Get_current_Folder')",
            "Timestamp": "@utcNow()"
          }
        },
        "Append_BrokenFolder": {
          "runAfter": {
            "DEBUG_BrokenPermission": [
              "Succeeded"
            ]
          },
          "metadata": {
            "operationMetadataId": "append-broken-folder-001"
          },
          "type": "AppendToArrayVariable",
          "inputs": {
            "name": "varFoldersWithBrokenPerms",
            "value": {
              "FolderPath": "@outputs('Get_current_Folder')",
              "Level": "@sub(length(split(outputs('Get_current_Folder'), '/')), variables('varBaseDepth'))"
            }
          }
        },
        "Condition_DryRun": {
          "actions": {
            "Delay_Before_Reset": {
              "metadata": {
                "operationMetadataId": "delay-before-reset-001"
              },
              "type": "Wait",
              "inputs": {
                "interval": {
                  "count": 3,
                  "unit": "Second"
                }
              }
            },
            "HTTP_Reset_Inheritance": {
              "runAfter": {
                "Delay_Before_Reset": [
                  "Succeeded"
                ]
              },
              "metadata": {
                "operationMetadataId": "http-reset-inheritance-001"
              },
              "type": "OpenApiConnection",
              "inputs": {
                "parameters": {
                  "dataset": "@triggerBody()['text']",
                  "parameters/method": "POST",
                  "parameters/uri": "@concat('_api/web/GetFolderByServerRelativeUrl(''', outputs('Get_current_Folder'), ''')/ListItemAllFields/ResetRoleInheritance()')",
                  "parameters/headers": {
                    "Accept": "application/json;odata=nometadata"
                  }
                },
                "host": {
                  "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                  "operationId": "HttpRequest",
                  "connectionName": "shared_sharepointonline"
                }
              },
              "retryPolicy": {
                "type": "exponential",
                "count": 5,
                "interval": "PT10S",
                "minimumInterval": "PT5S",
                "maximumInterval": "PT5M"
              }
            },
            "DEBUG_ResetSuccess": {
              "runAfter": {
                "HTTP_Reset_Inheritance": [
                  "Succeeded"
                ]
              },
              "metadata": {
                "operationMetadataId": "debug-reset-success-001"
              },
              "type": "Compose",
              "inputs": {
                "Step": "RESET SUCCESS",
                "FolderPath": "@outputs('Get_current_Folder')",
                "Status": "Permissions cleared - now inherits from parent",
                "Timestamp": "@utcNow()"
              }
            },
            "Increment_SuccessCount": {
              "runAfter": {
                "DEBUG_ResetSuccess": [
                  "Succeeded"
                ]
              },
              "metadata": {
                "operationMetadataId": "increment-success-count-001"
              },
              "type": "IncrementVariable",
              "inputs": {
                "name": "varSuccessCount",
                "value": 1
              }
            }
          },
          "runAfter": {
            "Append_BrokenFolder": [
              "Succeeded"
            ]
          },
          "else": {
            "actions": {
              "DEBUG_DryRunSkipped": {
                "metadata": {
                  "operationMetadataId": "debug-dryrun-skipped-001"
                },
                "type": "Compose",
                "inputs": {
                  "Step": "RESET SKIPPED (DRY RUN)",
                  "FolderPath": "@outputs('Get_current_Folder')",
                  "Message": "Would have reset permissions but DryRun is true",
                  "Timestamp": "@utcNow()"
                }
              }
            }
          },
          "expression": {
            "equals": [
              "@triggerBody()['text_4']",
              "false"
            ]
          },
          "metadata": {
            "operationMetadataId": "condition-dry-run-001"
          },
          "type": "If"
        }
      },
      "runAfter": {
        "HTTP_Check_Permissions": [
          "Succeeded"
        ]
      },
      "else": {
        "actions": {
          "DEBUG_NoUniquePermissions": {
            "metadata": {
              "operationMetadataId": "debug-no-unique-permissions-001"
            },
            "type": "Compose",
            "inputs": {
              "Step": "NO BROKEN PERMISSIONS",
              "FolderPath": "@outputs('Get_current_Folder')",
              "HasUniqueRoleAssignments": false,
              "Message": "Folder inherits permissions from parent",
              "Timestamp": "@utcNow()"
            }
          }
        }
      },
      "expression": {
        "equals": [
          "@body('HTTP_Check_Permissions')?['value']",
          true
        ]
      },
      "metadata": {
        "operationMetadataId": "condition-has-broken-perms-001"
      },
      "type": "If"
    },
    "Delay_Before_GetChildren": {
      "runAfter": {
        "Condition_HasBrokenPerms": [
          "Succeeded",
          "Failed"
        ]
      },
      "metadata": {
        "operationMetadataId": "delay-before-get-children-001"
      },
      "type": "Wait",
      "inputs": {
        "interval": {
          "count": 2,
          "unit": "Second"
        }
      }
    },
    "Get_Child_Folders": {
      "runAfter": {
        "Delay_Before_GetChildren": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "get-child-folders-001"
      },
      "type": "OpenApiConnection",
      "inputs": {
        "parameters": {
          "dataset": "@triggerBody()['text']",
          "parameters/method": "GET",
          "parameters/uri": "@concat('_api/web/GetFolderByServerRelativeUrl(''', outputs('Get_current_Folder'), ''')/Folders?$select=ServerRelativeUrl')",
          "parameters/headers": {
            "Accept": "application/json;odata=nometadata"
          }
        },
        "host": {
          "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
          "operationId": "HttpRequest",
          "connectionName": "shared_sharepointonline"
        }
      },
      "retryPolicy": {
        "type": "exponential",
        "count": 5,
        "interval": "PT10S",
        "minimumInterval": "PT5S",
        "maximumInterval": "PT5M"
      }
    },
    "DEBUG_ChildFolders": {
      "runAfter": {
        "Get_Child_Folders": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "debug-child-folders-001"
      },
      "type": "Compose",
      "inputs": {
        "Step": "CHILD FOLDERS FOUND",
        "ParentFolder": "@outputs('Get_current_Folder')",
        "ChildCount": "@length(body('Get_Child_Folders')?['value'])",
        "Children": "@body('Get_Child_Folders')?['value']",
        "Timestamp": "@utcNow()"
      }
    },
    "Apply_to_each_Child": {
      "foreach": "@body('Get_Child_Folders')?['value']",
      "actions": {
        "Append_Child_To_Queue": {
          "metadata": {
            "operationMetadataId": "append-child-to-queue-001"
          },
          "type": "AppendToArrayVariable",
          "inputs": {
            "name": "FoldersToProcess",
            "value": "@items('Apply_to_each_Child')?['ServerRelativeUrl']"
          }
        }
      },
      "runAfter": {
        "DEBUG_ChildFolders": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "apply-to-each-child-001"
      },
      "type": "Foreach"
    },
    "RemoveProcessedFolder": {
      "runAfter": {
        "Apply_to_each_Child": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "remove-processed-folder-001"
      },
      "type": "Compose",
      "inputs": "@skip(variables('FoldersToProcess'), 1)"
    },
    "Update_Queue": {
      "runAfter": {
        "RemoveProcessedFolder": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "update-queue-001"
      },
      "type": "SetVariable",
      "inputs": {
        "name": "FoldersToProcess",
        "value": "@outputs('RemoveProcessedFolder')"
      }
    },
    "Increment_ProcessedCount": {
      "runAfter": {
        "Update_Queue": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "increment-processed-count-001"
      },
      "type": "IncrementVariable",
      "inputs": {
        "name": "varProcessedCount",
        "value": 1
      }
    },
    "DEBUG_IterationComplete": {
      "runAfter": {
        "Increment_ProcessedCount": [
          "Succeeded"
        ]
      },
      "metadata": {
        "operationMetadataId": "debug-iteration-complete-001"
      },
      "type": "Compose",
      "inputs": {
        "Step": "ITERATION COMPLETE",
        "ProcessedFolder": "@outputs('Get_current_Folder')",
        "RemainingInQueue": "@length(variables('FoldersToProcess'))",
        "TotalProcessed": "@variables('varProcessedCount')",
        "BrokenPermissionsFound": "@length(variables('varFoldersWithBrokenPerms'))",
        "Timestamp": "@utcNow()"
      }
    }
  },
  "runAfter": {
    "Append_Root_To_Queue": [
      "Succeeded"
    ]
  },
  "expression": "@equals(length(variables('FoldersToProcess')), 0)",
  "limit": {
    "count": 5000,
    "timeout": "PT2H"
  },
  "metadata": {
    "operationMetadataId": "do-until-queue-empty-001"
  },
  "type": "Until"
}
```

---

## Step 5: Update DEBUG_Summary runAfter

**Change** `DEBUG_Summary` to run after `Do_until` instead of `Condition_GetFoldersSucceeded`:

```json
"DEBUG_Summary": {
  "runAfter": {
    "Do_until": [
      "Succeeded",
      "Failed"
    ]
  },
  ...
}
```

---

## Step 6: Repackage and Import

After making all changes:

```bash
# Navigate to solution folder
cd "Z:\power automate\sharepoint-scanner\solution\RecursivePermissionScanner"

# Create updated ZIP
zip -r RecursivePermissionScanner_v2.zip extracted/*

# Import to Power Platform
pac solution import --path RecursivePermissionScanner_v2.zip
```

---

## Summary of Changes

| Before (Flat List) | After (Queue-Based) |
|--------------------|---------------------|
| `Scope_GetAllFolders` → Gets all folders in ONE call | `Get_Root_Folder_Path` → Starts with root only |
| `Apply_to_each_Folder` (foreach) | `Do_until` (while queue not empty) |
| Static folder list | Dynamic discovery via `Get_Child_Folders` |
| `items('Apply_to_each_Folder')` | `outputs('Get_current_Folder')` |

---

## Queue Operations (Breadth-First)

```
1. Initialize: Queue = [Root]
2. Loop until Queue is empty:
   a. Get first folder:     first(FoldersToProcess)
   b. Process folder:       Check permissions, reset if needed
   c. Get children:         GetFolderByServerRelativeUrl()/Folders
   d. Add children to back: AppendToArrayVariable
   e. Remove processed:     skip(FoldersToProcess, 1)
```

**Traversal Order Example**:
```
Root
├── A
│   ├── A1
│   └── A2
└── B
    └── B1

Processing: Root → A → B → A1 → A2 → B1 (level by level)
```

---

## Testing Checklist

- [ ] Import solution successfully
- [ ] Run with DryRun=true - verify all nested folders discovered
- [ ] Check run history - confirm breadth-first order in DEBUG outputs
- [ ] Run with DryRun=false - verify permissions reset correctly
- [ ] Verify varSuccessCount and varFailCount are accurate
