#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Configuration environnement de développement
#═══════════════════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🛠️  Configuration Environnement Dev               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Installer les dépendances backend
echo -e "${BLUE}📦 Installation des dépendances backend...${NC}"
cd backend
npm install
cd ..

echo -e "${GREEN}✅ Dépendances backend installées${NC}"

# Créer docker-compose.override.yml pour le dev
echo ""
echo -e "${BLUE}🐳 Configuration Docker pour le développement...${NC}"

cat > docker-compose.override.yml << 'OVERRIDE_EOF'
version: '3.8'

services:
  backend:
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      NODE_ENV: development
    command: npm run dev
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port

  frontend:
    volumes:
      - ./frontend/public:/usr/share/nginx/html:ro
OVERRIDE_EOF

echo -e "${GREEN}✅ docker-compose.override.yml créé${NC}"

# Configuration VS Code
echo ""
echo -e "${BLUE}🎨 Configuration VS Code...${NC}"

mkdir -p .vscode

cat > .vscode/settings.json << 'VSCODE_EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
VSCODE_EOF

cat > .vscode/launch.json << 'LAUNCH_EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Docker: Attach to Node",
      "remoteRoot": "/app",
      "port": 9229,
      "restart": true,
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
LAUNCH_EOF

cat > .vscode/extensions.json << 'EXT_EOF'
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-azuretools.vscode-docker",
    "github.copilot",
    "ms-vscode.vscode-typescript-next"
  ]
}
EXT_EOF

echo -e "${GREEN}✅ Configuration VS Code créée${NC}"

# Résumé
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    ✅ Environnement de développement configuré        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🚀 Prochaines étapes:${NC}"
echo ""
echo -e "  1. Démarrer en mode dev:"
echo -e "     ${GREEN}docker-compose up${NC}"
echo ""
echo -e "  2. Le backend redémarre automatiquement à chaque changement"
echo ""
echo -e "  3. Déboguer avec VS Code:"
echo -e "     ${GREEN}F5${NC} pour attacher le debugger"
echo ""
echo -e "  4. Les logs sont visibles en temps réel"
echo ""
