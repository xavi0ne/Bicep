pipeline {
    agent  any 

    parameters {
        string(defaultValue: 'xtorres1@live.com', description: 'Email Address of the recipient list', name: 'RecipientList')
        string(defaultValue: 'torres1', description: 'Subscription Name', name: 'Subscription')
    }

    environment {
        MY_CRED = credentials('Azure_Infra_SP')
        T_ID = credentials('AZURE_TENANT_ID')
        S_ID = credentials('AZURE_SUBSCRIPTION_ID')
    }  
    stages {
        stage ('test') {
            steps {
                withCredentials([azureServicePrincipal('Azure_Infra_SP')]) {
                    script {
                        azureCLI commands: [[exportVariablesString: '', script: 'az configure --defaults group=test-rg'], 
                                            [exportVariablesString: '', script: 'az deployment group what-if --template-file strgtemplate.bicep --parameters strgparameters.json']], 
                                            principalCredentialId: 'Azure_Infra_SP'
                    }
                }        
            } 
        }       
        stage ('deploy') {
            steps {
                withCredentials([azureServicePrincipal('Azure_Infra_SP')]) {
                    script {
                        azureCLI commands: [[exportVariablesString: '', script: 'az configure --defaults group=test-rg'], 
                                            [exportVariablesString: '', script: 'az deployment group create --template-file strgtemplate.bicep --parameters strgparameters.json']], 
                                            principalCredentialId: 'Azure_Infra_SP'
                    }
                }        
            }       
        }
        stage ('post') {
            steps {
                withCredentials([azureServicePrincipal('Azure_Infra_SP')]) {
                    script {
                        bat ''' 
                            az logout
                        '''
                    }
                }
            }
            always {
                echo "Email address of RecipientList is: ${env.RecipientList}"
                emailext attachlog: true, attachmentsPattern: '', body: 'see the results in the attachments', subject: 'Commission SQL with dependencies', to: env.RecipientList
            }
        } 
    }    
        
}