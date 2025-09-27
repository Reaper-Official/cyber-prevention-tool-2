#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Configuration Complète PhishGuard - TOUS LES FICHIERS
#  Crée tous les fichiers nécessaires pour le projet
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                  Configuration Complète PhishGuard                            ║
║                     Création de TOUS les fichiers                             ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

INSTALL_DIR="/opt/phishguard"
cd "$INSTALL_DIR"

# Backup de l'ancien setup
echo -e "${BLUE}📦 Backup de la configuration actuelle...${NC}"
mkdir -p backups
tar -czf "backups/backup-$(date +%Y%m%d_%H%M%S).tar.gz" \
    --exclude=backups --exclude=.git --exclude=node_modules . 2>/dev/null || true
echo -e "${GREEN}✅ Backup créé dans backups/${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 1. DOCKERFILE BACKEND (Node.js)
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création du Dockerfile Backend (Node.js)...${NC}"

mkdir -p app-full/management

cat > app-full/management/Dockerfile << 'EOF'
# Backend Node.js pour PhishGuard
FROM node:18-alpine

# Métadonnées
LABEL maintainer="PhishGuard Team"
LABEL description="PhishGuard Backend API"

# Installer les dépendances système
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Créer le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production && \
    npm cache clean --force

# Copier le code source
COPY . .

# Variables d'environnement par défaut
ENV NODE_ENV=production \
    PORT=3000

# Exposer le port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node healthcheck.js || exit 1

# Démarrer l'application
CMD ["node", "server.js"]
EOF

echo -e "${GREEN}✅ Dockerfile Backend créé${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 2. DOCKERFILE FRONTEND (Nginx)
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création du Dockerfile Frontend (Nginx)...${NC}"

cat > Dockerfile << 'EOF'
# Frontend Nginx pour PhishGuard
FROM nginx:1.25-alpine

# Métadonnées
LABEL maintainer="PhishGuard Team"
LABEL description="PhishGuard Frontend"

# Copier les fichiers statiques
COPY index.html /usr/share/nginx/html/
COPY app-full /usr/share/nginx/html/app-full
COPY assets /usr/share/nginx/html/assets 2>/dev/null || true

# Copier la configuration Nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Exposer le port
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

echo -e "${GREEN}✅ Dockerfile Frontend créé${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 3. CONFIGURATION NGINX
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création des configurations Nginx...${NC}"

# nginx.conf principal
cat > nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    include /etc/nginx/conf.d/*.conf;
}
EOF

# default.conf pour le site
cat > default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Logs
    access_log /var/log/nginx/phishguard-access.log;
    error_log /var/log/nginx/phishguard-error.log;

    # Sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Frontend statique
    location / {
        try_files $uri $uri/ /index.html;
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    # Proxy vers le backend API
    location /api/ {
        proxy_pass http://backend:3000/;
        proxy_http_version 1.1;
        
        # Headers WebSocket
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers standards
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Cache bypass
        proxy_cache_bypass $http_upgrade;
    }

    # Assets statiques avec cache long
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Interdire l'accès aux fichiers sensibles
    location ~ /\. {
        deny all;
    }

    location ~ \.(env|git|gitignore|htaccess)$ {
        deny all;
    }
}
EOF

echo -e "${GREEN}✅ Configurations Nginx créées${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 4. DOCKER-COMPOSE.YML COMPLET
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création du docker-compose.yml...${NC}"

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  #═══════════════════════════════════════════════════════════════════════
  # Base de données PostgreSQL
  #═══════════════════════════════════════════════════════════════════════
  postgres:
    image: postgres:15-alpine
    container_name: phishguard-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-phishguard}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-phishguard}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d
    networks:
      - phishguard-network
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-phishguard}"]
      interval: 10s
      timeout: 5s
      retries: 5
    command: >
      postgres
      -c max_connections=200
      -c shared_buffers=256MB
      -c effective_cache_size=1GB

  #═══════════════════════════════════════════════════════════════════════
  # Cache Redis
  #═══════════════════════════════════════════════════════════════════════
  redis:
    image: redis:7-alpine
    container_name: phishguard-redis
    restart: unless-stopped
    command: >
      redis-server
      --appendonly yes
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - phishguard-network
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  #═══════════════════════════════════════════════════════════════════════
  # Backend Node.js
  #═══════════════════════════════════════════════════════════════════════
  backend:
    build:
      context: ./app-full/management
      dockerfile: Dockerfile
    container_name: phishguard-backend
    restart: unless-stopped
    environment:
      # Application
      NODE_ENV: ${NODE_ENV:-production}
      PORT: 3000
      
      # Base de données
      DATABASE_URL: ${DATABASE_URL}
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: ${POSTGRES_USER:-phishguard}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-phishguard}
      
      # Redis
      REDIS_URL: redis://redis:6379
      REDIS_HOST: redis
      REDIS_PORT: 6379
      
      # Sécurité
      JWT_SECRET: ${JWT_SECRET}
      SESSION_SECRET: ${SESSION_SECRET}
      
      # APIs externes
      GEMINI_API_KEY: ${GEMINI_API_KEY}
      
      # Email (optionnel)
      SMTP_HOST: ${SMTP_HOST:-}
      SMTP_PORT: ${SMTP_PORT:-587}
      SMTP_USER: ${SMTP_USER:-}
      SMTP_PASSWORD: ${SMTP_PASSWORD:-}
      
      # Application
      APP_URL: ${APP_URL:-http://localhost:8080}
      FRONTEND_URL: ${FRONTEND_URL:-http://localhost:8080}
      
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - phishguard-network
    volumes:
      - ./app-full/management:/app
      - /app/node_modules
      - backend_uploads:/app/uploads
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 10s
      retries: 3

  #═══════════════════════════════════════════════════════════════════════
  # Frontend Nginx
  #═══════════════════════════════════════════════════════════════════════
  frontend:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: phishguard-frontend
    restart: unless-stopped
    ports:
      - "${APP_PORT:-8080}:80"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - phishguard-network
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./default.conf:/etc/nginx/conf.d/default.conf:ro
      - nginx_logs:/var/log/nginx
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 3s
      retries: 3

#═══════════════════════════════════════════════════════════════════════════════
# Volumes persistants
#═══════════════════════════════════════════════════════════════════════════════
volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  backend_uploads:
    driver: local
  nginx_logs:
    driver: local

#═══════════════════════════════════════════════════════════════════════════════
# Réseau isolé
#═══════════════════════════════════════════════════════════════════════════════
networks:
  phishguard-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
EOF

echo -e "${GREEN}✅ docker-compose.yml créé${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 5. FICHIER .ENV COMPLET
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création du fichier .env...${NC}"

# Générer des secrets sécurisés
POSTGRES_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)
SESSION_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
SERVER_IP=$(hostname -I | awk '{print $1}')

cat > .env << EOF
#═══════════════════════════════════════════════════════════════════════════════
# Configuration PhishGuard BASIC
# Généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
#═══════════════════════════════════════════════════════════════════════════════

#───────────────────────────────────────────────────────────────────────────────
# Application
#───────────────────────────────────────────────────────────────────────────────
NODE_ENV=production
APP_PORT=8080
APP_URL=http://${SERVER_IP}:8080
FRONTEND_URL=http://${SERVER_IP}:8080
BACKEND_URL=http://${SERVER_IP}:8080/api

#───────────────────────────────────────────────────────────────────────────────
# Base de données PostgreSQL
#───────────────────────────────────────────────────────────────────────────────
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=phishguard
POSTGRES_PASSWORD=${POSTGRES_PASS}
POSTGRES_DB=phishguard
DATABASE_URL=postgresql://phishguard:${POSTGRES_PASS}@postgres:5432/phishguard

#───────────────────────────────────────────────────────────────────────────────
# Redis
#───────────────────────────────────────────────────────────────────────────────
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_URL=redis://redis:6379

#───────────────────────────────────────────────────────────────────────────────
# Sécurité & Authentication
#───────────────────────────────────────────────────────────────────────────────
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRES_IN=7d
SESSION_SECRET=${SESSION_SECRET}
BCRYPT_ROUNDS=12

#───────────────────────────────────────────────────────────────────────────────
# Gemini AI API (⚠️ OBLIGATOIRE)
#───────────────────────────────────────────────────────────────────────────────
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
GEMINI_MODEL=gemini-pro

#───────────────────────────────────────────────────────────────────────────────
# Configuration Email (Optionnel)
#───────────────────────────────────────────────────────────────────────────────
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM_NAME=PhishGuard Security
SMTP_FROM_EMAIL=

#───────────────────────────────────────────────────────────────────────────────
# Sécurité avancée
#───────────────────────────────────────────────────────────────────────────────
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
CORS_ORIGIN=http://${SERVER_IP}:8080
COOKIE_SECURE=false
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE=lax

#───────────────────────────────────────────────────────────────────────────────
# Upload de fichiers
#───────────────────────────────────────────────────────────────────────────────
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=pdf,doc,docx,xls,xlsx,jpg,jpeg,png,gif

#───────────────────────────────────────────────────────────────────────────────
# Logs
#───────────────────────────────────────────────────────────────────────────────
LOG_LEVEL=info
LOG_FORMAT=combined

#───────────────────────────────────────────────────────────────────────────────
# Timezone
#───────────────────────────────────────────────────────────────────────────────
TZ=Europe/Paris
EOF

chmod 600 .env
echo -e "${GREEN}✅ Fichier .env créé avec secrets générés${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 6. FICHIERS BACKEND ESSENTIELS
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création des fichiers backend essentiels...${NC}"

# healthcheck.js
cat > app-full/management/healthcheck.js << 'EOF'
// Healthcheck pour Docker
const http = require('http');

const options = {
    host: 'localhost',
    port: process.env.PORT || 3000,
    path: '/health',
    timeout: 2000
};

const healthCheck = http.request(options, (res) => {
    console.log(`HEALTHCHECK STATUS: ${res.statusCode}`);
    if (res.statusCode === 200) {
        process.exit(0);
    } else {
        process.exit(1);
    }
});

healthCheck.on('error', (err) => {
    console.error('HEALTHCHECK ERROR:', err);
    process.exit(1);
});

healthCheck.end();
EOF

# .dockerignore
cat > app-full/management/.dockerignore << 'EOF'
node_modules
npm-debug.log
.env
.env.local
.git
.gitignore
*.md
.DS_Store
coverage
.vscode
.idea
*.log
dist
build
EOF

# .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build
dist/
build/
*.tgz

# Docker
.dockerignore
docker-compose.override.yml

# Backups
backups/
*.backup

# Uploads
uploads/
EOF

echo -e "${GREEN}✅ Fichiers backend créés${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 7. README.md COMPLET
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création du README.md...${NC}"

cat > README.md << 'EOF'
# 🛡️ PhishGuard BASIC

Plateforme open-source de formation à la cybersécurité par simulation de phishing éthique.

## 🚀 Démarrage Rapide

\`\`\`bash
# 1. Cloner le projet
git clone https://github.com/Reaper-Official/cyber-prevention-tool.git
cd cyber-prevention-tool

# 2. Configuration
cp .env.example .env
nano .env  # Configurer GEMINI_API_KEY

# 3. Lancer l'application
docker-compose up -d

# 4. Accéder à l'application
open http://localhost:8080
\`\`\`

## 📋 Prérequis

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum
- 10GB espace disque

## 🏗️ Architecture

\`\`\`
├── Frontend (Nginx)      → Port 8080
├── Backend (Node.js)     → Port 3000
├── PostgreSQL            → Port 5432
└── Redis                 → Port 6379
\`\`\`

## 📖 Documentation

- [Installation](docs/installation.md)
- [Configuration](docs/configuration.md)
- [API](docs/api.md)

## 🔐 Sécurité

**Usage autorisé uniquement pour:**
- Formation interne d'entreprise
- Sensibilisation à la cybersécurité
- Tests autorisés et documentés

## 📝 License

Internal Use Only - Voir [LICENSE](LICENSE)
EOF

echo -e "${GREEN}✅ README.md créé${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# 8. MAKEFILE POUR COMMANDES UTILES
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔧 Création du Makefile...${NC}"

cat > Makefile << 'EOF'
.PHONY: help install start stop restart logs build clean

help:
	@echo "PhishGuard - Commandes disponibles:"
	@echo "  make install   - Installation complète"
	@echo "  make start     - Démarrer l'application"
	@echo "  make stop      - Arrêter l'application"
	@echo "  make restart   - Redémarrer l'application"
	@echo "  make logs      - Voir les logs"
	@echo "  make build     - Reconstruire les images"
	@echo "  make clean     - Nettoyer Docker"

install:
	@echo "Installation de PhishGuard..."
	docker-compose build --no-cache
	docker-compose up -d
	@echo "✅ Installation terminée!"
	@echo "Accédez à: http://localhost:8080"

start:
	docker-compose up -d

stop:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

build:
	docker-compose build --no-cache

clean:
	docker-compose down -v
	docker system prune -af
EOF

echo -e "${GREEN}✅ Makefile créé${NC}\n"

#═══════════════════════════════════════════════════════════════════════════════
# RÉSUMÉ ET INSTRUCTIONS
#═══════════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    ✅ TOUS LES FICHIERS CRÉÉS                                 ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📁 Fichiers créés:${NC}"
cat << EOF
   ✅ Dockerfile                        (Frontend Nginx)
   ✅ app-full/management/Dockerfile     (Backend Node.js)
   ✅ docker-compose.yml                 (Orchestration complète)
   ✅ nginx.conf                         (Configuration Nginx)
   ✅ default.conf                       (Virtual host)
   ✅ .env                               (Variables d'environnement)
   ✅ .gitignore                         (Fichiers à ignorer)
   ✅ app-full/management/healthcheck.js (Healthcheck backend)
   ✅ README.md                          (Documentation)
   ✅ Makefile                           (Commandes utiles)
EOF
echo ""

echo -e "${BLUE}📊 Architecture déployée:${NC}"
cat << EOF
   🌐 Frontend (Nginx)     → http://${SERVER_IP}:8080
   🔧 Backend (Node.js)    → http://backend:3000 (interne)
   🗄️  PostgreSQL          → postgres:5432 (interne)
   🔴 Redis               → redis:6379 (interne)
EOF
echo ""

echo -e "${YELLOW}⚠️  CONFIGURATION REQUISE:${NC}"
echo ""
echo "1. Obtenez une clé API Gemini (gratuite):"
echo -e "   ${BLUE}https://aistudio.google.com/app/apikey${NC}"
echo ""
echo "2. Configurez la clé dans .env:"
echo -e "   ${GREEN}nano .env${NC}"
echo -e "   Remplacer: ${RED}YOUR_GEMINI_API_KEY_HERE${NC}"
echo ""

echo -e "${BLUE}🚀 Commandes de démarrage:${NC}"
echo ""
echo -e "${GREEN}# Méthode 1: Avec Make${NC}"
echo "make install          # Installation complète"
echo "make start            # Démarrer"
echo "make logs             # Voir les logs"
echo ""
echo -e "${GREEN}# Méthode 2: Avec Docker Compose${NC}"
echo "docker-compose build --no-cache"
echo "docker-compose up -d"
echo "docker-compose logs -f"
echo ""

echo -e "${CYAN}🎉 Configuration terminée avec succès!${NC}\n"