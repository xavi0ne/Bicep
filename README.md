WHAT IS BICEP?

Bicep is a domain-specific language (DSL) that uses declarative syntax to deploy Azure resources. In a Bicep file, you define the infrastructure you want to deploy to Azure, and then use that file throughout the development lifecycle to repeatedly deploy your infrastructure. Your resources are deployed in a consistent manner.

Bicep provides concise syntax, reliable type safety, and support for code reuse. Bicep offers a first-class authoring experience for your infrastructure-as-code solutions in Azure.

BENEFITS 

Improves the authoring experience

Provides intellisense and syntax validation

Automatic dependency management

Modularity – Bicep Code in manageable parts for related resources

Preview changes using ‘what-if’ operations before deployment

Simplified lifecycle management of code

PRE-REQUISITES

To create Bicep files, you need a good Bicep editor. Recommend:

Visual Studio Code - If you don't already have Visual Studio Code, install it.

Bicep extension for Visual Studio Code. Visual Studio Code with the Bicep extension provides language support and resource autocompletion. The extension helps you create and validate Bicep files. To install the extension, search for bicep in the VS Code Extensions tab or in the Visual Studio marketplace.

To Deploy BICEP, you’ll need:

Azure CLI Version 2.20.0 or later. (recommended) – BICEP CLI install is automatic.
	and/or 
PowerShell 5.6.0 or later. Requires manual install of BICEP CLI PowerShell module

Microsoft reference - https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually








