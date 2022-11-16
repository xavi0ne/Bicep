param location string
param sqlServerName string
param sqlServerAdminLogin string
@secure()
param sqlAdminPswd string
param sqldbName string
param sId string
param tenantId string
param AADlogin string
param storageEndpoint string
param strgsubId string
param workspaceId string
param eventHubName string
param storageContainerPath string
param sqlDatabaseSku object = {
  name: 'GP_Gen5'
  tier: 'GeneralPurpose'
  family: 'Gen5'
  capacity: 2
}
param sqlPEName string
param virtualNetworkName string
param subnetName string
param sqlPEDnsGroupName string
param sqlDNSZoneName string
param peVNETLinkName string
param OBFWRuleName string
param stgContributorName string
param eHubRuleId string


resource sqlserver 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    financial: 'oit-taz-core'
  }
  kind: 'v12.0'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlAdminPswd
    version: '12.0'
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: AADlogin
      sid: sId
      tenantId: tenantId
      azureADOnlyAuthentication: false
    }
    restrictOutboundNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
}
resource stgContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing= {
  scope: resourceGroup('automate-sql')
  name: stgContributorName
}

resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sqlserver.name, resourceGroup().id, strgsubId)
  properties: {
    roleDefinitionId: stgContributor.id
    principalType: 'ServicePrincipal'
    principalId: sqlserver.identity.principalId
    description: 'Storage Blob Contributor'
  }
}
resource sqlOBFWRule 'Microsoft.Sql/servers/outboundFirewallRules@2022-05-01-preview' = {
  name: OBFWRuleName
  parent: sqlserver
}
resource sqlbdm 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  parent: sqlserver
  name: sqldbName
  location: location
  sku: sqlDatabaseSku
  kind: 'v12.0,user,vcore'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    licenseType: 'LicenseIncluded'
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
  }
}
resource sqlAuditing 'Microsoft.Sql/servers/auditingSettings@2022-02-01-preview' = {
  parent: sqlserver
  name: 'default'
  properties: {
    retentionDays: 0
    auditActionsAndGroups: [
        'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
        'FAILED_DATABASE_AUTHENTICATION_GROUP'
        'BATCH_COMPLETED_GROUP'
        'BACKUP_RESTORE_GROUP'
        'DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP'
        'DATABASE_OBJECT_PERMISSION_CHANGE_GROUP'
        'DATABASE_PERMISSION_CHANGE_GROUP'
        'DATABASE_PRINCIPAL_IMPERSONATION_GROUP'
        'FAILED_DATABASE_AUTHENTICATION_GROUP'
        'SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP'
        'SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP'
        'BATCH_COMPLETED_GROUP'
        'DATABASE_OWNERSHIP_CHANGE_GROUP'
    ]
    isAzureMonitorTargetEnabled: false
    isManagedIdentityInUse: true
    state: 'Enabled'
    storageEndpoint: storageEndpoint
    storageAccountSubscriptionId: strgsubId
  }
  dependsOn: [
    sqlRoleAssignment
  ]
}
resource configureSQLServerAudit 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'SendtoEventHubandLaW'
  scope: sqlbdm
  properties: {
    workspaceId: workspaceId
    eventHubName: eventHubName
    eventHubAuthorizationRuleId: eHubRuleId
    metrics: [
      {
        enabled: true
      }
    ]
  }
}
resource enableSQLDefender 'Microsoft.Sql/servers/advancedThreatProtectionSettings@2022-05-01-preview' = {
  parent: sqlserver
  name: 'Default'
  properties: {
    state: 'Enabled'
  }
  dependsOn: [
    configureSQLServerAudit
  ]
}

resource enableSQLVulnerabilityScan 'Microsoft.Sql/servers/vulnerabilityAssessments@2022-05-01-preview' = {
  parent: sqlserver
  name: 'default'
  properties: {
    recurringScans: {
      emails: [
        'string'
      ]
      emailSubscriptionAdmins: false
      isEnabled: true
    }
    storageContainerPath: storageContainerPath
  }
  dependsOn: [
    enableSQLDefender
  ]
}
module sqlPE 'automate-sql-pe.bicep' = {
  name: sqlPEName
  scope: resourceGroup('automate-sql')
  params: {
    location: location
    sqlDNSZoneName: sqlDNSZoneName
    sqlPEDnsGroupName: sqlPEDnsGroupName
    sqlPEName: sqlPEName
    sqlServerName: sqlServerName
    subnetName: subnetName
    virtualNetworkName: virtualNetworkName
    peVNETLinkName: peVNETLinkName 
  }
}
output sqlserverId string = sqlserver.id
output storagepath string = storageContainerPath
