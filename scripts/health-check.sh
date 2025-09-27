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
