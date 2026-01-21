const fs = require('fs');
const path = require('path');

// Paths
const flowPath = path.join(__dirname, 'validate_check_extracted/Workflows/SharePointPermissionScanner-17C3F8FE-0FEC-F011-8407-000D3AE1FF22.json');
const fixedFlowPath = path.join(__dirname, 'validate_check_extracted/Workflows/SharePointPermissionScanner-17C3F8FE-0FEC-F011-8407-000D3AE1FF22_FIXED.json');

console.log('Reading flow file...');
const flow = JSON.parse(fs.readFileSync(flowPath, 'utf8'));

// Get the actions object
const actions = flow.properties.definition.actions;

console.log('Extracting Catch_Scope from inside Try_Scope...');
// Extract Catch_Scope from Try_Scope.actions
const catchScope = actions.Try_Scope.actions.Catch_Scope;

if (!catchScope) {
  console.error('ERROR: Catch_Scope not found inside Try_Scope.actions');
  process.exit(1);
}

console.log('Removing Catch_Scope from Try_Scope.actions...');
// Remove Catch_Scope from Try_Scope.actions
delete actions.Try_Scope.actions.Catch_Scope;

console.log('Creating corrected Catch_Scope structure...');
// Create a new Catch_Scope with correct runAfter
const correctedCatchScope = {
  ...catchScope,
  runAfter: {
    Try_Scope: ["Failed", "TimedOut"]
  }
};

console.log('Creating Finally_Scope...');
// Create Finally_Scope to update scan session
const finallyScope = {
  actions: {
    Condition_Check_Error: {
      actions: {
        Update_Session_Failed: {
          runAfter: {},
          metadata: {
            operationMetadataId: "update-session-failed-001"
          },
          type: "OpenApiConnection",
          inputs: {
            host: {
              connectionName: "shared_commondataserviceforapps",
              operationId: "UpdateRecord",
              apiId: "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"
            },
            parameters: {
              entityName: "sp_scansessions",
              recordId: "@variables('ScanSessionId')",
              "item/sp_status": 100000002,
              "item/sp_completedon": "@utcNow()",
              "item/sp_totalfolders": "@variables('TotalFolders')",
              "item/sp_folderswithuniquepermissions": "@variables('FoldersWithUniquePerms')"
            },
            authentication: {
              type: "Raw",
              value: "@json(decodeBase64(triggerOutputs().headers['X-MS-APIM-Tokens']))['$ConnectionKey']"
            }
          }
        }
      },
      runAfter: {},
      else: {
        actions: {
          Update_Session_Success: {
            runAfter: {},
            metadata: {
              operationMetadataId: "update-session-success-001"
            },
            type: "OpenApiConnection",
            inputs: {
              host: {
                connectionName: "shared_commondataserviceforapps",
                operationId: "UpdateRecord",
                apiId: "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"
              },
              parameters: {
                entityName: "sp_scansessions",
                recordId: "@variables('ScanSessionId')",
                "item/sp_status": 100000000,
                "item/sp_completedon": "@utcNow()",
                "item/sp_totalfolders": "@variables('TotalFolders')",
                "item/sp_folderswithuniquepermissions": "@variables('FoldersWithUniquePerms')"
              },
              authentication: {
                type: "Raw",
                value: "@json(decodeBase64(triggerOutputs().headers['X-MS-APIM-Tokens']))['$ConnectionKey']"
              }
            }
          }
        }
      },
      expression: {
        equals: [
          "@variables('HasError')",
          true
        ]
      },
      metadata: {
        operationMetadataId: "condition-check-error-001"
      },
      type: "If"
    }
  },
  runAfter: {
    Catch_Scope: ["Succeeded", "Failed", "Skipped"]
  },
  metadata: {
    operationMetadataId: "finally-scope-001"
  },
  type: "Scope"
};

console.log('Rebuilding actions object with correct structure...');
// Rebuild actions object with correct order
const fixedActions = {};

// Copy all actions except Try_Scope first
for (const [key, value] of Object.entries(actions)) {
  if (key !== 'Try_Scope') {
    fixedActions[key] = value;
  }
}

// Add Try_Scope
fixedActions.Try_Scope = actions.Try_Scope;

// Add Catch_Scope as sibling
fixedActions.Catch_Scope = correctedCatchScope;

// Add Finally_Scope
fixedActions.Finally_Scope = finallyScope;

// Update the flow with fixed actions
flow.properties.definition.actions = fixedActions;

console.log('Writing fixed flow to file...');
fs.writeFileSync(fixedFlowPath, JSON.stringify(flow, null, 2), 'utf8');

console.log('✅ Flow fixed successfully!');
console.log(`📁 Fixed file saved to: ${fixedFlowPath}`);
console.log('\nChanges made:');
console.log('1. ✅ Extracted Catch_Scope from Try_Scope.actions');
console.log('2. ✅ Placed Catch_Scope as sibling to Try_Scope');
console.log('3. ✅ Updated Catch_Scope runAfter to: Try_Scope: ["Failed", "TimedOut"]');
console.log('4. ✅ Added Finally_Scope to update scan session status');
console.log('\nNext steps:');
console.log('1. Review the _FIXED.json file');
console.log('2. If correct, rename it to replace the original');
console.log('3. Repackage the solution using PAC CLI');
console.log('4. Import the corrected solution');
