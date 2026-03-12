-- ============================================
-- Create AI Insights Table
-- ============================================
-- Stores AI-generated health insights, recommendations, and analysis

CREATE TABLE IF NOT EXISTS ai_insights (
    insight_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users("userId") ON DELETE CASCADE,
    elder_user_id BIGINT REFERENCES users("userId") ON DELETE CASCADE,
    insight_type VARCHAR(100) NOT NULL, -- 'medication_adherence', 'health_trend', 'recommendation', 'alert', 'pattern_detection'
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    confidence DECIMAL(5,2) CHECK (confidence >= 0 AND confidence <= 100),
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    category VARCHAR(100), -- 'medication', 'vitals', 'lifestyle', 'general'
    metadata JSONB, -- Additional structured data
    recommendations JSONB, -- Array of recommendation objects
    embedding vector(1536), -- For semantic search of insights
    is_read BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- For time-sensitive insights
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for ai_insights
CREATE INDEX ai_insights_user_id_idx ON ai_insights(user_id);
CREATE INDEX ai_insights_elder_user_id_idx ON ai_insights(elder_user_id);
CREATE INDEX ai_insights_type_idx ON ai_insights(insight_type);
CREATE INDEX ai_insights_category_idx ON ai_insights(category);
CREATE INDEX ai_insights_priority_idx ON ai_insights(priority);
CREATE INDEX ai_insights_generated_at_idx ON ai_insights(generated_at);
CREATE INDEX ai_insights_is_read_idx ON ai_insights(is_read);
CREATE INDEX ai_insights_embedding_idx ON ai_insights 
USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);

-- Verify table was created
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ai_insights'
ORDER BY ordinal_position;

