-- ============================================
-- Complete Vector Database Setup Script
-- ============================================
-- This script combines all setup steps in the correct order
-- Run this in pgAdmin to set up the entire vector database infrastructure

-- Step 1: Verify pgvector extension is installed
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Step 2: Create vector indexes (run 01-create-vector-indexes.sql content here)
\i 01-create-vector-indexes.sql

-- Step 3: Create AI Insights table
\i 02-create-ai-insights-table.sql

-- Step 4: Create Document Chunks table
\i 03-create-document-chunks-table.sql

-- Step 5: Create AI Conversations tables
\i 04-create-ai-conversations-tables.sql

-- Step 6: Create AI Analysis Cache table
\i 05-create-ai-analysis-cache-table.sql

-- Step 7: Add AI configuration keys
\i 06-add-ai-config-keys.sql

-- Final verification: List all new tables
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name IN (
        'ai_insights',
        'document_chunks',
        'ai_conversations',
        'ai_conversation_messages',
        'ai_analysis_cache'
    )
ORDER BY table_name;

-- List all vector indexes
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE indexname LIKE '%embedding_idx%'
ORDER BY tablename, indexname;

