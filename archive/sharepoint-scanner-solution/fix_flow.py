import json

# Read the flow file
with open('validate_check_extracted/Workflows/SharePointPermissionScanner-17C3F8FE-0FEC-F011-8407-000D3AE1FF22.json', 'r', encoding='utf-8') as f:
    flow = json.load(f)

# Get the actions
actions = flow['properties']['definition']['actions']

# Remove Catch_Scope from inside Try_Scope
if 'Catch_Scope' in actions['Try_Scope']['actions']:
    del actions['Try_Scope']['actions']['Catch_Scope']

# Add Catch_Scope at top level with proper runAfter
actions['Catch_Scope'] = {
    "actions": {
        "Set_HasError_True": {
            "runAfter": {},
            "metadata": {
                "operationMetadataId": "2d93ebed-cc47-4ab2-a059-00bec0f356de"
            },
            "type": "SetVariable",
            "inputs": {
                "name": "HasError",
                "value": True
            }
        },
        "Get_Error_Details": {
            "runAfter": {
                "Set_HasError_True": ["Succeeded"]
            },
            "metadata": {
                "operationMetadataId": "error-details-compose"
            },
            "type": "Compose",
            "inputs": "@result('Try_Scope')"
        },
        "Update_Scan_Session_Failed": {
            "runAfter": {
                "Get_Error_Details": ["Succeeded"]
            },
            "metadata": {
                "operationMetadataId": "update-session-failed"
            },
            "type": "OpenApiConnection",
            "inputs": {
                "host": {
                    "connectionName": "shared_commondataserviceforapps",
                    "operationId": "UpdateRecord",
                    "apiId": "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"
                },
                "parameters": {
                    "entityName": "sp_scansessions",
                    "recordId": "@variables('ScanSessionId')",
                    "item/sp_status": 100000002,
                    "item/sp_completedon": "@utcNow()",
                    "item/sp_errormessage": "@string(outputs('Get_Error_Details'))"
                },
                "authentication": {
                    "type": "Raw",
                    "value": "@json(decodeBase64(triggerOutputs().headers['X-MS-APIM-Tokens']))['$ConnectionKey']"
                }
            }
        }
    },
    "runAfter": {
        "Try_Scope": ["Failed", "TimedOut"]
    },
    "metadata": {
        "operationMetadataId": "catch-scope-id"
    },
    "type": "Scope"
}

# Add Finally_Scope at top level
actions['Finally_Scope'] = {
    "actions": {
        "Check_No_Error": {
            "actions": {
                "Update_Scan_Session_Completed": {
                    "runAfter": {},
                    "metadata": {
                        "operationMetadataId": "update-session-completed"
                    },
                    "type": "OpenApiConnection",
                    "inputs": {
                        "host": {
                            "connectionName": "shared_commondataserviceforapps",
                            "operationId": "UpdateRecord",
                            "apiId": "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"
                        },
                        "parameters": {
                            "entityName": "sp_scansessions",
                            "recordId": "@variables('ScanSessionId')",
                            "item/sp_status": 100000000,
                            "item/sp_completedon": "@utcNow()",
                            "item/sp_totalfolders": "@variables('TotalFolders')",
                            "item/sp_folderswithuniquepermissions": "@variables('FoldersWithUniquePerms')"
                        },
                        "authentication": {
                            "type": "Raw",
                            "value": "@json(decodeBase64(triggerOutputs().headers['X-MS-APIM-Tokens']))['$ConnectionKey']"
                        }
                    }
                }
            },
            "else": {
                "actions": {}
            },
            "runAfter": {},
            "expression": {
                "equals": [
                    "@variables('HasError')",
                    False
                ]
            },
            "metadata": {
                "operationMetadataId": "check-no-error-condition"
            },
            "type": "If"
        }
    },
    "runAfter": {
        "Try_Scope": ["Succeeded", "Failed", "Skipped", "TimedOut"],
        "Catch_Scope": ["Succeeded", "Failed", "Skipped", "TimedOut"]
    },
    "metadata": {
        "operationMetadataId": "finally-scope-id"
    },
    "type": "Scope"
}

# Write the fixed flow back
with open('validate_check_extracted/Workflows/SharePointPermissionScanner-17C3F8FE-0FEC-F011-8407-000D3AE1FF22.json', 'w', encoding='utf-8') as f:
    json.dump(flow, f, indent=2)

print("Flow JSON fixed successfully!")
print("- Removed Catch_Scope from inside Try_Scope")
print("- Added Catch_Scope at top level with runAfter: Try_Scope [Failed, TimedOut]")
print("- Added Get_Error_Details Compose action")
print("- Added Update_Scan_Session_Failed action")
print("- Added Finally_Scope at top level")
print("- Added Check_No_Error condition with Update_Scan_Session_Completed")
