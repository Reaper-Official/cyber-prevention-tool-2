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
