-- ============================================
-- Create Vector Indexes for Fast Similarity Search
-- ============================================
-- Run this script in pgAdmin to create HNSW indexes for vector columns
-- These indexes enable fast semantic similarity search using cosine distance

-- Caregiver notes index
CREATE INDEX IF NOT EXISTS caregiver_notes_embedding_idx 
ON caregiver_notes 
USING hnsw (embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- Medications index
CREATE INDEX IF NOT EXISTS medications_notes_embedding_idx 
ON medications 
USING hnsw (notes_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- Vital measurements index
CREATE INDEX IF NOT EXISTS vital_measurements_notes_embedding_idx 
ON vital_measurements 
USING hnsw (notes_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- Diet logs indexes
CREATE INDEX IF NOT EXISTS diet_logs_food_items_embedding_idx 
ON diet_logs 
USING hnsw (food_items_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS diet_logs_notes_embedding_idx 
ON diet_logs 
USING hnsw (notes_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- Exercise logs indexes
CREATE INDEX IF NOT EXISTS exercise_logs_description_embedding_idx 
ON exercise_logs 
USING hnsw (description_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS exercise_logs_notes_embedding_idx 
ON exercise_logs 
USING hnsw (notes_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- Med intakes index
CREATE INDEX IF NOT EXISTS med_intakes_notes_embedding_idx 
ON med_intakes 
USING hnsw (notes_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- User documents index
CREATE INDEX IF NOT EXISTS user_documents_metadata_embedding_idx 
ON user_documents 
USING hnsw (metadata_embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- Verify indexes were created
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE indexname LIKE '%embedding_idx%'
ORDER BY tablename, indexname;

