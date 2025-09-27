#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Setup Ultra-Rapide PhishGuard - Crée TOUT en 1 commande
#═══════════════════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀 Setup Ultra-Rapide PhishGuard                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier qu'on est dans le bon dossier
if [ ! -f "package.json" ] && [ ! -d "backend" ]; then
    echo -e "${RED}❌ Structure de projet non trouvée${NC}"
    echo -e "${YELLOW}Exécutez d'abord le script de création du projet complet${NC}"
    exit 1
fi

# 1. Créer docker-compose.yml s'il n'existe pas
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${BLUE}📝 Création de docker-compose.yml...${NC}"
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: phishguard-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-phishguard}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-phishguard}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - phishguard-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U phishguard"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: phishguard-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - phishguard-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: phishguard-backend
    restart: unless-stopped
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: 3000
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      FRONTEND_URL: ${FRONTEND_URL:-http://localhost:8080}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - phishguard-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: phishguard-frontend
    restart: unless-stopped
    ports:
      - "${APP_PORT:-8080}:80"
    depends_on:
      - backend
    networks:
      - phishguard-network

volumes:
  postgres_data:
  redis_data:

networks:
  phishguard-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}✅ docker-compose.yml créé${NC}"
fi

# 2. Créer .env s'il n'existe pas
if [ ! -f ".env" ]; then
    echo -e "${BLUE}📝 Création du fichier .env...${NC}"
    
    POSTGRES_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32 2>/dev/null || echo "phishguard123")
    
    cat > .env << EOF
NODE_ENV=production
APP_PORT=8080
FRONTEND_URL=http://localhost:8080

POSTGRES_USER=phishguard
POSTGRES_PASSWORD=${POSTGRES_PASS}
POSTGRES_DB=phishguard
DATABASE_URL=postgresql://phishguard:${POSTGRES_PASS}@postgres:5432/phishguard

REDIS_URL=redis://redis:6379
EOF
    
    chmod 600 .env
    echo -e "${GREEN}✅ .env créé${NC}"
fi

# 3. Créer les dossiers manquants
echo -e "${BLUE}📁 Création des dossiers...${NC}"
mkdir -p {backend,frontend,database,scripts}
mkdir -p backend/src
mkdir -p frontend/public

# 4. Créer les Dockerfiles s'ils n'existent pas
if [ ! -f "backend/Dockerfile" ]; then
    echo -e "${BLUE}📝 Création backend/Dockerfile...${NC}"
    cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
CMD ["node", "src/server.js"]
EOF
fi

if [ ! -f "frontend/Dockerfile" ]; then
    echo -e "${BLUE}📝 Création frontend/Dockerfile...${NC}"
    cat > frontend/Dockerfile << 'EOF'
FROM nginx:alpine
COPY public /usr/share/nginx/html
COPY default.conf /etc/nginx/conf.d/default.conf 2>/dev/null || true
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
fi

# 5. Créer database/init.sql si manquant
if [ ! -f "database/init.sql" ]; then
    echo -e "${BLUE}📝 Création database/init.sql...${NC}"
    cat > database/init.sql << 'EOF'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS ai_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider VARCHAR(50) NOT NULL,
    config JSONB,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
fi

# Résumé
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅ Configuration créée avec succès !            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier la structure
echo -e "${BLUE}📊 Structure du projet:${NC}"
ls -la

echo ""
echo -e "${BLUE}🚀 Démarrage:${NC}"
docker-compose up -d

echo ""
echo -e "${GREEN}✅ PhishGuard démarré !${NC}"
echo -e "${BLUE}📱 Accès: http://localhost:8080${NC}"