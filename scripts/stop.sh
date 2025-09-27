#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script d'arrêt PhishGuard
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🛑 Arrêt de PhishGuard                       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Options
REMOVE_VOLUMES=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--volumes) REMOVE_VOLUMES=true ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --volumes    Supprimer aussi les volumes (données)"
            echo "  -h, --help       Afficher cette aide"
            exit 0
            ;;
        *) echo "Option inconnue: $1"; exit 1 ;;
    esac
    shift
done

# Arrêter les services
if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${YELLOW}⚠️  Arrêt ET suppression des volumes (données)...${NC}"
    docker compose down -v
    echo -e "${GREEN}✅ Services arrêtés et volumes supprimés${NC}"
else
    echo -e "${BLUE}🛑 Arrêt des services...${NC}"
    docker compose down
    echo -e "${GREEN}✅ Services arrêtés (données conservées)${NC}"
fi

echo ""
echo -e "${BLUE}💡 Pour redémarrer:${NC} ${GREEN}./scripts/start.sh${NC}"
echo -e "${BLUE}💡 Pour supprimer les données:${NC} ${GREEN}./scripts/stop.sh --volumes${NC}"
echo ""
