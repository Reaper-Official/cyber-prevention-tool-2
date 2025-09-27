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
