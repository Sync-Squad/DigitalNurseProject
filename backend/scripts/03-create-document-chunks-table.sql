-- ============================================
-- Create Document Chunks Table
-- ============================================
-- For storing chunked document content with embeddings (for document Q&A)

CREATE TABLE IF NOT EXISTS document_chunks (
    chunk_id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES user_documents("documentId") ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users("userId") ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL, -- Order of chunk in document
    chunk_text TEXT NOT NULL,
    chunk_embedding vector(1536),
    token_count INTEGER, -- For managing context windows
    metadata JSONB, -- Page number, section, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for document_chunks
CREATE INDEX document_chunks_document_id_idx ON document_chunks(document_id);
CREATE INDEX document_chunks_user_id_idx ON document_chunks(user_id);
CREATE INDEX document_chunks_chunk_embedding_idx ON document_chunks 
USING hnsw (chunk_embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);

-- Verify table was created
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'document_chunks'
ORDER BY ordinal_position;

