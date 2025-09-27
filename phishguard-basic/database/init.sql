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
