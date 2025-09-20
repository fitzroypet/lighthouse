# LightHouse - AI-Powered Education Platform

LightHouse is a data-driven education platform that digitizes learning resources and student results, builds academic profiles over time, and uses AI to deliver personalized insights to schools, teachers, and parents in Nigeria.

## 🎯 Vision

To build the data backbone of African education, helping schools grow, teachers teach better, and parents feel empowered.

## 🚀 Project Overview

This repository contains the AI engine components of the LightHouse application. The engineering and development teams will integrate these components into the full platform. The system uses PostgreSQL with vector database capabilities within the same database for efficient data management and AI-powered insights.

## 🏗️ Architecture

### Database Schema
- **PostgreSQL**: Primary database with vector extensions for AI capabilities
- **Schema**: Comprehensive ERD covering Nigerian 6-3-3 education system
- **Vector Support**: Built-in vector database for RAG (Retrieval-Augmented Generation) and embeddings

### Key Components
- Student management and academic tracking
- Teacher assignment and result entry systems
- Parent portal for real-time access
- AI insights and conversational assistant
- Comprehensive reporting and analytics

## 📋 Current Status

### Phase 1: MVP (Aug/Sept 2025)
- ✅ Database schema design
- 🔄 Bulk student/parent import system
- 📋 Class & subject configuration
- 📋 Result entry forms
- 📋 Student profile management

### Phase 2: Parent & Insights (Sept/Oct 2025)
- 📋 Parent portal development
- 📋 Summary dashboards
- 📋 Automated performance updates

### Phase 3: AI Features (Oct 2025)
- 📋 RAG data pipeline
- 📋 Conversational assistant
- 📋 Personalized learning suggestions

### Phase 4: Scale (Dec/Jan 2026)
- 📋 Multi-school onboarding
- 📋 Government & NGO reporting
- 📋 Strategic partnerships

## 🛠️ Development Setup

### Prerequisites
- PostgreSQL 13+ with vector extensions
- Python 3.9+
- Node.js 16+ (for frontend components)

### Database Setup

1. **Initialize the database schema:**
   ```bash
   psql -U your_username -d your_database -f lighthouse_erd_schema.sql
   ```

2. **Enable vector extensions (if not already enabled):**
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

### Environment Configuration

Create a `.env` file in the project root:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/lighthouse
VECTOR_EMBEDDING_MODEL=text-embedding-ada-002
OPENAI_API_KEY=your_openai_api_key
```

## 📊 Database Schema Overview

### Core Entities
- **school**: School information and configuration
- **app_user**: Users with role-based access (admin, teacher, parent)
- **class**: Academic classes following Nigerian 6-3-3 system
- **subject**: Subjects taught in each class
- **student**: Student profiles and academic history

### Curriculum Hierarchy
- **theme**: Subject themes and modules
- **topic**: Individual topics with learning outcomes and coverage tracking

### Assessment & Results
- **result**: CA1, CA2, and exam scores with automated totals
- **grading_scheme**: Configurable grading systems (WAEC-compliant)
- **assessment_weight**: Flexible assessment weighting per class/subject

### AI & Analytics
- **behaviour_skill**: JSONB storage for behavioral and skills assessment
- Vector embeddings for curriculum content and student data

## 🎯 Key Features

### For School Administrators
- Bulk import of students, parents, and enrollments
- Class and subject configuration for Nigerian curriculum
- Teacher assignment management
- Comprehensive dashboards and analytics

### For Teachers
- Easy result entry with spreadsheet support
- Student progress tracking
- Resource upload and management
- Predictive alerts for at-risk students

### For Parents
- Real-time access to results and teacher remarks
- SMS notifications for low-connectivity areas
- AI-powered insights and recommendations
- Historical performance tracking

### For Students
- Digital learning material access
- Academic history and development tracking
- Personalized learning suggestions

## 🤖 AI Capabilities

### RAG (Retrieval-Augmented Generation)
- Integration of results data with curriculum content
- Contextual insights based on student performance
- Personalized learning recommendations

### Conversational Assistant
- Parent-facing beta for academic guidance
- Teacher support for student assessment
- Predictive analytics for early intervention

### Vector Database Integration
- Efficient storage and retrieval of embeddings
- Semantic search across curriculum and student data
- Real-time insights generation

## 📈 Roadmap & Milestones

### Immediate Priorities (P0)
- [ ] Bulk import system for students/parents/enrollments
- [ ] Class & subject configuration UI
- [ ] Result entry forms with spreadsheet ingestion
- [ ] Auto totals & WAEC grading
- [ ] Parent portal development

### Short-term Goals (P1)
- [ ] Data validators & error reporting
- [ ] SMS notification pipeline
- [ ] RAG data pipeline
- [ ] Conversational assistant
- [ ] Early-warning prediction models

### Long-term Vision (P2)
- [ ] Multi-school setup & permissions
- [ ] NGO/Government reporting modules
- [ ] Billing & subscription management
- [ ] Advanced analytics and insights

## 🔧 Technical Stack

- **Database**: PostgreSQL with vector extensions
- **Backend**: Python (FastAPI/Django)
- **Frontend**: React/Next.js
- **AI/ML**: OpenAI API, vector embeddings
- **Deployment**: Docker, AWS/Azure
- **Monitoring**: Comprehensive logging and analytics

## 📚 Documentation

- [Product Documentation](./PRODUCT.md) - Detailed product strategy and roadmap
- [AI/ML Components](./AI_ML_COMPONENTS.md) - Comprehensive AI engine specifications
- [AI Workflow Diagrams](./AI_WORKFLOW_DIAGRAMS.md) - Visual system architecture and data flows
- [API Documentation](./docs/api/) - API endpoints and integration guides
- [Database Schema](./lighthouse_erd_schema.sql) - Complete ERD with comments

## 🤝 Contributing

This project is currently in active development. For integration with the main application:

1. Review the database schema and ensure compatibility
2. Test AI engine components in isolation
3. Follow the established data models for consistency
4. Coordinate with the main development team for integration

## 📞 Support

For questions about the AI engine components or database schema, please contact the development team or refer to the product documentation.

## 📄 License

[Add your license information here]

---

**Note**: This repository contains the AI engine components of LightHouse. The full application integration will be handled by the engineering and development teams.
