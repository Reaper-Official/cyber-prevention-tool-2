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
