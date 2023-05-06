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
$stgarray = @()

#loop through each row
foreach ($row in $values) {
    $storageDetails = [ordered]@{"storageName"=$row.names;"ipAddress"=$row.ips}
    $stgarray += $storageDetails
}
# Generate the JSON parameters file template using az cli
az bicep generate-params --file './AzureStorage/blobstorage1.bicep' 

# Load ARM JSON parameters file template
$template = Get-Content -Path './AzureStorage/blobstorage1.parameters.json' -Raw | ConvertFrom-Json

# Replace placeholders in template with values from .csv file
$storageProperties = $stgarray
    if ($template.parameters.storageDetails) {
        $template.parameters.storageDetails.value = $storageProperties
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

# Write the updated template to a file
$jsonfile = './AzureStorage/' + $RFC + 'parameters.json'
$template | ConvertTo-Json -Depth 10 -compress | Set-Content -Path $jsonfile

az account set --name $values.subscriptionId
az deployment group create --resource-group $values.resourceGroup --template-file ./AzureStorage/blobstorage1.bicep --parameters $jsonfile
