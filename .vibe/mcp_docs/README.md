# Documentation MCP OpenModelica - MicroPythonMCU

## Introduction

Ce dossier contient la documentation relative à la connexion et à l'utilisation du serveur MCP (Modelica Client Protocol) pour OpenModelica.

## Fichiers

- [openmodelica_mcp_connection.md](openmodelica_mcp_connection.md) - Connexion au serveur MCP
- [project_summary.md](project_summary.md) - Résumé du projet MicroPythonMCU

## Connexion rapide

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "mcp-protocol-version: 2025-11-25" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"Client","version":"1.0"}}}'
```
