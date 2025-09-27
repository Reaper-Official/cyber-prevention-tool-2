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
