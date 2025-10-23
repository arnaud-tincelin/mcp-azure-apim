# MCP Azure APIM Workshop

This workshop demonstrates how to use Azure API Management (APIM) to expose an existing REST API as a Model-Context-Protocol (MCP) Server. The MCP Server can then be consumed as a tool by various clients, including AI agents built with Azure AI services.

What you will learn in this workshop:

- deploy an Azure infrastructure with [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) (`azd`)
- expose a rest API on a MCP Server on an APIM
- call the MCP Server from different clients:
  - a python script using the [fastmcp](https://pypi.org/project/fastmcp/) library
  - a python script using the [azure-ai-agents](https://pypi.org/project/azure-ai-agents/) library
- call the MCP Server through a [GitHub Copilot MCP tool](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/extend-copilot-chat-with-mcp?tool=vscode)
- add a security layer on the MCP Server through APIM policies

The workshop leverages the public [Setlist.fm API](https://api.setlist.fm/docs/1.0/index.html) as an example. It provisions the necessary Azure infrastructure using Bicep and the Azure Developer CLI (`azd`).
[Setlist.fm](https://www.setlist.fm/) is a collaborative online platform dedicated to documenting setlists—the lists of songs performed by artists or bands during concerts. Unlike official setlists, Setlist.fm focuses on what was actually played at live events.

## Documentation

- https://learn.microsoft.com/en-us/azure/api-management/mcp-server-overview
- https://devblogs.microsoft.com/foundry/announcing-model-context-protocol-support-preview-in-azure-ai-foundry-agent-service/
- https://devblogs.microsoft.com/blog/connect-once-integrate-anywhere-with-mcps

## Workshop

[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/bmoussaud/mcp-azure-apim)

### 1. Configure Azure Resources

This project is using `azd` to configure the Azure Resources

```bash
azd auth login
azd up
```

You will be prompted for where to deploy the infrastructure:

```bash
New environment 'dev' created and set as default
? Select an Azure Subscription to use: 25. xxxxx-qqqqqqq-xxxxx (111111111-1111-1111-1111-11111111)
? Pick a resource group to use: 1. Create a new resource group
? Select a location to create the resource group in: 50. (US) East US 2 (eastus2)
? Enter a name for the new resource group: rm-mcp-dev
```

This repository is configured using Azure Bicep, which defines the following resources:

1. **API Management** manages APIs for the application, providing a gateway for API calls, used to MCP Feature to expose API
2. **Application Insights** monitors application performance and usage, providing insights into the application's health.
3. **Log Analytics Workspace** collects and analyzes log data from various resources for monitoring and troubleshooting.
4. **AI Foundry** deploys AI models, specifically a GPT-4.1 mini model for inference.
5. **SetlistFM API** provides access to the SetlistFM API, allowing users to retrieve setlist data using APIM.
6. **Named Value for API Key** stores the API key securely for accessing the SetlistFM API.
7. **Application Registration** in EntraID to manage OAuth2 Permission Scopes.

### 2. Expose API as an MCP Server

Go the Azure Portal https://portal.azure.com, select the APIM instance and MCP Servers (preview)
Create a MCP Server, expose API as an MCP Server

- API: `SetList FM`
- API Operations: `Search for Artists, Search for Setlists`
- Display Name: `SetlistFM MCP`
- Name: `setlistfm-mcp`
  Note: this value must match the value in .vscode/mcp.json and src/python/.env

![MCP Azure APIM](img/mcp_azure_apim.png)

Test SetList FM API:

```bash
# the script displays the latest setlist performed by The Weeknd
./src/shell/test_api.sh
```

The MCP Server is ready!

### 3. Setup Python environment

```bash
cd src/python
uv venv --clear
source .venv/bin/activate
uv sync
```

### 4. Fastapi MCP Client (Python)

`mcp_client.py` uses a library acting as MCP Client. It lists the exposed tools, and call them: `searchForArtists(coldplay)` and `searchForSetlists(Blondshell)`

```bash
uv run mcp_client.py
```

Sample Output


> 🔗 Testing connection to https://mcp-azure-apim-api-management-dev.azure-api.net/setlistfm-mcp/mcp...  
> ✅ Successfully authenticated!  
> 🔧 Available tools (2):  
> [...]  
> 🔗 Search for artists with 'Coldplay' in the name  
> | Name                                 | URL                                                                               |
> | ------------------------------------ | --------------------------------------------------------------------------------- |
> [...]  
> ------------------------------------------------------------------------------------------------------------------------------
> 🔗 Get a list of setlists for Blondshell  
> 🎤 23-09-2025 · History (Toronto)  
> Tour: The Clearing  
> Link: https://www.setlist.fm/setlist/wolf-alice/2025/history-toronto-on-canada-2b47f072.html  
> [...]  
> 👋 Closing client...  


### 5. Github Copilot MCP Tool (vscode)

Github Copilot in the [Agent Mode](https://code.visualstudio.com/blogs/2025/02/24/introducing-copilot-agent-mode) can include external tools defined in the `mcp.json` file.

In this workshop, this file was automatically generated by the `azd up` command. You can review the content of the file in [mcp.json](./.vscode/mcp.json).

Note: The generation can be manually triggered with the following command `azd hooks run preprovision`

To call the MCP tool from copilot, type the following text in the copilot chat:

```bash
#searchForArtists coldplay
```

Copilot should request you to validate the usage of the MCP tool:

![mcp tool](img/mcp_github_copilot_chat.png)


#### Demo: MCP and Github Copilot Agent Mode
<video src="https://github.com/user-attachments/assets/fa736a42-af49-4124-8d43-7abde7525d77" width="600" autoplay loop muted>
   Your browser does not support the video tag.
</video>


### 6. Custom Agent on Azure Ai Foundry (Python)

MCP is designed to provides tools to any agent. This is a sample where `azure_ai_agent_mcp.py` uses the [Azure Agent Service](https://learn.microsoft.com/en-us/python/api/overview/azure/ai-agents-readme?view=azure-python) library to create an **Agent in Azure AI Foundry** configured to use the `SetlistFM MCP Server` as tool.

```bash
uv run azure_ai_agent_mcp.py
```

Sample Output:

> Setting up Setlist FM plugin https://mcp-azure-apim-api-management-dev.azure-api.net/setlistfm-mcp/mcp  
> [...]  
> Conversation:  
> USER: Can you provide details about recent concerts and setlists in 2025 performed by the band Wolf Alice? Provide the average setlist length and the most frequently played songs.  
> ASSISTANT: In 2025, Wolf Alice performed multiple concerts with a variety of setlists mostly from their tour "The Clearing" and some intimate live shows. Here are some key details:  
> [...]

Once the conversation is finished, it is possible to view the executed thread in the [AI Foundry Portal](http://ai.azure.com):

![MCP Azure AI Foundry](img/mcp_ai_foundry.png)

![MCP Azure AI Foundry Thread Info](img/mcp_ai_foundry_thread_info.png)

### 7. MCP Policies in APIM (EntraID)

As the MCP server has it own policy layer, there are several scenario that can be implemented.

- to set a rate limiting on the MCP side to protect the API part
- to manage inbound authentication, authorization (EntraID / OAuth2)
- to manage outbund authentication, authorization to the backend api (Headers)
- to update the request document or the response document

The steps to define the MCP policy are:

1. Open the azure portal and select the APIM instance
1. Select the left side `MCP Servers` and open the `mcp-setlist-fm` server
1. Open the policies menu

In this sample, an EntraID application has been defined to represent the the MCP Server. The client will perform an EntraId authentication process and the policy validates the provided token and then and header will be added to inject the `Ocp-Apim-Subscription-Key` value.

It is implementing this APIM Pattern: [API Authentication with API Management (APIM) using APIM Policies with Entra ID and App Roles](https://github.com/microsoft/apim-auth-entraid-with-approles/blob/main/README.md)

Doc: [Secure access to MCP servers in API Management / Token-based authentication (OAuth 2.1 with Microsoft Entra ID)](https://learn.microsoft.com/en-us/azure/api-management/secure-mcp-servers#token-based-authentication-oauth-21-with-microsoft-entra-id)

1. paste the following content [src/apim/setlistfm/mcp-policy-setlistfm-entra-id.xml](src/apim/setlistfm/mcp-policy-setlistfm-entra-id.xml) (File generated during the execution of the `azd up` command, you can run the generation again using the `azd hooks run postprovision` command)

```xml
   .....
   <inbound>
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized due Benoit APIM Policy" require-expiration-time="true" require-scheme="Bearer" require-signed-tokens="true">
            <openid-config url="https://login.microsoftonline.com/OAUTH_TENANT_ID/v2.0/.well-known/openid-configuration" />
            <audiences>
                <audience>api://OAUTH_APP_ID</audience>
            </audiences>
            <issuers>
                <issuer>https://sts.windows.net/OAUTH_TENANT_ID/</issuer>
            </issuers>
        </validate-jwt>
		<!-- Set the subscription key header for the backend service -->
		<set-header name="Ocp-Apim-Subscription-Key" exists-action="override">
			<value>SETLISTAPI_SUBSCRIPTION_KEY</value>
		</set-header>
		<base />
	</inbound>
   .....
```

If you run the previous python code, you'll get an `401` error:

```bash
uv run mcp_client.py
```

> 🔗 Testing connection to https://mcp-azure-apim-api-management-dev.azure-api.net/setlistfm-mcp/mcp...  
> ❌ failure : Client error '401 Unauthorized' for url 'https://mcp-azure-apim-api-management-dev.azure-api.net/setlistfm-mcp/mcp'  
> For more information check: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401  
> 👋 Closing client...

Run the following test:

```bash
uv run mcp_client_entra_id.py  default_credential|client_secret|msal
```

what ever the option, the output should be the same when using simple basic authentication using Header.
The options are:

- `default_credential` uses use the magic `DefaultAzureCredential` that support several Azure Authentication features. It re-use the `az login` or the `azd auth login`
- `client_secret` uses the client_id, the client_secret and the tenant_id properties
- `client_secret` uses the client_id, the client_secret and the tenant_id properties and MSAL (Microsoft Authentication Library) library. It’s a client SDK family (for Python, .NET, Java, JavaScript, etc.) that hides the wire details of standard identity protocols. Under the hood, MSAL talks to Microsoft Entra ID (formerly Azure AD) using OAuth 2.0 and OpenID Connect endpoints.

### 8. Clean up

```bash
azd down --force --purge
```
