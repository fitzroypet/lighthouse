# LightHouse - AI-Powered Education Platform

LightHouse is a data-driven education platform that digitises learning resources and student results, builds academic profiles over time, and uses AI to deliver personalised insights to schools, teachers, and parents in Nigeria.

## 🎯 Vision

To build the data backbone of African education, helping schools grow, teachers teach better, and parents feel empowered.

## 🧭 Platform Overview

This repository hosts the AI engine for LightHouse. The wider product teams embed these services into the full learning platform so schools can manage students, parents, and classrooms while benefiting from AI insights. PostgreSQL with pgvector powers both transactional storage and retrieval-augmented generation in a single stack.

## 🏗️ Architecture Highlights

- **PostgreSQL ERD** covering Nigeria's 6-3-3 education system with read-only roles and RLS
- **Vector-backed RAG pipeline** for curriculum-aware responses and embeddings
- **CrewAI agents** (Teacher, Parent, Orchestrator) orchestrated through the Lighthouse MCP tools
- **FastAPI backend** exposing REST + SSE endpoints secured with JWTs

## 🛣️ Roadmap Snapshot

- **Phase 1 – MVP (Aug/Sept 2025):** Schema design, bulk import flows, class/subject setup, result entry, student profiles
- **Phase 2 – Parent & Insights (Sept/Oct 2025):** Parent portal, dashboards, automated performance updates
- **Phase 3 – AI Features (Oct 2025):** RAG pipeline, conversational assistant, personalised learning suggestions
- **Phase 4 – Scale (Dec/Jan 2026):** Multi-school onboarding, government/NGO reporting, strategic partnerships

## 🏗️ Current Project Structure

```
/Users/petgrave/lighthouse/
├── 📋 docs/                           # Project documentation & roadmaps
│   ├── README.md                      # Detailed product documentation
│   ├── PRODUCT.md                     # Product strategy and roadmap
│   ├── PRODUCT_ROADMAP.md             # Development roadmap
│   ├── AI_ML_COMPONENTS.md            # AI engine specifications
│   └── AI_WORKFLOW_DIAGRAMS.md        # System architecture diagrams
├── 🗄️ schema/                         # Database schema assets
│   └── lighthouse_erd_schema.sql      # Main ERD schema
├── 🔧 backend/                        # FastAPI + CrewAI implementation
│   ├── app.py                         # API application entrypoint
│   ├── requirements.txt               # Python dependencies
│   ├── README.md                      # Backend-specific documentation
│   ├── env/                           # Environment configuration templates
│   │   └── .env.example
│   ├── lighthouse_mcp/                # Model Context Protocol server
│   │   └── lighthouse_mcp_server.py
│   ├── crew/                          # CrewAI demonstration scripts
│   │   └── crewai_mcp_example.py
│   └── sql/                           # Database setup & RAG scripts
│       ├── 01_rag_schema.sql
│       ├── 02_agent_views_and_functions.sql
│       ├── 03_readonly_role.sql
│       └── 04_rls_policies.sql
└── LICENSE                            # Project licence
```

## 🚀 Quick Start

### 1. Create and activate the virtualenv

```bash
python3.10 -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt
```

### 2. Configure environment variables

```bash
cd backend
cp env/.env.example .env  # one-time setup
# edit .env with your Neon URLs, JWT secret, and API keys
set -a && source .env && set +a  # load vars into the current shell
```

Run `echo $DATABASE_URL_RO` to confirm the value is available before starting any services.

### 3. Apply database schema (first-time only)

```bash
psql "$DATABASE_URL" -f ../schema/lighthouse_erd_schema.sql
psql "$DATABASE_URL" -f sql/01_rag_schema.sql
psql "$DATABASE_URL" -f sql/02_agent_views_and_functions.sql
psql "$DATABASE_URL" -f sql/03_readonly_role.sql
psql "$DATABASE_URL" -f sql/04_rls_policies.sql
```

### 4. Run the FastAPI backend

```bash
cd backend
set -a && source .env && set +a  # reload after opening a new shell
uvicorn app:app --reload --port 8001
```

The API lives at `http://127.0.0.1:8001` (adjust the port if 8001 is busy).

### 5. Run the CrewAI example locally

```bash
cd backend
set -a && source .env && set +a
python crew/crewai_mcp_example.py
```

You will see verbose logs from the orchestrator, teacher, and parent agents followed by the teacher's final summary.

## 🎯 Current Implementation Status

### ✅ Completed
- **Database Schema**: Complete ERD with Nigerian 6-3-3 education system
- **MCP Server**: Model Context Protocol server with safe database tools
- **CrewAI Agents**: Multi-agent system with Teacher, Parent, and Orchestrator personas
- **FastAPI Backend**: REST API with JWT authentication and streaming
- **Security**: Row-level security policies and read-only database role
- **Vector Database**: pgvector integration for RAG capabilities

### 🔄 In Progress
- **RAG Content Population**: Adding curriculum and help documentation
- **Embedding Provider**: OpenAI integration for vector embeddings
- **Frontend Development**: Web interface for agent interaction

### 📋 Next Steps
- **Data Population**: Add sample curriculum and student data
- **API Testing**: Comprehensive testing of all endpoints
- **Frontend**: Build web interface for parents, teachers, and students
- **Deployment**: Production deployment setup

## 🔧 Technical Stack

- **Backend**: FastAPI + Python 3.10
- **Database**: PostgreSQL with pgvector
- **AI Framework**: CrewAI with MCP integration
- **Authentication**: JWT-based security
- **Vector Search**: pgvector for embeddings
- **API**: RESTful with Server-Sent Events streaming

## 📚 API Endpoints

- `GET /` - Health check
- `POST /chat` - Chat with AI agents
- `POST /chat/stream` - Streaming chat responses
- `GET /docs` - Interactive API documentation

## 🤖 AI Agents

The system includes three specialized AI personas:

1. **Teacher Agent**: Helps with lesson planning, student assessment, and academic guidance
2. **Parent Agent**: Provides insights on student progress and learning recommendations
3. **Orchestrator Agent**: Coordinates between agents and manages complex queries

## 🔒 Security Features

- **Row-Level Security (RLS)**: Database-level access control
- **Read-Only Role**: Separate database role for agents
- **JWT Authentication**: Secure API access
- **Parameterized Queries**: SQL injection prevention

## 📖 Documentation

- [Backend Documentation](./backend/README.md) - Backend setup and API details
- [Product Documentation](./docs/PRODUCT.md) - Product strategy and roadmap
- [AI Components](./docs/AI_ML_COMPONENTS.md) - AI engine specifications
- [Database Schema](./schema/lighthouse_erd_schema.sql) - Complete ERD

## 🛠️ Development

### Prerequisites
- Python 3.10+ (use the provided virtualenv instructions)
- PostgreSQL 13+ with pgvector extension
- Neon database account (or local PostgreSQL)

### Environment Variables
```env
DATABASE_URL=postgresql://user:pass@host/db
DATABASE_URL_RO=postgresql://ro_user:pass@host/db
JWT_SECRET=your-jwt-secret
OPENAI_API_KEY=your-openai-key  # Optional
```

## 📞 Support

For questions about the implementation or integration, refer to the documentation in the `docs/` directory or check the backend README for technical details.

## 📄 License

MIT License
See [LICENSE](./LICENSE) for license information.

---

**Status**: ✅ **Fully Operational** - The LightHouse MCP Agent system is ready for development and testing!
