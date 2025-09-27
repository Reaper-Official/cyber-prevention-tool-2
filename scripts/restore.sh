#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script de restauration PhishGuard
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./backups"
DB_CONTAINER="phishguard-postgres"
DB_USER="${POSTGRES_USER:-phishguard}"
DB_NAME="${POSTGRES_DB:-phishguard}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          ♻️  Restauration PhishGuard                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier que le conteneur est en cours d'exécution
if ! docker ps | grep -q "$DB_CONTAINER"; then
    echo -e "${RED}❌ Le conteneur PostgreSQL n'est pas en cours d'exécution${NC}"
    echo -e "${YELLOW}Démarrez PhishGuard avec: ./scripts/start.sh${NC}"
    exit 1
fi

# Lister les backups disponibles
echo -e "${BLUE}📋 Backups disponibles:${NC}"
echo ""

if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/phishguard_db_*.sql.gz 2>/dev/null)" ]; then
    echo -e "${RED}❌ Aucun backup trouvé dans $BACKUP_DIR${NC}"
    exit 1
fi

BACKUPS=($(ls -t "$BACKUP_DIR"/phishguard_db_*.sql.gz))
for i in "${!BACKUPS[@]}"; do
    SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
    DATE=$(basename "${BACKUPS[$i]}" | grep -oP '\d{8}_\d{6}')
    FORMATTED_DATE=$(echo "$DATE" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
    echo -e "  ${GREEN}[$i]${NC} $FORMATTED_DATE - $SIZE"
done

echo ""
read -p "$(echo -e ${YELLOW}Choisir le numéro du backup à restaurer [0]:${NC} )" BACKUP_CHOICE
BACKUP_CHOICE=${BACKUP_CHOICE:-0}

if [ "$BACKUP_CHOICE" -lt 0 ] || [ "$BACKUP_CHOICE" -ge "${#BACKUPS[@]}" ]; then
    echo -e "${RED}❌ Choix invalide${NC}"
    exit 1
fi

BACKUP_FILE="${BACKUPS[$BACKUP_CHOICE]}"
echo ""
echo -e "${YELLOW}⚠️  ATTENTION: Cette opération va écraser la base de données actuelle${NC}"
read -p "$(echo -e ${YELLOW}Confirmer la restauration ? [o/N]:${NC} )" CONFIRM

if [[ ! $CONFIRM =~ ^[Oo]$ ]]; then
    echo -e "${BLUE}Restauration annulée${NC}"
    exit 0
fi

# Restauration
echo ""
echo -e "${BLUE}♻️  Restauration en cours...${NC}"

# Arrêter le backend pour éviter les connexions
docker compose stop backend

# Supprimer et recréer la base
docker compose exec -T postgres psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS ${DB_NAME};" 2>/dev/null || true
docker compose exec -T postgres psql -U "$DB_USER" -c "CREATE DATABASE ${DB_NAME};"

# Restaurer depuis le backup
gunzip < "$BACKUP_FILE" | docker compose exec -T postgres psql -U "$DB_USER" "$DB_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Restauration réussie${NC}"
    
    # Redémarrer le backend
    docker compose start backend
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✅ Restauration terminée avec succès             ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}❌ Échec de la restauration${NC}"
    docker compose start backend
    exit 1
fi

echo ""
