-- ============================================
-- Add AI-Related Configuration Keys
-- ============================================
-- Add AI-related configuration keys to app_config table

INSERT INTO app_config (config_key, config_value, description, is_active)
VALUES 
    ('ai_embedding_model', 'text-embedding-3-small', 'OpenAI embedding model to use', true),
    ('ai_embedding_dimensions', '1536', 'Dimensions for embeddings', true),
    ('ai_max_context_tokens', '8000', 'Maximum tokens for AI context', true),
    ('ai_insight_generation_enabled', 'true', 'Enable automated insight generation', true),
    ('ai_insight_generation_interval_hours', '24', 'Hours between insight generation', true),
    ('ai_semantic_search_threshold', '0.7', 'Minimum similarity threshold for semantic search', true)
ON CONFLICT (config_key) DO UPDATE 
SET config_value = EXCLUDED.config_value, 
    updated_at = NOW();

-- Verify config keys were added
SELECT 
    config_key,
    config_value,
    description,
    is_active
FROM app_config
WHERE config_key LIKE 'ai_%'
ORDER BY config_key;

