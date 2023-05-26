param (
    [Parameter(Mandatory=$true)]
    [ValidatePattern("^[M]?RFC-\d{4}-\d{4}")]
    [string]$RFC,
    
    [Parameter(Mandatory=$False)]
    [switch]$Interactive
)

$rfcfile = './extracts/' + $RFC + '.csv'
if(!(Test-Path $rfcfile) )
{
    Write-Host "RFC extract file, $rfcfile does not exist, abort the process"
    exit 1
}

# Read values from .csv file
$values = Import-Csv -Path $rfcfile 

#Create an empty array
$vmarray = @()

#loop through each row
foreach ($row in $values) {
    $vmDetails = [ordered]@{"Name"=$row.Name; "IP_Address"=$row.IP_Address; "RoleTagValue"=$row.RoleTagValue; `
    "DeviceIdTagValue"=$row.DeviceIdTagValue; "FinancialTagValue"=$row.FinancialTagValue; "ImageTagValue"=$row.ImageTagValue; `
    "Schedule"=$row.Schedule; "Size"=$row.Size; "StorageSKU"=$row.StorageSKU; "OsDiskSize"=$row.OsDiskSize; "AvailabilitySet"=$row.AvailabilitySet; `
    "DataDiskSKU"=$row.DataDiskSKU; "DataDisk"=$row.DataDisk; "Domain"=$row.Domain}
    $vmarray += $vmDetails
}
# Generate the JSON parameters file template using az cli
az bicep generate-params --file './AzureVM/maindeployVM.bicep' 

# Load ARM JSON parameters file template
$template = Get-Content -Path './AzureVM/maindeployVM.parameters.json' -Raw | ConvertFrom-Json

# Replace placeholders in template with values from .csv file
$vmProperties = $vmarray
    if ($template.parameters.vms) {
        $template.parameters.vms.value = $vmProperties
    }
$vnetResourceGroup = $values.vnetResourceGroup
    if ($template.parameters.vnetResourceGroup) {
        $template.parameters.vnetResourceGroup.value = [string]$vnetResourceGroup -replace '(\s+$)', ''
    }
$vnet = $values.vnet
    if ($template.parameters.vnet) {
        $template.parameters.vnet.value = [string]$vnet -replace '(\s+$)', ''
    }
$subnet = $values.subnet
    if ($template.parameters.subnet) {
        $template.parameters.subnet.value = [string]$subnet -replace '(\s+$)', ''
    }
$location = $values.location
    if ($template.parameters.location) {
        $template.parameters.location.value = [string]$location -replace '(\s+$)', ''
    }
$financialTag = $values.financialTag
    if ($template.parameters.financialTag) {
        $template.parameters.financialTag.value = [string]$financialTag -replace '(\s+$)', ''
    }
$subscription = $values.subscription
    if ($template.parameters.subscription) {
        $template.parameters.subscription.value = [string]$subscription -replace '(\s+$)', ''
    }
$imageResourceGroup = $values.imageResourceGroup
    if ($template.parameters.imageResourceGroup) {
        $template.parameters.imageResourceGroup.value = [string]$imageResourceGroup -replace '(\s+$)', ''
    }
$imageVersion = $values.imageVersion
    if ($template.parameters.imageVersion) {
        $template.parameters.imageVersion.value = [string]$imageVersion -replace '(\s+$)', ''
    }
$kvName = $values.kvName
    if ($template.parameters.kvName) {
        $template.parameters.kvName.value = [string]$kvName -replace '(\s+$)', ''
    }
$resourceGroup = $values.resourceGroup
    if ($template.parameters.resourceGroup) {
        $template.parameters.resourceGroup.value = [string]$resourceGroup -replace '(\s+$)', ''
    }


# Write the updated template to a file
$jsonfile = './AzureVM/' + $RFC + '.parameters.json'
$template | ConvertTo-Json -Depth 100 | Set-Content -Path $jsonfile
