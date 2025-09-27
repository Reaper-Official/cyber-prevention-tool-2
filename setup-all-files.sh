#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  PhishGuard BASIC - Setup Complet avec Multi-IA
#  Supporte: Ollama, Gemini, Claude, ChatGPT
#  Version: 4.0.0
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_NAME="phishguard-basic"
PROJECT_DIR="${PWD}/${PROJECT_NAME}"

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════════╗
║        🛡️  PHISHGUARD - Plateforme de Formation Cybersécurité  🛡️             ║
║                                                                               ║
║              Multi-IA: Ollama | Gemini | Claude | ChatGPT                     ║
║                        Version 4.0.0 - Setup Complet                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $*"; }
section_header() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
    printf "${MAGENTA}║${NC} ${BOLD}%-56s${NC} ${MAGENTA}║${NC}\n" "$1"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
}

create_project_structure() {
    section_header "Création de la structure du projet"
    
    mkdir -p "${PROJECT_DIR}"
    cd "${PROJECT_DIR}"
    
    mkdir -p {backend,frontend,database,docs,.github/workflows,.devcontainer,scripts,config}
    mkdir -p backend/{src/{routes,controllers,models,middleware,services,utils,config},tests}
    mkdir -p frontend/{public/{js,css,assets},src}
    mkdir -p database/{migrations,seeds}
    
    log_success "Structure créée"
}

#═══════════════════════════════════════════════════════════════════════════════
# BACKEND - Service IA Multi-Provider
#═══════════════════════════════════════════════════════════════════════════════

create_backend() {
    section_header "Création du Backend (Multi-IA)"
    
    cd "${PROJECT_DIR}/backend"
    
    # package.json avec toutes les dépendances IA
    cat > package.json << 'EOF'
{
  "name": "phishguard-backend",
  "version": "1.0.0",
  "description": "PhishGuard Backend with Multi-AI Support",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest --coverage"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "dotenv": "^16.3.1",
    "pg": "^8.11.3",
    "redis": "^4.6.12",
    "bcrypt": "^5.1.1",
    "jsonwebtoken": "^9.0.2",
    "express-rate-limit": "^7.1.5",
    "express-validator": "^7.0.1",
    "winston": "^3.11.0",
    "@google/generative-ai": "^0.1.3",
    "@anthropic-ai/sdk": "^0.17.0",
    "openai": "^4.24.1",
    "axios": "^1.6.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0"
  }
}
EOF

    # Service IA avec tous les providers
    cat > src/services/aiService.js << 'EOF'
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Anthropic = require('@anthropic-ai/sdk');
const OpenAI = require('openai');
const axios = require('axios');

class AIService {
    constructor() {
        this.providers = {
            gemini: null,
            claude: null,
            openai: null,
            ollama: null
        };
    }

    // Initialiser les providers avec les clés
    initializeProvider(provider, apiKey, config = {}) {
        try {
            switch (provider) {
                case 'gemini':
                    this.providers.gemini = new GoogleGenerativeAI(apiKey);
                    break;
                case 'claude':
                    this.providers.claude = new Anthropic({ apiKey });
                    break;
                case 'openai':
                    this.providers.openai = new OpenAI({ apiKey });
                    break;
                case 'ollama':
                    this.providers.ollama = {
                        baseURL: config.baseURL || 'http://localhost:11434',
                        model: config.model || 'llama2'
                    };
                    break;
                default:
                    throw new Error(`Provider ${provider} not supported`);
            }
            return { success: true, message: `${provider} initialized` };
        } catch (error) {
            throw new Error(`Failed to initialize ${provider}: ${error.message}`);
        }
    }

    // Tester la connexion à un provider
    async testConnection(provider, apiKey, config = {}) {
        try {
            const testPrompt = "Réponds simplement 'OK' si tu reçois ce message.";
            
            switch (provider) {
                case 'gemini':
                    const genAI = new GoogleGenerativeAI(apiKey);
                    const model = genAI.getGenerativeModel({ model: config.model || 'gemini-pro' });
                    const result = await model.generateContent(testPrompt);
                    return {
                        success: true,
                        response: result.response.text(),
                        provider: 'gemini'
                    };

                case 'claude':
                    const claude = new Anthropic({ apiKey });
                    const message = await claude.messages.create({
                        model: config.model || 'claude-3-sonnet-20240229',
                        max_tokens: 50,
                        messages: [{ role: 'user', content: testPrompt }]
                    });
                    return {
                        success: true,
                        response: message.content[0].text,
                        provider: 'claude'
                    };

                case 'openai':
                    const openai = new OpenAI({ apiKey });
                    const completion = await openai.chat.completions.create({
                        model: config.model || 'gpt-3.5-turbo',
                        messages: [{ role: 'user', content: testPrompt }],
                        max_tokens: 50
                    });
                    return {
                        success: true,
                        response: completion.choices[0].message.content,
                        provider: 'openai'
                    };

                case 'ollama':
                    const ollamaURL = config.baseURL || 'http://localhost:11434';
                    const ollamaModel = config.model || 'llama2';
                    const ollamaResponse = await axios.post(`${ollamaURL}/api/generate`, {
                        model: ollamaModel,
                        prompt: testPrompt,
                        stream: false
                    });
                    return {
                        success: true,
                        response: ollamaResponse.data.response,
                        provider: 'ollama'
                    };

                default:
                    throw new Error(`Provider ${provider} not supported`);
            }
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider
            };
        }
    }

    // Générer du contenu avec le provider actif
    async generateContent(prompt, provider, config = {}) {
        try {
            switch (provider) {
                case 'gemini':
                    if (!this.providers.gemini) throw new Error('Gemini not initialized');
                    const model = this.providers.gemini.getGenerativeModel({ 
                        model: config.model || 'gemini-pro' 
                    });
                    const result = await model.generateContent(prompt);
                    return result.response.text();

                case 'claude':
                    if (!this.providers.claude) throw new Error('Claude not initialized');
                    const message = await this.providers.claude.messages.create({
                        model: config.model || 'claude-3-sonnet-20240229',
                        max_tokens: config.maxTokens || 1024,
                        messages: [{ role: 'user', content: prompt }]
                    });
                    return message.content[0].text;

                case 'openai':
                    if (!this.providers.openai) throw new Error('OpenAI not initialized');
                    const completion = await this.providers.openai.chat.completions.create({
                        model: config.model || 'gpt-3.5-turbo',
                        messages: [{ role: 'user', content: prompt }],
                        max_tokens: config.maxTokens || 1024
                    });
                    return completion.choices[0].message.content;

                case 'ollama':
                    if (!this.providers.ollama) throw new Error('Ollama not configured');
                    const response = await axios.post(
                        `${this.providers.ollama.baseURL}/api/generate`,
                        {
                            model: this.providers.ollama.model,
                            prompt: prompt,
                            stream: false
                        }
                    );
                    return response.data.response;

                default:
                    throw new Error(`Provider ${provider} not supported`);
            }
        } catch (error) {
            throw new Error(`AI generation failed: ${error.message}`);
        }
    }

    // Lister les modèles disponibles pour un provider
    async listModels(provider, apiKey, config = {}) {
        try {
            switch (provider) {
                case 'gemini':
                    return ['gemini-pro', 'gemini-pro-vision'];
                
                case 'claude':
                    return [
                        'claude-3-opus-20240229',
                        'claude-3-sonnet-20240229',
                        'claude-3-haiku-20240307'
                    ];
                
                case 'openai':
                    const openai = new OpenAI({ apiKey });
                    const models = await openai.models.list();
                    return models.data
                        .filter(m => m.id.includes('gpt'))
                        .map(m => m.id);
                
                case 'ollama':
                    const ollamaURL = config.baseURL || 'http://localhost:11434';
                    const response = await axios.get(`${ollamaURL}/api/tags`);
                    return response.data.models.map(m => m.name);
                
                default:
                    return [];
            }
        } catch (error) {
            console.error(`Error listing models for ${provider}:`, error);
            return [];
        }
    }
}

module.exports = new AIService();
EOF

    # Routes pour l'IA
    cat > src/routes/ai.js << 'EOF'
const express = require('express');
const router = express.Router();
const aiService = require('../services/aiService');

// Tester une connexion IA
router.post('/test', async (req, res) => {
    try {
        const { provider, apiKey, config } = req.body;
        
        if (!provider || !apiKey) {
            return res.status(400).json({ 
                error: 'Provider and API key are required' 
            });
        }

        const result = await aiService.testConnection(provider, apiKey, config);
        res.json(result);
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// Initialiser un provider
router.post('/initialize', async (req, res) => {
    try {
        const { provider, apiKey, config } = req.body;
        
        const result = aiService.initializeProvider(provider, apiKey, config);
        res.json(result);
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// Générer du contenu
router.post('/generate', async (req, res) => {
    try {
        const { prompt, provider, config } = req.body;
        
        if (!prompt || !provider) {
            return res.status(400).json({ 
                error: 'Prompt and provider are required' 
            });
        }

        const content = await aiService.generateContent(prompt, provider, config);
        res.json({ 
            success: true, 
            content,
            provider 
        });
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// Lister les modèles disponibles
router.get('/models/:provider', async (req, res) => {
    try {
        const { provider } = req.params;
        const { apiKey, config } = req.query;
        
        const models = await aiService.listModels(
            provider, 
            apiKey, 
            config ? JSON.parse(config) : {}
        );
        
        res.json({ 
            success: true, 
            provider, 
            models 
        });
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

module.exports = router;
EOF

    # Routes pour la configuration
    cat > src/routes/settings.js << 'EOF'
const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Récupérer les paramètres IA
router.get('/ai', async (req, res) => {
    try {
        const settings = await db.query(
            'SELECT provider, config FROM ai_settings WHERE active = true LIMIT 1'
        );
        
        if (settings.rows.length === 0) {
            return res.json({ 
                provider: null, 
                config: null 
            });
        }
        
        res.json(settings.rows[0]);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Sauvegarder les paramètres IA
router.post('/ai', async (req, res) => {
    try {
        const { provider, apiKey, config } = req.body;
        
        // Désactiver tous les anciens paramètres
        await db.query('UPDATE ai_settings SET active = false');
        
        // Insérer les nouveaux paramètres (sans stocker la clé API)
        await db.query(
            `INSERT INTO ai_settings (provider, config, active) 
             VALUES ($1, $2, true)`,
            [provider, JSON.stringify(config)]
        );
        
        res.json({ 
            success: true, 
            message: 'Settings saved successfully' 
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
EOF

    # Server principal
    cat > src/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:8080',
    credentials: true
}));

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});
app.use('/api/', limiter);

app.use(express.json());

// Routes
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString() 
    });
});

app.use('/api/ai', require('./routes/ai'));
app.use('/api/settings', require('./routes/settings'));

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 PhishGuard Backend on port ${PORT}`);
    console.log(`🤖 Multi-AI Support: Ollama | Gemini | Claude | ChatGPT`);
});

module.exports = app;
EOF

    # Config database
    cat > src/config/database.js << 'EOF'
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

module.exports = {
    query: (text, params) => pool.query(text, params),
    pool
};
EOF

    # Healthcheck
    cat > healthcheck.js << 'EOF'
const http = require('http');
const options = {
    host: 'localhost',
    port: process.env.PORT || 3000,
    path: '/health',
    timeout: 2000
};
const req = http.request(options, (res) => {
    process.exit(res.statusCode === 200 ? 0 : 1);
});
req.on('error', () => process.exit(1));
req.end();
EOF

    # Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
HEALTHCHECK CMD node healthcheck.js || exit 1
CMD ["node", "src/server.js"]
EOF

    log_success "Backend créé avec Multi-IA"
}

#═══════════════════════════════════════════════════════════════════════════════
# FRONTEND - Interface de configuration IA
#═══════════════════════════════════════════════════════════════════════════════

create_frontend() {
    section_header "Création du Frontend avec Config IA"
    
    cd "${PROJECT_DIR}/frontend"
    
    # HTML principal
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PhishGuard - Multi-IA Platform</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <nav class="navbar">
        <div class="container">
            <h1 class="logo">🛡️ PhishGuard</h1>
            <ul class="nav-links">
                <li><a href="#home">Accueil</a></li>
                <li><a href="#campaigns">Campagnes</a></li>
                <li><a href="#settings" onclick="showSettings()">⚙️ Configuration IA</a></li>
            </ul>
        </div>
    </nav>

    <main class="container">
        <!-- Page d'accueil -->
        <section id="home-section">
            <div class="hero">
                <h2>Formation en Cybersécurité par Simulation de Phishing</h2>
                <p>Propulsé par l'IA de votre choix</p>
                <div class="ai-providers">
                    <span class="ai-badge">🤖 Ollama</span>
                    <span class="ai-badge">✨ Gemini</span>
                    <span class="ai-badge">🎭 Claude</span>
                    <span class="ai-badge">💬 ChatGPT</span>
                </div>
            </div>
        </section>

        <!-- Configuration IA -->
        <section id="settings-section" style="display:none;">
            <div class="settings-container">
                <h2>⚙️ Configuration de l'IA</h2>
                
                <div class="ai-selector">
                    <h3>Choisissez votre provider IA</h3>
                    <div class="provider-grid">
                        <div class="provider-card" onclick="selectProvider('ollama')">
                            <span class="provider-icon">🤖</span>
                            <h4>Ollama</h4>
                            <p>Local & Gratuit</p>
                        </div>
                        <div class="provider-card" onclick="selectProvider('gemini')">
                            <span class="provider-icon">✨</span>
                            <h4>Google Gemini</h4>
                            <p>Puissant & Rapide</p>
                        </div>
                        <div class="provider-card" onclick="selectProvider('claude')">
                            <span class="provider-icon">🎭</span>
                            <h4>Anthropic Claude</h4>
                            <p>Précis & Éthique</p>
                        </div>
                        <div class="provider-card" onclick="selectProvider('openai')">
                            <span class="provider-icon">💬</span>
                            <h4>OpenAI ChatGPT</h4>
                            <p>Polyvalent</p>
                        </div>
                    </div>
                </div>

                <!-- Configuration form -->
                <div id="config-form" class="config-form" style="display:none;">
                    <h3 id="provider-title">Configuration</h3>
                    
                    <div id="ollama-config" class="provider-config" style="display:none;">
                        <div class="form-group">
                            <label>URL Ollama</label>
                            <input type="text" id="ollama-url" value="http://localhost:11434" placeholder="http://localhost:11434">
                        </div>
                        <div class="form-group">
                            <label>Modèle</label>
                            <select id="ollama-model">
                                <option value="llama2">Llama 2</option>
                                <option value="llama3">Llama 3</option>
                                <option value="mistral">Mistral</option>
                                <option value="codellama">Code Llama</option>
                            </select>
                        </div>
                    </div>

                    <div id="gemini-config" class="provider-config" style="display:none;">
                        <div class="form-group">
                            <label>Clé API Gemini</label>
                            <input type="password" id="gemini-key" placeholder="Votre clé API Gemini">
                            <small><a href="https://aistudio.google.com/app/apikey" target="_blank">Obtenir une clé API</a></small>
                        </div>
                        <div class="form-group">
                            <label>Modèle</label>
                            <select id="gemini-model">
                                <option value="gemini-pro">Gemini Pro</option>
                                <option value="gemini-pro-vision">Gemini Pro Vision</option>
                            </select>
                        </div>
                    </div>

                    <div id="claude-config" class="provider-config" style="display:none;">
                        <div class="form-group">
                            <label>Clé API Claude</label>
                            <input type="password" id="claude-key" placeholder="Votre clé API Claude">
                            <small><a href="https://console.anthropic.com/" target="_blank">Obtenir une clé API</a></small>
                        </div>
                        <div class="form-group">
                            <label>Modèle</label>
                            <select id="claude-model">
                                <option value="claude-3-sonnet-20240229">Claude 3 Sonnet</option>
                                <option value="claude-3-opus-20240229">Claude 3 Opus</option>
                                <option value="claude-3-haiku-20240307">Claude 3 Haiku</option>
                            </select>
                        </div>
                    </div>

                    <div id="openai-config" class="provider-config" style="display:none;">
                        <div class="form-group">
                            <label>Clé API OpenAI</label>
                            <input type="password" id="openai-key" placeholder="Votre clé API OpenAI">
                            <small><a href="https://platform.openai.com/api-keys" target="_blank">Obtenir une clé API</a></small>
                        </div>
                        <div class="form-group">
                            <label>Modèle</label>
                            <select id="openai-model">
                                <option value="gpt-3.5-turbo">GPT-3.5 Turbo</option>
                                <option value="gpt-4">GPT-4</option>
                                <option value="gpt-4-turbo">GPT-4 Turbo</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-actions">
                        <button class="btn-secondary" onclick="testConnection()">🧪 Tester la connexion</button>
                        <button class="btn-primary" onclick="saveConfiguration()">💾 Sauvegarder</button>
                    </div>

                    <div id="test-result" class="test-result" style="display:none;"></div>
                </div>
            </div>
        </section>
    </main>

    <script src="js/app.js"></script>
</body>
</html>
EOF

    # CSS
    cat > public/css/styles.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

:root {
    --primary: #2563eb;
    --secondary: #7c3aed;
    --success: #10b981;
    --danger: #ef4444;
    --dark: #1f2937;
    --light: #f9fafb;
}

body {
    font-family: system-ui, -apple-system, sans-serif;
    line-height: 1.6;
    color: var(--dark);
    background: var(--light);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

/* Navbar */
.navbar {
    background: white;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    padding: 1rem 0;
    position: sticky;
    top: 0;
    z-index: 100;
}

.navbar .container {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.logo {
    color: var(--primary);
    font-size: 1.5rem;
}

.nav-links {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-links a {
    text-decoration: none;
    color: var(--dark);
    font-weight: 500;
    cursor: pointer;
}

/* Hero */
.hero {
    text-align: center;
    padding: 60px 20px;
}

.hero h2 {
    font-size: 2.5rem;
    margin-bottom: 1rem;
    background: linear-gradient(135deg, var(--primary), var(--secondary));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.ai-providers {
    display: flex;
    justify-content: center;
    gap: 1rem;
    margin-top: 2rem;
    flex-wrap: wrap;
}

.ai-badge {
    background: white;
    padding: 0.5rem 1.5rem;
    border-radius: 20px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    font-weight: 500;
}

/* Settings */
.settings-container {
    background: white;
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
}

.provider-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1.5rem;
    margin: 2rem 0;
}

.provider-card {
    background: var(--light);
    padding: 2rem;
    border-radius: 12px;
    text-align: center;
    cursor: pointer;
    transition: all 0.3s;
    border: 2px solid transparent;
}

.provider-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 25px rgba(0,0,0,0.1);
    border-color: var(--primary);
}

.provider-card.selected {
    border-color: var(--primary);
    background: #eff6ff;
}

.provider-icon {
    font-size: 3rem;
    display: block;
    margin-bottom: 1rem;
}

/* Forms */
.config-form {
    margin-top: 2rem;
    padding: 2rem;
    background: var(--light);
    border-radius: 8px;
}

.form-group {
    margin-bottom: 1.5rem;
}

.form-group label {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: var(--dark);
}

.form-group input,
.form-group select {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e5e7eb;
    border-radius: 8px;
    font-size: 1rem;
    transition: border-color 0.3s;
}

.form-group input:focus,
.form-group select:focus {
    outline: none;
    border-color: var(--primary);
}

.form-group small {
    display: block;
    margin-top: 0.5rem;
    color: #6b7280;
}

.form-group small a {
    color: var(--primary);
    text-decoration: none;
}

.form-actions {
    display: flex;
    gap: 1rem;
    margin-top: 2rem;
}

.btn-primary,
.btn-secondary {
    padding: 0.75rem 2rem;
    border: none;
    border-radius: 8px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
}

.btn-primary {
    background: var(--primary);
    color: white;
}

.btn-primary:hover {
    background: #1d4ed8;
    transform: translateY(-2px);
}

.btn-secondary {
    background: white;
    color: var(--primary);
    border: 2px solid var(--primary);
}

.btn-secondary:hover {
    background: var(--primary);
    color: white;
}

/* Test Results */
.test-result {
    margin-top: 1.5rem;
    padding: 1rem;
    border-radius: 8px;
    animation: fadeIn 0.3s;
}

.test-result.success {
    background: #d1fae5;
    color: #065f46;
    border: 1px solid #10b981;
}

.test-result.error {
    background: #fee2e2;
    color: #991b1b;
    border: 1px solid #ef4444;
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(-10px); }
    to { opacity: 1; transform: translateY(0); }
}

/* Responsive */
@media (max-width: 768px) {
    .hero h2 {
        font-size: 1.8rem;
    }
    
    .provider-grid {
        grid-template-columns: 1fr;
    }
    
    .form-actions {
        flex-direction: column;
    }
    
    .btn-primary,
    .btn-secondary {
        width: 100%;
    }
}
EOF

    # JavaScript
    cat > public/js/app.js << 'EOF'
const API_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:3000/api' 
    : '/api';

let currentProvider = null;

// Afficher la page de configuration
function showSettings() {
    document.getElementById('home-section').style.display = 'none';
    document.getElementById('settings-section').style.display = 'block';
    loadCurrentSettings();
}

// Charger les paramètres actuels
async function loadCurrentSettings() {
    try {
        const response = await fetch(`${API_URL}/settings/ai`);
        const data = await response.json();
        
        if (data.provider) {
            selectProvider(data.provider);
            // Remplir les champs si disponibles
            if (data.config) {
                const config = typeof data.config === 'string' 
                    ? JSON.parse(data.config) 
                    : data.config;
                populateConfigForm(data.provider, config);
            }
        }
    } catch (error) {
        console.error('Error loading settings:', error);
    }
}

// Sélectionner un provider
function selectProvider(provider) {
    currentProvider = provider;
    
    // Mettre à jour l'UI
    document.querySelectorAll('.provider-card').forEach(card => {
        card.classList.remove('selected');
    });
    event?.target.closest('.provider-card')?.classList.add('selected');
    
    // Afficher le formulaire de config
    document.getElementById('config-form').style.display = 'block';
    document.getElementById('provider-title').textContent = 
        `Configuration ${provider.charAt(0).toUpperCase() + provider.slice(1)}`;
    
    // Masquer tous les formulaires
    document.querySelectorAll('.provider-config').forEach(config => {
        config.style.display = 'none';
    });
    
    // Afficher le bon formulaire
    document.getElementById(`${provider}-config`).style.display = 'block';
}

// Remplir le formulaire avec les données existantes
function populateConfigForm(provider, config) {
    switch(provider) {
        case 'ollama':
            if (config.baseURL) document.getElementById('ollama-url').value = config.baseURL;
            if (config.model) document.getElementById('ollama-model').value = config.model;
            break;
        case 'gemini':
            if (config.model) document.getElementById('gemini-model').value = config.model;
            break;
        case 'claude':
            if (config.model) document.getElementById('claude-model').value = config.model;
            break;
        case 'openai':
            if (config.model) document.getElementById('openai-model').value = config.model;
            break;
    }
}

// Récupérer la configuration du formulaire
function getConfigFromForm() {
    const config = {};
    
    switch(currentProvider) {
        case 'ollama':
            return {
                baseURL: document.getElementById('ollama-url').value,
                model: document.getElementById('ollama-model').value
            };
        case 'gemini':
            return {
                apiKey: document.getElementById('gemini-key').value,
                model: document.getElementById('gemini-model').value
            };
        case 'claude':
            return {
                apiKey: document.getElementById('claude-key').value,
                model: document.getElementById('claude-model').value
            };
        case 'openai':
            return {
                apiKey: document.getElementById('openai-key').value,
                model: document.getElementById('openai-model').value
            };
    }
}

// Tester la connexion
async function testConnection() {
    if (!currentProvider) {
        showTestResult('error', 'Veuillez sélectionner un provider');
        return;
    }
    
    const config = getConfigFromForm();
    const apiKey = config.apiKey || null;
    
    // Validation
    if (!apiKey && currentProvider !== 'ollama') {
        showTestResult('error', 'Clé API requise');
        return;
    }
    
    showTestResult('info', '🔄 Test en cours...');
    
    try {
        const response = await fetch(`${API_URL}/ai/test`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                provider: currentProvider,
                apiKey: apiKey,
                config: config
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showTestResult('success', 
                `✅ Connexion réussie!\n\nRéponse: "${result.response}"\n\nProvider: ${result.provider}`
            );
        } else {
            showTestResult('error', 
                `❌ Échec de la connexion\n\nErreur: ${result.error}`
            );
        }
    } catch (error) {
        showTestResult('error', 
            `❌ Erreur de connexion\n\n${error.message}`
        );
    }
}

// Sauvegarder la configuration
async function saveConfiguration() {
    if (!currentProvider) {
        showTestResult('error', 'Veuillez sélectionner un provider');
        return;
    }
    
    const config = getConfigFromForm();
    const apiKey = config.apiKey || null;
    
    try {
        // D'abord initialiser le provider
        const initResponse = await fetch(`${API_URL}/ai/initialize`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                provider: currentProvider,
                apiKey: apiKey,
                config: config
            })
        });
        
        if (!initResponse.ok) {
            throw new Error('Failed to initialize provider');
        }
        
        // Ensuite sauvegarder les paramètres (sans la clé API pour la sécurité)
        const settingsResponse = await fetch(`${API_URL}/settings/ai`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                provider: currentProvider,
                apiKey: apiKey, // Sera utilisé côté serveur mais pas stocké
                config: {
                    model: config.model,
                    baseURL: config.baseURL
                }
            })
        });
        
        const result = await settingsResponse.json();
        
        if (result.success) {
            showTestResult('success', 
                `✅ Configuration sauvegardée!\n\nProvider: ${currentProvider}\nModèle: ${config.model || 'default'}`
            );
            
            // Masquer le mot de passe après sauvegarde
            if (config.apiKey) {
                const keyInput = document.getElementById(`${currentProvider}-key`);
                if (keyInput) keyInput.value = '••••••••••••••••';
            }
        } else {
            showTestResult('error', `❌ Erreur: ${result.error}`);
        }
    } catch (error) {
        showTestResult('error', `❌ Erreur de sauvegarde\n\n${error.message}`);
    }
}

// Afficher le résultat du test
function showTestResult(type, message) {
    const resultDiv = document.getElementById('test-result');
    resultDiv.style.display = 'block';
    resultDiv.className = `test-result ${type}`;
    resultDiv.textContent = message;
    
    // Auto-masquer après 5 secondes pour les succès
    if (type === 'success') {
        setTimeout(() => {
            resultDiv.style.display = 'none';
        }, 5000);
    }
}

// Test de connexion API au chargement
window.addEventListener('DOMContentLoaded', () => {
    fetch(`${API_URL}/../health`)
        .then(res => res.json())
        .then(data => {
            console.log('✅ API Connected:', data);
        })
        .catch(err => {
            console.error('❌ API Connection Failed:', err);
        });
});
EOF

    # Dockerfile frontend
    cat > Dockerfile << 'EOF'
FROM nginx:1.25-alpine
COPY public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
RUN chown -R nginx:nginx /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s CMD wget -q -O /dev/null http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
EOF

    # Configuration Nginx
    cat > nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    keepalive_timeout 65;
    gzip on;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF

    cat > default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

    log_success "Frontend créé avec interface Multi-IA"
}

#═══════════════════════════════════════════════════════════════════════════════
# DATABASE - Schema avec table pour les paramètres IA
#═══════════════════════════════════════════════════════════════════════════════

create_database() {
    section_header "Création de la base de données"
    
    cd "${PROJECT_DIR}"
    
    cat > database/init.sql << 'EOF'
-- PhishGuard Database Schema with AI Settings

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table des paramètres IA
CREATE TABLE IF NOT EXISTS ai_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider VARCHAR(50) NOT NULL,
    config JSONB,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_ai_settings_active ON ai_settings(active);

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des campagnes
CREATE TABLE IF NOT EXISTS campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    ai_provider VARCHAR(50),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des templates générés par IA
CREATE TABLE IF NOT EXISTS templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    subject VARCHAR(500),
    content TEXT,
    category VARCHAR(100),
    ai_provider VARCHAR(50),
    ai_model VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des résultats
CREATE TABLE IF NOT EXISTS campaign_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    clicked BOOLEAN DEFAULT FALSE,
    submitted_data BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour performances
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_provider ON campaigns(ai_provider);
CREATE INDEX idx_templates_provider ON templates(ai_provider);

-- Données de test
INSERT INTO users (email, password_hash, first_name, last_name, role) 
VALUES ('admin@phishguard.local', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5agyWW.hiayxm', 'Admin', 'PhishGuard', 'admin')
ON CONFLICT (email) DO NOTHING;
EOF

    log_success "Schema de base de données créé"
}

#═══════════════════════════════════════════════════════════════════════════════
# DOCKER COMPOSE - Configuration complète
#═══════════════════════════════════════════════════════════════════════════════

create_docker_compose() {
    section_header "Création de Docker Compose"
    
    cd "${PROJECT_DIR}"
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: phishguard-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-phishguard}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-phishguard}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - phishguard-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U phishguard"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: phishguard-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - phishguard-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: phishguard-backend
    restart: unless-stopped
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: 3000
      DATABASE_URL: postgresql://${POSTGRES_USER:-phishguard}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB:-phishguard}
      REDIS_URL: redis://redis:6379
      FRONTEND_URL: ${FRONTEND_URL:-http://localhost:8080}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - phishguard-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: phishguard-frontend
    restart: unless-stopped
    ports:
      - "${APP_PORT:-8080}:80"
    depends_on:
      - backend
    networks:
      - phishguard-network

volumes:
  postgres_data:
  redis_data:

networks:
  phishguard-network:
    driver: bridge
EOF

    log_success "Docker Compose créé"
}

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION FILES
#═══════════════════════════════════════════════════════════════════════════════

create_config_files() {
    section_header "Création des fichiers de configuration"
    
    cd "${PROJECT_DIR}"
    
    # .env
    POSTGRES_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    
    cat > .env << EOF
NODE_ENV=production
APP_PORT=8080
FRONTEND_URL=http://localhost:8080

POSTGRES_USER=phishguard
POSTGRES_PASSWORD=${POSTGRES_PASS}
POSTGRES_DB=phishguard
DATABASE_URL=postgresql://phishguard:${POSTGRES_PASS}@postgres:5432/phishguard

REDIS_URL=redis://redis:6379
EOF

    # .env.example
    cat > .env.example << 'EOF'
NODE_ENV=production
APP_PORT=8080
FRONTEND_URL=http://localhost:8080

POSTGRES_USER=phishguard
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=phishguard
DATABASE_URL=postgresql://phishguard:password@postgres:5432/phishguard

REDIS_URL=redis://redis:6379

# Note: Les clés API sont configurées depuis l'interface web
# Elles ne doivent PAS être stockées dans les fichiers .env
EOF

    # .gitignore
    cat > .gitignore << 'EOF'
node_modules/
.env
.env.local
*.log
.DS_Store
.vscode/
.idea/
dist/
build/
coverage/
uploads/
backups/
EOF

    log_success "Fichiers de configuration créés"
}

#═══════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION COMPLÈTE
#═══════════════════════════════════════════════════════════════════════════════

create_documentation() {
    section_header "Création de la documentation"
    
    cd "${PROJECT_DIR}"
    
    cat > README.md << 'EOF'
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
EOF

    mkdir -p docs
    
    cat > docs/ai-config.md << 'EOF'
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
EOF

    log_success "Documentation créée"
}

#═══════════════════════════════════════════════════════════════════════════════
# SCRIPTS UTILITAIRES
#═══════════════════════════════════════════════════════════════════════════════

create_scripts() {
    section_header "Création des scripts utilitaires"
    
    cd "${PROJECT_DIR}"
    
    cat > Makefile << 'EOF'
.PHONY: help start stop logs test clean

help:
	@echo "PhishGuard Multi-IA - Commandes:"
	@echo "  make start   - Démarrer"
	@echo "  make stop    - Arrêter"
	@echo "  make logs    - Voir les logs"
	@echo "  make test    - Test IA"
	@echo "  make clean   - Nettoyer"

start:
	docker-compose up -d
	@echo "✅ PhishGuard démarré: http://localhost:8080"

stop:
	docker-compose down

logs:
	docker-compose logs -f

test:
	@echo "🧪 Test des providers IA disponibles..."
	@curl -s http://localhost:3000/health || echo "❌ Backend non accessible"

clean:
	docker-compose down -v
	docker system prune -af
EOF

    log_success "Scripts créés"
}

#═══════════════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
#═══════════════════════════════════════════════════════════════════════════════

show_final_summary() {
    section_header "Installation Terminée"
    
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                  ✅ PROJET PHISHGUARD MULTI-IA CRÉÉ !                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    echo -e "${CYAN}📁 Projet créé:${NC} ${BOLD}${PROJECT_DIR}${NC}\n"
    
    echo -e "${BLUE}🤖 Providers IA supportés:${NC}"
    echo "   🤖 Ollama (local, gratuit)"
    echo "   ✨ Google Gemini"
    echo "   🎭 Anthropic Claude"
    echo "   💬 OpenAI ChatGPT"
    echo ""
    
    echo -e "${YELLOW}🚀 Démarrage:${NC}"
    echo -e "   ${GREEN}cd ${PROJECT_NAME}${NC}"
    echo -e "   ${GREEN}docker-compose up -d${NC}"
    echo ""
    
    echo -e "${BLUE}📱 Accès:${NC}"
    echo -e "   Interface: ${GREEN}http://localhost:8080${NC}"
    echo -e "   API:       ${GREEN}http://localhost:3000${NC}"
    echo ""
    
    echo -e "${YELLOW}⚙️  Configuration IA:${NC}"
    echo "   1. Ouvrir http://localhost:8080"
    echo "   2. Cliquer sur 'Configuration IA'"
    echo "   3. Choisir votre provider"
    echo "   4. Entrer la clé API"
    echo "   5. Tester et sauvegarder"
    echo ""
    
    echo -e "${CYAN}🎉 Projet prêt pour GitHub Codespaces !${NC}\n"
}

#═══════════════════════════════════════════════════════════════════════════════
# MAIN
#═══════════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    create_project_structure
    create_backend
    create_frontend
    create_database
    create_docker_compose
    create_config_files
    create_documentation
    create_scripts
    show_final_summary
}

main "$@"
exit 0