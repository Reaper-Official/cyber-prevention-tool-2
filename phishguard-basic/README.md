# 🛡️ PhishGuard BASIC - Multi-IA Platform

**Plateforme open-source de formation en cybersécurité par simulation de phishing avec support multi-IA.**

## 🤖 IA Supportées

- **🤖 Ollama** - Local & gratuit (Llama, Mistral, etc.)
- **✨ Google Gemini** - Puissant & rapide
- **🎭 Anthropic Claude** - Précis & éthique  
- **💬 OpenAI ChatGPT** - Polyvalent

## 🚀 Installation Rapide

```bash
# 1. Cloner
git clone https://github.com/username/phishguard-basic.git
cd phishguard-basic

# 2. Lancer
docker-compose up -d

# 3. Accéder
open http://localhost:8080
```

## ⚙️ Configuration de l'IA

1. Ouvrez l'interface : http://localhost:8080
2. Cliquez sur **⚙️ Configuration IA**
3. Choisissez votre provider IA
4. Entrez votre clé API
5. Testez la connexion
6. Sauvegardez

### Obtenir les clés API

- **Gemini** : https://aistudio.google.com/app/apikey
- **Claude** : https://console.anthropic.com/
- **OpenAI** : https://platform.openai.com/api-keys
- **Ollama** : Installation locale (pas de clé requise)

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Frontend  │────▶│   Backend    │────▶│  PostgreSQL  │
│   (Nginx)   │     │  (Node.js)   │     │              │
└─────────────┘     └──────────────┘     └──────────────┘
                            │
                    ┌───────┴───────┐
                    ▼               ▼
            ┌──────────┐    ┌──────────────┐
            │  Redis   │    │  Multi-IA    │
            └──────────┘    │ Ollama       │
                            │ Gemini       │
                            │ Claude       │
                            │ ChatGPT      │
                            └──────────────┘
```

## 📖 Documentation

- [Installation](docs/installation.md)
- [Configuration IA](docs/ai-config.md)
- [API Reference](docs/api.md)

## 🔐 Sécurité

- ✅ Clés API chiffrées en mémoire
- ✅ Non stockées en base de données
- ✅ Connexion HTTPS recommandée en production
- ✅ Rate limiting activé

## 📝 License

MIT License - Usage éthique uniquement

---

**Made with ❤️ for safer internet**
