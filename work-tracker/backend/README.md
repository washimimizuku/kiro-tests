# Work Tracker Backend

FastAPI backend services for the Work Tracker application.

## Tech Stack

- **FastAPI** with async/await support
- **SQLAlchemy** with async PostgreSQL
- **Alembic** for database migrations
- **Redis** for caching and sessions
- **AWS Bedrock** for AI services
- **AWS Cognito** for authentication
- **pytest** for testing
- **Hypothesis** for property-based testing

## Development

1. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start development server**
   ```bash
   uvicorn app.main:app --reload
   ```

4. **Run tests**
   ```bash
   pytest
   ```

## Project Structure

```
app/
├── api/               # API routes and endpoints
│   └── v1/           # API version 1
├── core/             # Core configuration and database
├── models/           # SQLAlchemy database models
├── schemas/          # Pydantic request/response schemas
├── services/         # Business logic services
└── main.py           # FastAPI application entry point
```

## Environment Variables

Create a `.env` file in the backend directory:

```env
# Database
DATABASE_URL=postgresql://work_tracker_user:work_tracker_password@localhost:5432/work_tracker

# Redis
REDIS_URL=redis://localhost:6379

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Cognito
COGNITO_USER_POOL_ID=your-user-pool-id
COGNITO_CLIENT_ID=your-client-id
COGNITO_CLIENT_SECRET=your-client-secret

# Security
SECRET_KEY=your-secret-key-change-in-production
```

## API Documentation

When running in development mode, API documentation is available at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Database Migrations

```bash
# Create a new migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Downgrade migrations
alembic downgrade -1
```

## Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app

# Run property-based tests only
pytest -m property

# Run specific test file
pytest tests/test_activities.py
```

## Deployment

The backend is designed for deployment on:
- AWS ECS Fargate
- Docker containers
- Any container orchestration platform

Build the Docker image:
```bash
docker build -t work-tracker-backend .
```