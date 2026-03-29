-- ============================================
-- AI Dynamic Configuration Setup
-- ============================================
-- This script ensures all AI dynamic configuration keys exist in the app_config table.
-- Existing keys will NOT be overwritten if they already have values, unless specified.

-- 1. Insert core AI keys with defaults from .env
INSERT INTO app_config (config_key, config_value, description, is_active)
VALUES 
    ('ai_api_key', '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', 'OpenRouter/OpenAI API key (priority over .env)', true),
    ('ai_chat_model', 'openai/gpt-oss-20b:free', 'Primary AI model for chat and assistant', true),
    ('ai_embedding_model', 'text-embedding-3-small', 'Model used for vector embeddings', true),
    ('ai_embedding_dimensions', '1536', 'Dimensions for the embedding model', true)
ON CONFLICT (config_key) DO NOTHING;

-- 2. Link Gemini key for mobile backward compatibility (optional)
-- This ensures the mobile app can still find its key while we transition
INSERT INTO app_config (config_key, config_value, description, is_active)
SELECT 'gemini_api_key', config_value, 'Alias for mobile app compatibility', true
FROM app_config WHERE config_key = 'ai_api_key'
ON CONFLICT (config_key) DO NOTHING;

-- Verify results
SELECT config_key, config_value, description FROM app_config WHERE config_key LIKE 'ai_%' OR config_key = 'gemini_api_key';
