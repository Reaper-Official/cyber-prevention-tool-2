# 🤖 Configuration Multi-IA

## Providers supportés

### 1. Ollama (Local)

**Avantages** : Gratuit, privé, offline
**Installation** :
```bash
curl https://ollama.ai/install.sh | sh
ollama pull llama2
```

**Configuration** :
- URL : `http://localhost:11434`
- Modèle : llama2, mistral, codellama...

### 2. Google Gemini

**Avantages** : Rapide, multimodal
**Clé API** : https://aistudio.google.com/app/apikey

**Modèles** :
- `gemini-pro` : Texte
- `gemini-pro-vision` : Vision + texte

### 3. Anthropic Claude

**Avantages** : Précis, éthique, long contexte
**Clé API** : https://console.anthropic.com/

**Modèles** :
- `claude-3-opus` : Plus performant
- `claude-3-sonnet` : Équilibré
- `claude-3-haiku` : Plus rapide

### 4. OpenAI ChatGPT

**Avantages** : Polyvalent, bien documenté
**Clé API** : https://platform.openai.com/api-keys

**Modèles** :
- `gpt-4-turbo` : Plus récent
- `gpt-4` : Standard
- `gpt-3.5-turbo` : Économique

## Test de connexion

L'interface permet de tester chaque provider avant de sauvegarder.

## Sécurité

- Les clés API ne sont **jamais** stockées en base
- Chiffrement en mémoire côté serveur
- Recommandé : variables d'environnement en production
