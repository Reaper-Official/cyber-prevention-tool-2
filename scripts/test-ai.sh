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
