#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script de backup PhishGuard
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_CONTAINER="phishguard-postgres"
DB_USER="${POSTGRES_USER:-phishguard}"
DB_NAME="${POSTGRES_DB:-phishguard}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          💾 Backup PhishGuard                         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Créer le dossier de backup
mkdir -p "$BACKUP_DIR"

# Vérifier que le conteneur est en cours d'exécution
if ! docker ps | grep -q "$DB_CONTAINER"; then
    echo -e "${RED}❌ Le conteneur PostgreSQL n'est pas en cours d'exécution${NC}"
    echo -e "${YELLOW}Démarrez PhishGuard avec: ./scripts/start.sh${NC}"
    exit 1
fi

# Backup de la base de données
echo -e "${BLUE}📦 Backup de la base de données PostgreSQL...${NC}"
BACKUP_FILE="$BACKUP_DIR/phishguard_db_${TIMESTAMP}.sql.gz"

docker compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backup réussi:${NC} $BACKUP_FILE"
    
    # Afficher la taille
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${BLUE}📊 Taille:${NC} $SIZE"
else
    echo -e "${RED}❌ Échec du backup${NC}"
    exit 1
fi

# Backup des fichiers uploadés (si le dossier existe)
if [ -d "backend/uploads" ]; then
    echo ""
    echo -e "${BLUE}📂 Backup des fichiers uploadés...${NC}"
    UPLOADS_BACKUP="$BACKUP_DIR/phishguard_uploads_${TIMESTAMP}.tar.gz"
    
    tar -czf "$UPLOADS_BACKUP" backend/uploads 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup uploads réussi:${NC} $UPLOADS_BACKUP"
        SIZE=$(du -h "$UPLOADS_BACKUP" | cut -f1)
        echo -e "${BLUE}📊 Taille:${NC} $SIZE"
    fi
fi

# Nettoyage des anciens backups (garder les 7 derniers)
echo ""
echo -e "${BLUE}🧹 Nettoyage des anciens backups...${NC}"
ls -t "$BACKUP_DIR"/phishguard_db_*.sql.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null
ls -t "$BACKUP_DIR"/phishguard_uploads_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null
echo -e "${GREEN}✅ Anciens backups supprimés (conservation: 7 derniers)${NC}"

# Résumé
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ Backup terminé avec succès               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📁 Dossier de backup:${NC} $BACKUP_DIR"
echo -e "${BLUE}📝 Fichiers:${NC}"
ls -lh "$BACKUP_DIR" | tail -n +2 | head -n 5
echo ""
