-- Work Tracker Database Initialization
-- This script creates the initial database schema for the Work Tracker application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    cognito_user_id VARCHAR(255) UNIQUE NOT NULL,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activities table
CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    tags TEXT[] DEFAULT '{}',
    impact_level INTEGER CHECK (impact_level >= 1 AND impact_level <= 5),
    date DATE NOT NULL,
    duration_minutes INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stories table
CREATE TABLE IF NOT EXISTS stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    situation TEXT NOT NULL,
    task TEXT NOT NULL,
    action TEXT NOT NULL,
    result TEXT NOT NULL,
    impact_metrics JSONB DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'draft',
    ai_enhanced BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reports table
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    report_type VARCHAR(20) NOT NULL,
    content TEXT,
    activities_included UUID[] DEFAULT '{}',
    stories_included UUID[] DEFAULT '{}',
    generated_by_ai BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_activities_user_date ON activities(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_activities_category ON activities(category);
CREATE INDEX IF NOT EXISTS idx_activities_tags ON activities USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_stories_user_status ON stories(user_id, status);
CREATE INDEX IF NOT EXISTS idx_reports_user_type ON reports(user_id, report_type);

-- Full-text search indexes
CREATE INDEX IF NOT EXISTS idx_activities_search ON activities USING GIN(to_tsvector('english', title || ' ' || COALESCE(description, '')));
CREATE INDEX IF NOT EXISTS idx_stories_search ON stories USING GIN(to_tsvector('english', title || ' ' || situation || ' ' || task || ' ' || action || ' ' || result));

-- Insert sample data for development
INSERT INTO users (email, name, cognito_user_id) VALUES 
    ('demo@example.com', 'Demo User', 'demo-cognito-id')
ON CONFLICT (email) DO NOTHING;

-- Activity categories enum check
ALTER TABLE activities ADD CONSTRAINT check_activity_category 
    CHECK (category IN ('customer_engagement', 'learning', 'speaking', 'mentoring', 'technical_consultation', 'content_creation'));

-- Story status enum check  
ALTER TABLE stories ADD CONSTRAINT check_story_status
    CHECK (status IN ('draft', 'complete', 'published'));

-- Report type enum check
ALTER TABLE reports ADD CONSTRAINT check_report_type
    CHECK (report_type IN ('weekly', 'monthly', 'quarterly', 'annual', 'custom'));

-- Report status enum check
ALTER TABLE reports ADD CONSTRAINT check_report_status
    CHECK (status IN ('draft', 'generating', 'complete', 'failed'));

-- Update triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stories_updated_at BEFORE UPDATE ON stories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();