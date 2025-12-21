# Work Tracker

A modern web-based professional activity tracking system built with React, FastAPI, and AWS services.

## Architecture

- **Frontend**: React with TypeScript
- **Backend**: FastAPI microservices
- **Database**: PostgreSQL
- **AI Services**: AWS Bedrock
- **Authentication**: AWS Cognito
- **Deployment**: AWS ECS Fargate + S3/CloudFront

## Project Structure

```
work-tracker/
├── frontend/           # React TypeScript application
├── backend/           # FastAPI microservices
├── docker-compose.yml # Local development environment
└── README.md         # This file
```

## Quick Start

1. **Prerequisites**
   - Docker and Docker Compose
   - Node.js 18+ (for frontend development)
   - Python 3.11+ (for backend development)

2. **Local Development**
   ```bash
   # Start all services
   docker-compose up -d
   
   # Frontend development server
   cd frontend && npm run dev
   
   # Backend development server
   cd backend && uvicorn app.main:app --reload
   ```

3. **Access Points**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs
   - Database: localhost:5432

## Development

See individual README files in `frontend/` and `backend/` directories for detailed development instructions.

## Deployment

The application is designed for AWS deployment using:
- ECS Fargate for backend services
- S3 + CloudFront for frontend
- RDS PostgreSQL for database
- AWS Bedrock for AI services