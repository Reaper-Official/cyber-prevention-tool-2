#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Création des scripts utilitaires pour PhishGuard
#  À exécuter dans le répertoire scripts/
#═══════════════════════════════════════════════════════════════════════════════

# Créer le dossier scripts
mkdir -p scripts
cd scripts

#═══════════════════════════════════════════════════════════════════════════════
# 1. start.sh - Démarrage de l'application
#═══════════════════════════════════════════════════════════════════════════════

cat > start.sh << 'EOF'
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
    echo -e "${BLUE}Création depuis .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ Fichier .env créé${NC}"
    echo -e "${YELLOW}⚠️  Pensez à configurer vos variables d'environnement${NC}"
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
EOF

chmod +x start.sh

#═══════════════════════════════════════════════════════════════════════════════
# 2. stop.sh - Arrêt de l'application
#═══════════════════════════════════════════════════════════════════════════════

cat > stop.sh << 'EOF'
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
EOF

chmod +x stop.sh

#═══════════════════════════════════════════════════════════════════════════════
# 3. backup.sh - Sauvegarde de la base de données
#═══════════════════════════════════════════════════════════════════════════════

cat > backup.sh << 'EOF'
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
EOF

chmod +x backup.sh

#═══════════════════════════════════════════════════════════════════════════════
# 4. restore.sh - Restauration de la base de données
#═══════════════════════════════════════════════════════════════════════════════

cat > restore.sh << 'EOF'
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
EOF

chmod +x restore.sh

#═══════════════════════════════════════════════════════════════════════════════
# 5. test-ai.sh - Tester les providers IA
#═══════════════════════════════════════════════════════════════════════════════

cat > test-ai.sh << 'EOF'
#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Script de test des providers IA
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_URL="http://localhost:3000/api"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🧪 Test des Providers IA                     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier que l'API est accessible
echo -e "${BLUE}🔍 Vérification de l'API...${NC}"
if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${RED}❌ L'API n'est pas accessible${NC}"
    echo -e "${YELLOW}Démarrez PhishGuard avec: ./scripts/start.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✅ API accessible${NC}"
echo ""

# Menu de sélection
echo -e "${BLUE}🤖 Choisissez le provider à tester:${NC}"
echo ""
echo "  1) 🤖 Ollama (local)"
echo "  2) ✨ Google Gemini"
echo "  3) 🎭 Anthropic Claude"
echo "  4) 💬 OpenAI ChatGPT"
echo ""

read -p "$(echo -e ${YELLOW}Votre choix [1-4]:${NC} )" CHOICE

case $CHOICE in
    1)
        PROVIDER="ollama"
        read -p "$(echo -e ${YELLOW}URL Ollama [http://localhost:11434]:${NC} )" OLLAMA_URL
        OLLAMA_URL=${OLLAMA_URL:-http://localhost:11434}
        read -p "$(echo -e ${YELLOW}Modèle [llama2]:${NC} )" MODEL
        MODEL=${MODEL:-llama2}
        
        echo ""
        echo -e "${BLUE}🧪 Test de Ollama...${NC}"
        RESPONSE=$(curl -s -X POST "$API_URL/ai/test" \
            -H "Content-Type: application/json" \
            -d "{\"provider\":\"$PROVIDER\",\"apiKey\":null,\"config\":{\"baseURL\":\"$OLLAMA_URL\",\"model\":\"$MODEL\"}}")
        ;;
        
    2)
        PROVIDER="gemini"
        read -sp "$(echo -e ${YELLOW}Clé API Gemini:${NC} )" API_KEY
        echo ""
        read -p "$(echo -e ${YELLOW}Modèle [gemini-pro]:${NC} )" MODEL
        MODEL=${MODEL:-gemini-pro}
        
        echo ""
        echo -e "${BLUE}🧪 Test de Gemini...${NC}"
        RESPONSE=$(curl -s -X POST "$API_URL/ai/test" \
            -H "Content-Type: application/json" \
            -d "{\"provider\":\"$PROVIDER\",\"apiKey\":\"$API_KEY\",\"config\":{\"model\":\"$MODEL\"}}")
        ;;
        
    3)
        PROVIDER="claude"
        read -sp "$(echo -e ${YELLOW}Clé API Claude:${NC} )" API_KEY
        echo ""
        read -p "$(echo -e ${YELLOW}Modèle [claude-3-sonnet-20240229]:${NC} )" MODEL
        MODEL=${MODEL:-claude-3-sonnet-20240229}
        
        echo ""
        echo -e "${BLUE}🧪 Test de Claude...${NC}"
        RESPONSE=$(curl -s -X POST "$API_URL/ai/test" \
            -H "Content-Type: application/json" \
            -d "{\"provider\":\"$PROVIDER\",\"apiKey\":\"$API_KEY\",\"config\":{\"model\":\"$MODEL\"}}")
        ;;
        
    4)
        PROVIDER="openai"
        read -sp "$(echo -e ${YELLOW}Clé API OpenAI:${NC} )" API_KEY
        echo ""
        read -p "$(echo -e ${YELLOW}Modèle [gpt-3.5-turbo]:${NC} )" MODEL
        MODEL=${MODEL:-gpt-3.5-turbo}
        
        echo ""
        echo -e "${BLUE}🧪 Test de OpenAI...${NC}"
        RESPONSE=$(curl -s -X POST "$API_URL/ai/test" \
            -H "Content-Type: application/json" \
            -d "{\"provider\":\"$PROVIDER\",\"apiKey\":\"$API_KEY\",\"config\":{\"model\":\"$MODEL\"}}")
        ;;
        
    *)
        echo -e "${RED}❌ Choix invalide${NC}"
        exit 1
        ;;
esac

# Analyser la réponse
echo ""
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           ✅ Test réussi !                            ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📝 Réponse de l'IA:${NC}"
    echo "$RESPONSE" | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"$//'
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           ❌ Test échoué                              ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Erreur:${NC}"
    echo "$RESPONSE" | grep -o '"error":"[^"]*"' | sed 's/"error":"//;s/"$//' || echo "$RESPONSE"
fi

echo ""
EOF

chmod +x test-ai.sh

#═══════════════════════════════════════════════════════════════════════════════
# 6. logs.sh - Afficher les logs
#═══════════════════════════════════════════════════════════════════════════════

cat > logs.sh << 'EOF'
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
EOF

chmod +x logs.sh

#═══════════════════════════════════════════════════════════════════════════════
# 7. clean.sh - Nettoyage complet
#═══════════════════════════════════════════════════════════════════════════════

cat > clean.sh << 'EOF'
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
EOF

chmod +x clean.sh

#═══════════════════════════════════════════════════════════════════════════════
# 8. setup-dev.sh - Configuration environnement de développement
#═══════════════════════════════════════════════════════════════════════════════

cat > setup-dev.sh << 'EOF'
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
EOF

chmod +x setup-dev.sh

#═══════════════════════════════════════════════════════════════════════════════
# 9. health-check.sh - Vérification de la santé du système
#═══════════════════════════════════════════════════════════════════════════════

cat > health-check.sh << 'EOF'
#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  Vérification de santé du système
#═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🏥 Health Check PhishGuard                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

ERRORS=0

# 1. Vérifier Docker
echo -e "${BLUE}🐳 Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "   ${GREEN}✅ Docker installé ($(docker --version | cut -d' ' -f3 | sed 's/,//'))${NC}"
else
    echo -e "   ${RED}❌ Docker non installé${NC}"
    ((ERRORS++))
fi

# 2. Vérifier Docker Compose
echo -e "${BLUE}🐳 Docker Compose...${NC}"
if docker compose version &> /dev/null; then
    echo -e "   ${GREEN}✅ Docker Compose installé ($(docker compose version --short))${NC}"
else
    echo -e "   ${RED}❌ Docker Compose non installé${NC}"
    ((ERRORS++))
fi

# 3. Vérifier les conteneurs
echo -e "${BLUE}📦 Conteneurs...${NC}"
if docker ps > /dev/null 2>&1; then
    RUNNING=$(docker compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    TOTAL=$(docker compose ps --services 2>/dev/null | wc -l)
    
    if [ "$RUNNING" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Tous les conteneurs actifs ($RUNNING/$TOTAL)${NC}"
    elif [ "$TOTAL" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  Certains conteneurs inactifs ($RUNNING/$TOTAL)${NC}"
        ((ERRORS++))
    else
        echo -e "   ${YELLOW}⚠️  Aucun conteneur démarré${NC}"
    fi
else
    echo -e "   ${RED}❌ Impossible de vérifier les conteneurs${NC}"
    ((ERRORS++))
fi

# 4. Vérifier le backend
echo -e "${BLUE}🔧 Backend API...${NC}"
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    HEALTH=$(curl -s http://localhost:3000/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo -e "   ${GREEN}✅ Backend opérationnel (status: $HEALTH)${NC}"
else
    echo -e "   ${RED}❌ Backend inaccessible${NC}"
    ((ERRORS++))
fi

# 5. Vérifier le frontend
echo -e "${BLUE}🌐 Frontend...${NC}"
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Frontend accessible${NC}"
else
    echo -e "   ${RED}❌ Frontend inaccessible${NC}"
    ((ERRORS++))
fi

# 6. Vérifier PostgreSQL
echo -e "${BLUE}🗄️  PostgreSQL...${NC}"
if docker compose exec -T postgres pg_isready -U phishguard > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ PostgreSQL opérationnel${NC}"
else
    echo -e "   ${RED}❌ PostgreSQL non accessible${NC}"
    ((ERRORS++))
fi

# 7. Vérifier Redis
echo -e "${BLUE}🔴 Redis...${NC}"
if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Redis opérationnel${NC}"
else
    echo -e "   ${RED}❌ Redis non accessible${NC}"
    ((ERRORS++))
fi

# 8. Vérifier les ports
echo -e "${BLUE}🔌 Ports...${NC}"
for port in 8080 3000 5432 6379; do
    if ss -tuln 2>/dev/null | grep -q ":$port " || netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "   ${GREEN}✅ Port $port ouvert${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Port $port fermé${NC}"
    fi
done

# 9. Vérifier l'espace disque
echo -e "${BLUE}💾 Espace disque...${NC}"
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo -e "   ${GREEN}✅ Espace disque OK (${DISK_USAGE}% utilisé)${NC}"
elif [ "$DISK_USAGE" -lt 90 ]; then
    echo -e "   ${YELLOW}⚠️  Espace disque faible (${DISK_USAGE}% utilisé)${NC}"
else
    echo -e "   ${RED}❌ Espace disque critique (${DISK_USAGE}% utilisé)${NC}"
    ((ERRORS++))
fi

# 10. Vérifier la RAM
echo -e "${BLUE}🧠 Mémoire...${NC}"
AVAILABLE_RAM=$(free -m | awk 'NR==2{print $7}')
if [ "$AVAILABLE_RAM" -gt 1000 ]; then
    echo -e "   ${GREEN}✅ RAM disponible: ${AVAILABLE_RAM}MB${NC}"
else
    echo -e "   ${YELLOW}⚠️  RAM faible: ${AVAILABLE_RAM}MB${NC}"
fi

# Résumé
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        ✅ Système en parfait état !                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║        ⚠️  $ERRORS problème(s) détecté(s)                  ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}💡 Pour corriger:${NC}"
    echo -e "   - Redémarrer: ${GREEN}./scripts/start.sh${NC}"
    echo -e "   - Voir les logs: ${GREEN}./scripts/logs.sh${NC}"
    echo -e "   - Nettoyer: ${GREEN}./scripts/clean.sh${NC}"
    exit 1
fi
EOF

chmod +x health-check.sh

#═══════════════════════════════════════════════════════════════════════════════
# 10. update.sh - Mise à jour de l'application
#═══════════════════════════════════════════════════════════════════════════════

cat > update.sh << 'EOF'
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
EOF

chmod +x update.sh

#═══════════════════════════════════════════════════════════════════════════════
# 11. README.md pour le dossier scripts
#═══════════════════════════════════════════════════════════════════════════════

cat > README.md << 'EOF'
# 🛠️ Scripts Utilitaires PhishGuard

Ce dossier contient tous les scripts pour gérer PhishGuard facilement.

## 📋 Liste des scripts

### 🚀 Gestion de l'application

| Script | Description | Usage |
|--------|-------------|-------|
| `start.sh` | Démarrer l'application | `./scripts/start.sh` |
| `stop.sh` | Arrêter l'application | `./scripts/stop.sh` |
| `logs.sh` | Afficher les logs | `./scripts/logs.sh` |
| `health-check.sh` | Vérifier la santé du système | `./scripts/health-check.sh` |

### 💾 Backup & Restauration

| Script | Description | Usage |
|--------|-------------|-------|
| `backup.sh` | Sauvegarder la base de données | `./scripts/backup.sh` |
| `restore.sh` | Restaurer depuis un backup | `./scripts/restore.sh` |

### 🤖 IA & Tests

| Script | Description | Usage |
|--------|-------------|-------|
| `test-ai.sh` | Tester les providers IA | `./scripts/test-ai.sh` |

### 🛠️ Développement

| Script | Description | Usage |
|--------|-------------|-------|
| `setup-dev.sh` | Configurer l'environnement dev | `./scripts/setup-dev.sh` |

### 🧹 Maintenance

| Script | Description | Usage |
|--------|-------------|-------|
| `clean.sh` | Nettoyer complètement | `./scripts/clean.sh` |
| `update.sh` | Mettre à jour l'application | `./scripts/update.sh` |

## 🚀 Exemples d'utilisation

### Démarrage rapide
```bash
./scripts/start.sh
```

### Voir les logs en temps réel
```bash
./scripts/logs.sh --follow
./scripts/logs.sh --service backend
```

### Backup automatique
```bash
# Backup simple
./scripts/backup.sh

# Backup dans cron (tous les jours à 2h)
0 2 * * * cd /opt/phishguard && ./scripts/backup.sh
```

### Test des providers IA
```bash
./scripts/test-ai.sh
```

### Vérification de santé
```bash
# Check manuel
./scripts/health-check.sh

# En monitoring (chaque minute)
watch -n 60 ./scripts/health-check.sh
```

### Arrêt avec suppression des données
```bash
./scripts/stop.sh --volumes
```

### Nettoyage complet
```bash
./scripts/clean.sh
```

### Mise à jour
```bash
./scripts/update.sh
```

## 🔧 Configuration

### Variables d'environnement

Les scripts utilisent les variables du fichier `.env` :

```env
POSTGRES_USER=phishguard
POSTGRES_PASSWORD=xxx
POSTGRES_DB=phishguard
```

### Personnalisation

Vous pouvez modifier les variables en haut de chaque script :

```bash
# Exemple dans backup.sh
BACKUP_DIR="./backups"          # Dossier de backup
DB_CONTAINER="phishguard-postgres"  # Nom du conteneur
```

## 📊 Automatisation

### Backup automatique (cron)

```bash
# Éditer le crontab
crontab -e

# Ajouter ces lignes
# Backup tous les jours à 2h du matin
0 2 * * * cd /opt/phishguard && ./scripts/backup.sh >> /var/log/phishguard-backup.log 2>&1

# Health check toutes les heures
0 * * * * cd /opt/phishguard && ./scripts/health-check.sh >> /var/log/phishguard-health.log 2>&1
```

### Monitoring avec systemd

Créer un service de monitoring :

```bash
# /etc/systemd/system/phishguard-monitor.service
[Unit]
Description=PhishGuard Health Monitor
After=docker.service

[Service]
Type=oneshot
ExecStart=/opt/phishguard/scripts/health-check.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
```

```bash
# /etc/systemd/system/phishguard-monitor.timer
[Unit]
Description=Run PhishGuard Health Check every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Activer :
```bash
sudo systemctl enable phishguard-monitor.timer
sudo systemctl start phishguard-monitor.timer
```

## 🐛 Dépannage

### Script ne s'exécute pas

```bash
# Vérifier les permissions
chmod +x scripts/*.sh

# Vérifier la syntaxe
bash -n scripts/start.sh
```

### Erreur "command not found"

Assurez-vous d'être dans le répertoire racine du projet :

```bash
cd /opt/phishguard
./scripts/start.sh
```

### Problème de connexion Docker

```bash
# Vérifier Docker
sudo systemctl status docker

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker
```

## 📝 Notes

- Tous les scripts utilisent `set -e` pour arrêter en cas d'erreur
- Les backups sont automatiquement compressés (.gz)
- Les logs sont colorés pour meilleure lisibilité
- Les anciens backups (>7 jours) sont automatiquement supprimés

## 🔗 Liens utiles

- [Documentation principale](../README.md)
- [Configuration IA](../docs/ai-config.md)
- [Troubleshooting](../docs/troubleshooting.md)

---

**💡 Astuce** : Ajoutez `alias pg='cd /opt/phishguard && ./scripts'` dans votre `~/.bashrc` pour un accès rapide !
EOF

# Message final
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║      ✅ Tous les scripts ont été créés !              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "📁 Scripts créés dans: ./scripts/"
echo ""
echo "📋 Liste des scripts:"
echo "   ✅ start.sh         - Démarrer PhishGuard"
echo "   ✅ stop.sh          - Arrêter PhishGuard"
echo "   ✅ backup.sh        - Sauvegarder la DB"
echo "   ✅ restore.sh       - Restaurer la DB"
echo "   ✅ test-ai.sh       - Tester les IA"
echo "   ✅ logs.sh          - Afficher les logs"
echo "   ✅ clean.sh         - Nettoyer tout"
echo "   ✅ setup-dev.sh     - Config dev"
echo "   ✅ health-check.sh  - Vérifier la santé"
echo "   ✅ update.sh        - Mettre à jour"
echo "   ✅ README.md        - Documentation"
echo ""
echo "🚀 Utilisation:"
echo "   chmod +x scripts/*.sh"
echo "   ./scripts/start.sh"
echo ""