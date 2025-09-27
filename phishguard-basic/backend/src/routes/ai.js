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
