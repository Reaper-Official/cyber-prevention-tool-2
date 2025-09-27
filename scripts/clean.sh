#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script de nettoyage PhishGuard
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🧹 Nettoyage PhishGuard                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠️  Cette opération va:${NC}"
echo "  - Arrêter tous les conteneurs"
echo "  - Supprimer les volumes (données)"
echo "  - Nettoyer les images Docker"
echo "  - Libérer de l'espace disque"
echo ""

read -p "$(echo -e ${RED}Êtes-vous sûr ? [o/N]:${NC} )" CONFIRM

if [[ ! $CONFIRM =~ ^[Oo]$ ]]; then
    echo -e "${BLUE}Nettoyage annulé${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🛑 Arrêt des services...${NC}"
docker compose down -v

echo -e "${BLUE}🗑️  Suppression des images PhishGuard...${NC}"
docker images | grep phishguard | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true

echo -e "${BLUE}🧹 Nettoyage Docker...${NC}"
docker system prune -af --volumes

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      ✅ Nettoyage terminé                             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}💡 Pour réinstaller:${NC} ${GREEN}./scripts/start.sh${NC}"
echo ""
