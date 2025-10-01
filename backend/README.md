# LightHouse Backend - MCP Agent System

This is the backend implementation of the LightHouse educational AI agent system using FastAPI, CrewAI, MCP (Model Context Protocol), and PostgreSQL with pgvector.

## ✅ Status: Fully Operational

The backend is fully set up and running! All components are working:
- ✅ Database schemas applied
- ✅ Dependencies installed  
- ✅ MCP server functional
- ✅ FastAPI server running
- ✅ CrewAI agents configured

## Quick Start

### Prerequisites
- Python 3.10+
- PostgreSQL database (Neon recommended)
- `.env` populated with database URLs, JWT secret, and API keys

### 1. Setup environment and dependencies
```bash
python3.10 -m venv ../.venv  # run once from the repo root
source ../.venv/bin/activate
pip install -r requirements.txt
cp env/.env.example .env  # first-time setup, then edit with real values
```

### 2. Load environment variables (every new shell)
```bash
set -a && source .env && set +a
# confirm
echo $DATABASE_URL_RO
```

### 3. Run the API locally
```bash
uvicorn app:app --reload --port 8001
```

Visit `http://127.0.0.1:8001/docs` for interactive documentation. Use a different port if 8001 is already taken.

## Architecture

- **FastAPI**: REST API with JWT auth and SSE streaming
- **MCP Server**: Exposes safe database tools via Model Context Protocol
- **CrewAI**: Multi-agent system with Teacher/Parent/Admin personas
- **PostgreSQL + pgvector**: Data storage with vector embeddings for RAG
- **Row-Level Security**: Ensures data privacy and access control

## API Endpoints

- `GET /` - Health check
- `POST /chat` - Get JSON response from agent
- `POST /chat/stream` - Get streaming response via Server-Sent Events
- `GET /docs` - Interactive API documentation

## AI Agents

The system includes three specialized AI personas:

1. **Teacher Agent**: Helps with lesson planning, student assessment, and academic guidance
2. **Parent Agent**: Provides insights on student progress and learning recommendations  
3. **Orchestrator Agent**: Coordinates between agents and manages complex queries

## Testing

```bash
# Test MCP server standalone
cd lighthouse_mcp && python lighthouse_mcp_server.py

# Test CrewAI integration
python crew/crewai_mcp_example.py

# Test API endpoints
curl -X POST "http://127.0.0.1:8001/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, I need help with math", "persona": "teacher"}'

# When testing RAG, provide a JWT and curriculum-focused prompt
curl -X POST "http://127.0.0.1:8001/chat" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-jwt>" \
  -d '{"message": "Give me the themes for JSS3 English Language.", "persona": "teacher"}'
```

## Populate RAG Embeddings

```bash
# Align existing databases with the latest schema changes (nullable class.term, RAG indexes)
psql "$DATABASE_URL" -f sql/06_apply_term_and_rag_index_updates.sql

# Ensure DATABASE_URL and OPENAI_API_KEY are set, then run:
python scripts/ingest_rag_data.py --include-results

# To ingest topics without student narratives:
python scripts/ingest_rag_data.py --topics-only
```

## Environment Variables

```env
DATABASE_URL=postgresql://user:pass@host/db
DATABASE_URL_RO=postgresql://ro_user:pass@host/db
JWT_SECRET=your-jwt-secret
OPENAI_API_KEY=your-openai-key  # Required when using rag_search embeddings
```

## Troubleshooting

- **Import errors**: Make sure your `.venv` is activated (`source ../.venv/bin/activate`)
- **Database connection**: Verify your DATABASE_URL in the .env file
- **Port conflicts**: Change the `--port` flag if 8001 is occupied
