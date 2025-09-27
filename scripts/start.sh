#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script de démarrage PhishGuard
#═══════════════════════════════════════════════════════════════════════════════

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🚀 Démarrage de PhishGuard                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker n'est pas installé${NC}"
    exit 1
fi

# Vérifier docker-compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose n'est pas installé${NC}"
    exit 1
fi

# Vérifier le fichier .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Fichier .env non trouvé${NC}"
    echo -e "${BLUE}Création du fichier .env...${NC}"
    
    # Générer un mot de passe sécurisé
    POSTGRES_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32 2>/dev/null || echo "changeme_$(date +%s)")
    
    # Créer le fichier .env
    cat > .env << ENV_EOF
# PhishGuard Configuration
NODE_ENV=production
APP_PORT=8080
FRONTEND_URL=http://localhost:8080

# Database
POSTGRES_USER=phishguard
POSTGRES_PASSWORD=${POSTGRES_PASS}
POSTGRES_DB=phishguard
DATABASE_URL=postgresql://phishguard:${POSTGRES_PASS}@postgres:5432/phishguard

# Redis
REDIS_URL=redis://redis:6379

# Note: Les clés API IA sont configurées via l'interface web
# Ne PAS stocker les clés API ici pour des raisons de sécurité
ENV_EOF
    
    echo -e "${GREEN}✅ Fichier .env créé avec mot de passe sécurisé${NC}"
    echo -e "${YELLOW}⚠️  Configurez les clés API depuis l'interface web (http://localhost:8080)${NC}"
fi

# Démarrer les services
echo -e "${BLUE}🐳 Démarrage des conteneurs Docker...${NC}"
docker compose up -d

# Attendre que les services soient prêts
echo -e "${BLUE}⏳ Attente du démarrage des services...${NC}"
sleep 5

# Vérifier l'état des conteneurs
echo ""
echo -e "${BLUE}📊 État des services:${NC}"
docker compose ps

# Vérifier la santé du backend
echo ""
echo -e "${BLUE}🔍 Vérification du backend...${NC}"
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend opérationnel${NC}"
else
    echo -e "${YELLOW}⚠️  Backend en cours de démarrage...${NC}"
fi

# Afficher les URLs
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ PhishGuard démarré avec succès           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📱 URLs d'accès:${NC}"
echo -e "   Frontend:    ${GREEN}http://localhost:8080${NC}"
echo -e "   Backend API: ${GREEN}http://localhost:3000${NC}"
echo -e "   Health:      ${GREEN}http://localhost:3000/health${NC}"
echo ""
echo -e "${BLUE}📖 Commandes utiles:${NC}"
echo -e "   ${GREEN}docker compose logs -f${NC}         # Voir les logs"
echo -e "   ${GREEN}docker compose ps${NC}              # Voir l'état"
echo -e "   ${GREEN}docker compose stop${NC}            # Arrêter"
echo -e "   ${GREEN}docker compose restart${NC}         # Redémarrer"
echo ""
