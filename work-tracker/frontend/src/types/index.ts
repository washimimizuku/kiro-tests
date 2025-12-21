// Core type definitions for the Work Tracker application

export interface User {
  id: string
  email: string
  name: string
  cognitoUserId: string
  preferences: Record<string, any>
  createdAt: string
  updatedAt: string
}

export enum ActivityCategory {
  CUSTOMER_ENGAGEMENT = 'customer_engagement',
  LEARNING = 'learning',
  SPEAKING = 'speaking',
  MENTORING = 'mentoring',
  TECHNICAL_CONSULTATION = 'technical_consultation',
  CONTENT_CREATION = 'content_creation',
}

export interface Activity {
  id: string
  userId: string
  title: string
  description?: string
  category: ActivityCategory
  tags: string[]
  impactLevel: number // 1-5 scale
  date: string
  durationMinutes?: number
  metadata: Record<string, any>
  createdAt: string
  updatedAt: string
}

export enum StoryStatus {
  DRAFT = 'draft',
  COMPLETE = 'complete',
  PUBLISHED = 'published',
}

export interface Story {
  id: string
  userId: string
  title: string
  situation: string
  task: string
  action: string
  result: string
  impactMetrics: Record<string, any>
  tags: string[]
  status: StoryStatus
  aiEnhanced: boolean
  createdAt: string
  updatedAt: string
}

export enum ReportType {
  WEEKLY = 'weekly',
  MONTHLY = 'monthly',
  QUARTERLY = 'quarterly',
  ANNUAL = 'annual',
  CUSTOM = 'custom',
}

export enum ReportStatus {
  DRAFT = 'draft',
  GENERATING = 'generating',
  COMPLETE = 'complete',
  FAILED = 'failed',
}

export interface Report {
  id: string
  userId: string
  title: string
  periodStart: string
  periodEnd: string
  reportType: ReportType
  content?: string
  activitiesIncluded: string[]
  storiesIncluded: string[]
  generatedByAi: boolean
  status: ReportStatus
  createdAt: string
}

// API Response types
export interface ApiResponse<T> {
  data: T
  message?: string
  success: boolean
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

// Form types
export interface ActivityCreateRequest {
  title: string
  description?: string
  category: ActivityCategory
  tags: string[]
  impactLevel: number
  date: string
  durationMinutes?: number
  metadata?: Record<string, any>
}

export interface StoryCreateRequest {
  title: string
  situation: string
  task: string
  action: string
  result: string
  impactMetrics?: Record<string, any>
  tags: string[]
}

export interface ReportGenerateRequest {
  title: string
  periodStart: string
  periodEnd: string
  reportType: ReportType
  includeActivities?: string[]
  includeStories?: string[]
}

// Filter types
export interface ActivityFilters {
  category?: ActivityCategory
  tags?: string[]
  dateFrom?: string
  dateTo?: string
  impactLevel?: number
  search?: string
}

export interface StoryFilters {
  status?: StoryStatus
  tags?: string[]
  search?: string
  aiEnhanced?: boolean
}

// Authentication types
export interface LoginRequest {
  email: string
  password: string
}

export interface TokenResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
  user: User
}