# Vector Database Setup Scripts

These SQL scripts set up the vector database infrastructure for AI features in Digital Nurse.

## Script Execution Order

Run these scripts in pgAdmin in the following order:

1. **01-create-vector-indexes.sql** - Creates HNSW indexes for fast vector similarity search
2. **02-create-ai-insights-table.sql** - Creates table for AI-generated health insights
3. **03-create-document-chunks-table.sql** - Creates table for document chunks with embeddings
4. **04-create-ai-conversations-tables.sql** - Creates tables for AI chat conversations
5. **05-create-ai-analysis-cache-table.sql** - Creates table for caching AI analysis results
6. **06-add-ai-config-keys.sql** - Adds AI configuration keys to app_config table

## How to Run in pgAdmin

1. Open pgAdmin and connect to your Digital Nurse database
2. Right-click on your database → **Query Tool**
3. Open each SQL file in order (01 through 06)
4. Execute each script (F5 or click Execute)
5. Verify success by checking the output messages

## Alternative: Run All at Once

You can also copy and paste all scripts into a single query window and run them together. The scripts use `IF NOT EXISTS` clauses, so they're safe to run multiple times.

## Verification Queries

After running all scripts, you can verify the setup:

```sql
-- Check if all new tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'ai_insights',
    'document_chunks',
    'ai_conversations',
    'ai_conversation_messages',
    'ai_analysis_cache'
  );

-- Check if all vector indexes exist
SELECT indexname, tablename 
FROM pg_indexes 
WHERE indexname LIKE '%embedding_idx%'
ORDER BY tablename, indexname;

-- Check if AI config keys exist
SELECT config_key, config_value 
FROM app_config 
WHERE config_key LIKE 'ai_%'
ORDER BY config_key;
```

## Notes

- All scripts use `IF NOT EXISTS` clauses, so they're idempotent (safe to run multiple times)
- Vector indexes use HNSW algorithm with optimized parameters (m=16, ef_construction=64)
- All embedding columns use 1536 dimensions (compatible with OpenAI text-embedding-3-small)
- Index creation may take a few minutes depending on table size

