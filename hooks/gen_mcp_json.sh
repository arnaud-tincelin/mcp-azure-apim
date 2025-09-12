#!/bin/bash

azd env get-values > .env
source .env

cat <<EOF > .vscode/mcp.json
{
	"servers": {
		"setlistfm": {
			"url": "${SETLISTAPI_MCP_ENDPOINT}",
			"type": "http",
			"headers": {
				"Ocp-Apim-Subscription-Key":"${SETLISTAPI_SUBSCRIPTION_KEY}"
			}
		}
	},
	"inputs": []
}
EOF