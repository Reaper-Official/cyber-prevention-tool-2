#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script d'affichage des logs
#═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          📋 Logs PhishGuard                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Options
SERVICE=""
FOLLOW=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--follow) FOLLOW=true ;;
        -s|--service) SERVICE="$2"; shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --follow           Suivre les logs en temps réel"
            echo "  -s, --service NAME     Logs d'un service spécifique"
            echo "  -h, --help             Afficher cette aide"
            echo ""
            echo "Services disponibles: backend, frontend, postgres, redis"
            exit 0
            ;;
        *) echo "Option inconnue: $1"; exit 1 ;;
    esac
    shift
done

# Menu si aucun service spécifié
if [ -z "$SERVICE" ]; then
    echo -e "${BLUE}📋 Choisissez un service:${NC}"
    echo ""
    echo "  1) Tous les services"
    echo "  2) Backend (API)"
    echo "  3) Frontend (Nginx)"
    echo "  4) PostgreSQL"
    echo "  5) Redis"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Votre choix [1-5]:${NC} )" CHOICE
    
    case $CHOICE in
        1) SERVICE="" ;;
        2) SERVICE="backend" ;;
        3) SERVICE="frontend" ;;
        4) SERVICE="postgres" ;;
        5) SERVICE="redis" ;;
        *) echo -e "${RED}❌ Choix invalide${NC}"; exit 1 ;;
    esac
fi

# Afficher les logs
echo ""
if [ "$FOLLOW" = true ]; then
    echo -e "${GREEN}📡 Logs en temps réel (Ctrl+C pour quitter)${NC}"
    echo ""
    docker compose logs -f $SERVICE
else
    echo -e "${GREEN}📄 Derniers logs${NC}"
    echo ""
    docker compose logs --tail=100 $SERVICE
fi
