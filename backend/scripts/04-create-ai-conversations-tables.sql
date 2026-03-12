-- ============================================
-- Create AI Conversations Tables
-- ============================================
-- Store chat history with AI assistant

CREATE TABLE IF NOT EXISTS ai_conversations (
    conversation_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users("userId") ON DELETE CASCADE,
    elder_user_id BIGINT REFERENCES users("userId") ON DELETE CASCADE,
    title VARCHAR(255), -- Auto-generated from first message
    context_summary TEXT, -- Summary of conversation context
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_conversation_messages (
    message_id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES ai_conversations(conversation_id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- 'user' or 'assistant'
    content TEXT NOT NULL,
    metadata JSONB, -- Sources used, confidence, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX ai_conversations_user_id_idx ON ai_conversations(user_id);
CREATE INDEX ai_conversations_elder_user_id_idx ON ai_conversations(elder_user_id);
CREATE INDEX ai_conversation_messages_conversation_id_idx ON ai_conversation_messages(conversation_id);
CREATE INDEX ai_conversation_messages_created_at_idx ON ai_conversation_messages(created_at);

-- Verify tables were created
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name IN ('ai_conversations', 'ai_conversation_messages')
ORDER BY table_name, ordinal_position;

