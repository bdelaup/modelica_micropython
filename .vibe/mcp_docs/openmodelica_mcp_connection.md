# Connexion au serveur MCP OpenModelica

## Informations de connexion
- **URL :** `http://localhost:3000/mcp`
- **Version protocole :** 2025-11-25
- **Serveur :** OMEdit MCP Server v1.0.0
- **Processus :** OMEdit.exe

## Méthode de connexion

Requêtes HTTP POST avec en-têtes :
```
Content-Type: application/json
mcp-protocol-version: 2025-11-25
```

## Exemple d'initialisation

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "mcp-protocol-version: 2025-11-25" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"ClientName","version":"1.0"}}}'
```

## Outils disponibles

### Lecture
- `getClassNames` - Lister les classes Modelica chargées
- `getSourceCode` - Code source d'une classe
- `getTotalModel` - Modèle complet avec dépendances
- `getModelInfo` - Infos sur un modèle
- `getComponentInfo` - Infos sur un composant
- `getConnectionInfo` - Infos sur une connexion
- `listShapes` - Lister les formes graphiques
- `getCoordinateSystem` - Système de coordonnées

### Écriture
- `setSourceCode` - Remplacer le code source
- `createClass` - Créer une nouvelle classe
- `setComponentInfo` - Modifier un composant
- `setConnectionInfo` - Modifier une connexion
- `removeShape` - Supprimer une forme
- `setCoordinateSystem` - Définir le système de coordonnées

### Simulation
- `checkModel` - Vérifier l'équilibre
- `simulate` - Simuler un modèle
- `stopSimulation` - Arrêter une simulation
- `getSimulationInfo` - Infos sur une simulation

### Actions
- `newModel`, `openModel`, `saveModel`, `closeModel`
