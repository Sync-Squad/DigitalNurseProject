---
name: Vector Database and RAG-Based AI Features Implementation
overview: Transform Digital Nurse into an AI-powered health assistant by adding pgvector extension, creating vector embeddings for all text data, building new AI analysis tables, and implementing comprehensive RAG-based features for health analysis, recommendations, semantic search, and conversational AI assistant.
todos:
  - id: install-pgvector
    content: Install pgvector extension in PostgreSQL database using CREATE EXTENSION
    status: completed
  - id: add-vector-columns
    content: Add vector embedding columns to existing tables (caregiver_notes, medications, vital_measurements, diet_logs, exercise_logs, med_intakes, user_documents)
    status: completed
    dependencies:
      - install-pgvector
  - id: create-vector-indexes
    content: Create HNSW vector indexes for all embedding columns to enable fast similarity search
    status: completed
    dependencies:
      - add-vector-columns
  - id: create-ai-insights-table
    content: Create ai_insights table with vector embedding support for storing AI-generated health insights
    status: completed
    dependencies:
      - install-pgvector
  - id: create-document-chunks-table
    content: Create document_chunks table for storing chunked document content with embeddings for document Q&A feature
    status: completed
    dependencies:
      - install-pgvector
  - id: create-ai-conversations-tables
    content: Create ai_conversations and ai_conversation_messages tables for storing chat history with AI assistant
    status: completed
  - id: create-ai-analysis-cache-table
    content: Create ai_analysis_cache table for caching expensive AI analysis results
    status: completed
    dependencies:
      - install-pgvector
  - id: add-ai-config-keys
    content: Add AI-related configuration keys to app_config table (embedding model, dimensions, thresholds, etc.)
    status: completed
  - id: implement-embedding-service
    content: Create EmbeddingService in backend to generate embeddings using OpenAI/Gemini API with batch processing support
    status: completed
    dependencies:
      - add-ai-config-keys
  - id: implement-vector-search-service
    content: Create VectorSearchService for semantic search across all tables with similarity threshold management
    status: completed
    dependencies:
      - create-vector-indexes
      - implement-embedding-service
  - id: implement-ai-health-analyst
    content: Create AIHealthAnalystService for medication adherence analysis, health trend detection, and pattern recognition
    status: completed
    dependencies:
      - implement-vector-search-service
  - id: implement-ai-insights-service
    content: Create AIInsightsService for generating, storing, and retrieving AI-generated insights with expiration management
    status: completed
    dependencies:
      - create-ai-insights-table
      - implement-ai-health-analyst
  - id: implement-ai-assistant-service
    content: Create AIAssistantService with RAG implementation for context-aware conversational AI using database context
    status: completed
    dependencies:
      - implement-vector-search-service
      - create-ai-conversations-tables
  - id: implement-document-processor
    content: Create DocumentProcessorService for chunking documents, extracting text, and generating embeddings
    status: completed
    dependencies:
      - create-document-chunks-table
      - implement-embedding-service
  - id: create-ai-controller
    content: Create AIController with endpoints for insights, analysis, search, chat, and recommendations
    status: completed
    dependencies:
      - implement-ai-insights-service
      - implement-ai-assistant-service
      - implement-vector-search-service
  - id: create-ai-module
    content: Create AI module in NestJS with all services, controllers, and DTOs properly wired together
    status: completed
    dependencies:
      - create-ai-controller
  - id: create-ai-assistant-screen
    content: Create AI Assistant screen in Flutter with chat interface, voice input, quick actions, and source citations
    status: completed
    dependencies:
      - create-ai-module
  - id: create-ai-insights-screen
    content: Create AI Insights screen in Flutter with filterable list, priority badges, expandable cards, and action buttons
    status: completed
    dependencies:
      - create-ai-module
  - id: create-health-analysis-screen
    content: Create Health Analysis screen in Flutter with trend visualizations, adherence charts, and recommendations
    status: completed
    dependencies:
      - create-ai-module
  - id: create-semantic-search-screen
    content: Create Semantic Search screen in Flutter with natural language search, grouped results, and relevance scores
    status: completed
    dependencies:
      - create-ai-module
  - id: create-document-qa-screen
    content: Create Document Q&A screen in Flutter with document selector, question input, and source citations
    status: completed
    dependencies:
      - implement-document-processor
  - id: create-ai-widgets
    content: Create reusable AI widgets (AIInsightCard, AIChatBubble, HealthTrendChart, RecommendationCard)
    status: completed
    dependencies:
      - create-ai-assistant-screen
      - create-ai-insights-screen
  - id: integrate-ai-dashboard
    content: Integrate AI insights widget into home dashboard for both patient and caregiver views
    status: completed
    dependencies:
      - create-ai-widgets
  - id: implement-batch-embedding
    content: Create background job/service to generate embeddings for existing data in batches
    status: completed
    dependencies:
      - implement-embedding-service
      - add-vector-columns
  - id: implement-automated-insights
    content: Create scheduled job to automatically generate daily/weekly insights for users
    status: completed
    dependencies:
      - implement-ai-insights-service
---

# Vector Database and RAG-Based AI Features Implementation Plan

## Overview

This plan transforms Digital Nurse into an AI-powered health assistant by:

1. Installing pgvector extension for vector similarity search
2. Adding vector embedding columns to existing tables
3. Creating new tables for AI-generated insights and document chunks
4. Building backend services for embedding generation, vector search, and AI analysis
5. Designing mobile app UI/UX for AI features
6. Implementing RAG (Retrieval-Augmented Generation) for context-aware AI responses

## Database Changes (Using PostgreSQL MCP Tool)

### Phase 1: Install pgvector Extension

```sql
-- Step 1: Install pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify installation
SELECT * FROM pg_extension WHERE extname = 'vector';
```

### Phase 2: Add Vector Columns to Existing Tables

Add embedding columns to tables with text content that can benefit from semantic search:

```sql
-- Caregiver Notes: Embedding for note_text
ALTER TABLE caregiver_notes 
ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Medications: Embedding for combined notes + instructions
ALTER TABLE medications 
ADD COLUMN IF NOT EXISTS notes_embedding vector(1536);

-- Vital Measurements: Embedding for notes
ALTER TABLE vital_measurements 
ADD COLUMN IF NOT EXISTS notes_embedding vector(1536);

-- Diet Logs: Embedding for food_items and notes
ALTER TABLE diet_logs 
ADD COLUMN IF NOT EXISTS food_items_embedding vector(1536);
ALTER TABLE diet_logs 
ADD COLUMN IF NOT EXISTS notes_embedding vector(1536);

-- Exercise Logs: Embedding for description and notes
ALTER TABLE exercise_logs 
ADD COLUMN IF NOT EXISTS description_embedding vector(1536);
ALTER TABLE exercise_logs 
ADD COLUMN IF NOT EXISTS notes_embedding vector(1536);

-- Med Intakes: Embedding for notes
ALTER TABLE med_intakes 
ADD COLUMN IF NOT EXISTS notes_embedding vector(1536);

-- User Documents: Embedding for title + description (content will be in separate chunks table)
ALTER TABLE user_documents 
ADD COLUMN IF NOT EXISTS metadata_embedding vector(1536);
```

### Phase 3: Create Vector Indexes for Fast Similarity Search

```sql
-- Create HNSW indexes for efficient vector similarity search
-- Using cosine distance (<=> operator) for semantic similarity

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
```

### Phase 4: Create New AI-Focused Tables

#### 4.1: AI Insights Table

Stores AI-generated health insights, recommendations, and analysis:

```sql
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
```

#### 4.2: Document Chunks Table

For storing chunked document content with embeddings (for document Q&A):

```sql
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
```

#### 4.3: AI Conversations Table

Store chat history with AI assistant:

```sql
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
```

#### 4.4: AI Analysis Cache Table

Cache expensive AI analysis results:

```sql
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
```

### Phase 5: Add Configuration for AI Features

```sql
-- Add AI-related configuration keys
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
```

## Backend Implementation

### New Services to Create

1. **Embedding Service** (`backend/src/ai/services/embedding.service.ts`)

   - Generate embeddings using OpenAI or Gemini
   - Batch processing for efficiency
   - Handle rate limiting

2. **Vector Search Service** (`backend/src/ai/services/vector-search.service.ts`)

   - Semantic search across all tables
   - Hybrid search (vector + metadata filters)
   - Similarity threshold management

3. **AI Health Analyst Service** (`backend/src/ai/services/ai-health-analyst.service.ts`)

   - Medication adherence analysis
   - Health trend detection
   - Pattern recognition across vitals, diet, exercise

4. **AI Insights Service** (`backend/src/ai/services/ai-insights.service.ts`)

   - Generate automated insights
   - Store and retrieve insights
   - Insight expiration management

5. **AI Assistant Service** (`backend/src/ai/services/ai-assistant.service.ts`)

   - RAG-based conversational AI
   - Context retrieval from database
   - Multi-turn conversation management

6. **Document Processing Service** (`backend/src/ai/services/document-processor.service.ts`)

   - Chunk documents intelligently
   - Extract text from PDFs/images
   - Generate embeddings for chunks

### New Controllers to Create

1. **AI Controller** (`backend/src/ai/ai.controller.ts`)

   - `/api/ai/insights` - Get AI insights
   - `/api/ai/analyze` - Trigger health analysis
   - `/api/ai/search` - Semantic search
   - `/api/ai/chat` - AI assistant chat
   - `/api/ai/recommendations` - Get personalized recommendations

### Module Structure

```
backend/src/ai/
├── ai.module.ts
├── ai.controller.ts
├── services/
│   ├── embedding.service.ts
│   ├── vector-search.service.ts
│   ├── ai-health-analyst.service.ts
│   ├── ai-insights.service.ts
│   ├── ai-assistant.service.ts
│   └── document-processor.service.ts
└── dto/
    ├── generate-insight.dto.ts
    ├── chat-message.dto.ts
    ├── semantic-search.dto.ts
    └── health-analysis.dto.ts
```

## Mobile App UI/UX Design

### New Screens to Create

#### 1. AI Assistant Screen (`mobile/lib/features/ai/screens/ai_assistant_screen.dart`)

- Chat interface with message bubbles
- Voice input option
- Quick action buttons (e.g., "Analyze my health", "Check medications")
- Context indicators showing what data is being used
- Source citations for AI responses

#### 2. AI Insights Screen (`mobile/lib/features/ai/screens/ai_insights_screen.dart`)

- List of AI-generated insights
- Filter by type (medication, health, lifestyle)
- Priority badges (low, medium, high, critical)
- Expandable cards with details and recommendations
- Action buttons (e.g., "View related data", "Dismiss")

#### 3. Health Analysis Screen (`mobile/lib/features/ai/screens/health_analysis_screen.dart`)

- Comprehensive health dashboard
- Trend visualizations
- Medication adherence charts
- Lifestyle correlation analysis
- Personalized recommendations section

#### 4. Semantic Search Screen (`mobile/lib/features/ai/screens/semantic_search_screen.dart`)

- Natural language search bar
- Results grouped by type (notes, medications, vitals, etc.)
- Relevance scores
- Quick preview of results
- Deep link to source data

#### 5. Document Q&A Screen (`mobile/lib/features/ai/screens/document_qa_screen.dart`)

- Document selector
- Question input
- Answer display with source citations
- Related document suggestions

### New Widgets to Create

1. **AI Insight Card** (`mobile/lib/features/ai/widgets/ai_insight_card.dart`)

   - Displays insight with priority indicator
   - Expandable for full details
   - Action buttons

2. **AI Chat Bubble** (`mobile/lib/features/ai/widgets/ai_chat_bubble.dart`)

   - User and assistant message bubbles
   - Loading indicators
   - Source citations

3. **Health Trend Chart** (`mobile/lib/features/ai/widgets/health_trend_chart.dart`)

   - Interactive charts for health trends
   - AI annotations on significant points

4. **Recommendation Card** (`mobile/lib/features/ai/widgets/recommendation_card.dart`)

   - Actionable recommendations
   - Implementation tracking

### Integration Points

- **Dashboard Integration**: Add AI insights widget to home dashboard
- **Medication Screen**: Show AI recommendations for medication timing
- **Vitals Screen**: Display AI-detected trends
- **Profile Screen**: Add AI assistant quick access

## Feature Roadmap

### Phase 1: Foundation (Weeks 1-2)

- Install pgvector extension
- Add vector columns to existing tables
- Create vector indexes
- Create new AI tables
- Set up embedding service
- Basic vector search implementation

### Phase 2: Core AI Services (Weeks 3-4)

- Health analysis service
- AI insights generation
- Semantic search service
- Document processing service
- Backend API endpoints

### Phase 3: AI Assistant (Weeks 5-6)

- RAG implementation
- Conversation management
- Context retrieval
- AI assistant service
- Chat API endpoints

### Phase 4: Mobile UI (Weeks 7-8)

- AI Assistant screen
- AI Insights screen
- Health Analysis screen
- Semantic Search screen
- Dashboard integration

### Phase 5: Advanced Features (Weeks 9-10)

- Document Q&A
- Automated insight generation (scheduled jobs)
- Advanced pattern detection
- Personalized recommendations engine
- Multi-language support for AI

## Key Features to Implement

### 1. Health Analysis Features

- **Medication Adherence Analysis**: Pattern detection, missed dose predictions
- **Health Trend Detection**: Identify concerning patterns in vitals
- **Lifestyle Correlation**: Connect diet/exercise to health outcomes
- **Risk Assessment**: Early warning system for health issues

### 2. AI Assistant Features

- **Natural Language Queries**: "How's my blood pressure been?"
- **Context-Aware Responses**: Uses patient's actual data
- **Multi-Turn Conversations**: Follow-up questions
- **Action Execution**: "Remind me to take my medication"

### 3. Semantic Search Features

- **Cross-Entity Search**: Search across notes, medications, vitals
- **Natural Language**: "Find notes about dizziness"
- **Relevance Ranking**: Most relevant results first
- **Quick Actions**: Direct links to edit/view source data

### 4. Automated Insights

- **Daily Health Summary**: AI-generated daily reports
- **Medication Reminders**: Smart reminders based on patterns
- **Health Alerts**: Proactive warnings about concerning trends
- **Lifestyle Recommendations**: Personalized suggestions

### 5. Document Intelligence

- **Document Q&A**: Ask questions about uploaded medical documents
- **Information Extraction**: Extract key data from documents
- **Document Summarization**: AI-generated summaries
- **Cross-Reference**: Link document info to health data

## Technical Considerations

### Embedding Model Choice

- **OpenAI text-embedding-3-small**: 1536 dimensions, cost-effective
- **Alternative**: Use Gemini's embedding capabilities if available
- Store model choice in `app_config` for flexibility

### Performance Optimization

- Batch embedding generation for existing data
- Cache frequently accessed embeddings
- Use background jobs for insight generation
- Implement pagination for search results

### Privacy & Security

- Embeddings stored locally in database
- No data sent to external services without consent
- User can opt-out of AI features
- Audit logs for AI-generated insights

### Scalability

- Vector indexes (HNSW) for fast similarity search
- Partition large tables if needed
- Background processing for heavy operations
- Rate limiting for AI API calls

## Success Metrics

- **User Engagement**: % of users using AI features weekly
- **Insight Accuracy**: User feedback on insight relevance
- **Search Performance**: Average response time < 500ms
- **Adherence Improvement**: Medication adherence % increase
- **User Satisfaction**: App store ratings and reviews

## Next Steps After Implementation

1. **A/B Testing**: Test different AI models and prompts
2. **User Feedback Loop**: Collect feedback to improve AI responses
3. **Advanced Analytics**: Build analytics dashboard for AI usage
4. **Integration Expansion**: Connect with more health data sources
5. **Telemedicine Integration**: Use AI insights in telemedicine consultations