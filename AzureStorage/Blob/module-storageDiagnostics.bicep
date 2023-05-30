param logAnalyitcsID string
param eventHubID string
param eventHub string
param storageDetails object

resource storageDeployment 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: '${storageDetails.storageName}sg'
}
resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' =  {
    scope: storageDeployment
    name: 'diagnostics00'
    properties: {
      workspaceId: logAnalyitcsID
      eventHubAuthorizationRuleId: eventHubID
      eventHubName: eventHub
      metrics: [
        {
          category: 'Transaction'
          enabled: true
        }
      ]
    }
  }
  resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' existing = {
    parent: storageDeployment
    name: 'default'
  }
  resource diagnosticsBlob 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
    scope: storageAccountBlob
    name: 'diagnostics01'
    properties: {
      workspaceId: logAnalyitcsID
      eventHubAuthorizationRuleId: eventHubID
      eventHubName: eventHub
      logs: [
        {
          category: 'storageRead'
          enabled: true
        }
      ]
    }
  }
