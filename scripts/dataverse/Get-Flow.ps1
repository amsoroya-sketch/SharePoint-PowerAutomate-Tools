<#
.SYNOPSIS
    Downloads and analyzes Power Automate flows from the environment.

.PARAMETER FlowId
    The GUID of the flow to download.

.PARAMETER Name
    Search for flow by name (partial match).

.PARAMETER ListAll
    List all cloud flows in the environment.

.PARAMETER Export
    Export the solution containing the flow.

.EXAMPLE
    .\Get-Flow.ps1 -ListAll

.EXAMPLE
    .\Get-Flow.ps1 -Name "Permission"

.EXAMPLE
    .\Get-Flow.ps1 -FlowId "17c3f8fe-0fec-f011-8407-000d3ae1ff22"
#>

param(
    [string]$FlowId,
    [string]$Name,
    [switch]$ListAll,
    [switch]$Export
)

Write-Host "=== Power Automate Flow Manager ===" -ForegroundColor Cyan
Write-Host ""

# List all flows
if ($ListAll) {
    Write-Host "Listing all Cloud Flows..." -ForegroundColor Yellow
    Write-Host ""

    $result = & pac org fetch --xml "<fetch><entity name='workflow'><attribute name='name'/><attribute name='workflowid'/><attribute name='statecode'/><attribute name='statuscode'/><attribute name='modifiedon'/><filter><condition attribute='category' operator='eq' value='5'/></filter><order attribute='modifiedon' descending='true'/></entity></fetch>" 2>&1

    Write-Host $result
    Write-Host ""
    Write-Host "=== Done ===" -ForegroundColor Green
    exit 0
}

# Search by name
if ($Name) {
    Write-Host "Searching for flows containing: $Name" -ForegroundColor Yellow
    Write-Host ""

    $result = & pac org fetch --xml "<fetch><entity name='workflow'><attribute name='name'/><attribute name='workflowid'/><attribute name='statecode'/><attribute name='statuscode'/><filter><condition attribute='category' operator='eq' value='5'/><condition attribute='name' operator='like' value='%$Name%'/></filter></entity></fetch>" 2>&1

    Write-Host $result
    Write-Host ""
    Write-Host "=== Done ===" -ForegroundColor Green
    exit 0
}

# Get specific flow
if ($FlowId) {
    Write-Host "Fetching flow: $FlowId" -ForegroundColor Yellow
    Write-Host ""

    $result = & pac org fetch --xml "<fetch><entity name='workflow'><attribute name='name'/><attribute name='workflowid'/><attribute name='statecode'/><attribute name='description'/><attribute name='solutionid'/><filter><condition attribute='workflowid' operator='eq' value='$FlowId'/></filter></entity></fetch>" 2>&1

    Write-Host $result

    if ($Export) {
        Write-Host ""
        Write-Host "To export, use: pac solution export --name [SolutionName] --path [output.zip]" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "=== Done ===" -ForegroundColor Green
    exit 0
}

# No parameters - show help
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  .\Get-Flow.ps1 -ListAll              # List all cloud flows"
Write-Host "  .\Get-Flow.ps1 -Name 'Permission'    # Search by name"
Write-Host "  .\Get-Flow.ps1 -FlowId 'guid-here'   # Get specific flow"
Write-Host ""
