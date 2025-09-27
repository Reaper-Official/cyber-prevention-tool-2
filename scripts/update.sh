#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script de mise à jour PhishGuard
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🔄 Mise à jour PhishGuard                    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier si c'est un dépôt git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Ce n'est pas un dépôt Git${NC}"
    exit 1
fi

# Backup avant mise à jour
echo -e "${BLUE}💾 Backup avant mise à jour...${NC}"
./scripts/backup.sh

# Récupérer les modifications
echo ""
echo -e "${BLUE}📥 Récupération des modifications...${NC}"
git fetch origin

# Afficher les changements
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}📊 Changements disponibles:${NC}"
git log HEAD..origin/$CURRENT_BRANCH --oneline --decorate --graph | head -20

echo ""
read -p "$(echo -e ${YELLOW}Continuer la mise à jour ? [O/n]:${NC} )" CONFIRM
CONFIRM=${CONFIRM:-o}

if [[ ! $CONFIRM =~ ^[Oo]$ ]]; then
    echo -e "${BLUE}Mise à jour annulée${NC}"
    exit 0
fi

# Pull des modifications
echo ""
echo -e "${BLUE}⬇️  Téléchargement des modifications...${NC}"
git pull origin $CURRENT_BRANCH

# Rebuild des images
echo ""
echo -e "${BLUE}🔨 Reconstruction des images Docker...${NC}"
docker compose build --no-cache

# Redémarrage
echo ""
echo -e "${BLUE}🔄 Redémarrage de l'application...${NC}"
docker compose down
docker compose up -d

# Vérification
sleep 5
echo ""
echo -e "${BLUE}🔍 Vérification de la mise à jour...${NC}"
./scripts/health-check.sh

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅ Mise à jour terminée avec succès            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
