-- ============================================
-- Create AI Analysis Cache Table
-- ============================================
-- Cache expensive AI analysis results

CREATE TABLE IF NOT EXISTS ai_analysis_cache (
    cache_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users("userId") ON DELETE CASCADE,
    elder_user_id BIGINT REFERENCES users("userId") ON DELETE CASCADE,
    analysis_type VARCHAR(100) NOT NULL, -- 'medication_adherence', 'health_trends', etc.
    date_range_start DATE NOT NULL,
    date_range_end DATE NOT NULL,
    analysis_result JSONB NOT NULL,
    embedding vector(1536), -- For finding similar analyses
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Indexes
CREATE INDEX ai_analysis_cache_user_id_idx ON ai_analysis_cache(user_id);
CREATE INDEX ai_analysis_cache_elder_user_id_idx ON ai_analysis_cache(elder_user_id);
CREATE INDEX ai_analysis_cache_type_idx ON ai_analysis_cache(analysis_type);
CREATE INDEX ai_analysis_cache_expires_at_idx ON ai_analysis_cache(expires_at);

-- Verify table was created
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ai_analysis_cache'
ORDER BY ordinal_position;

