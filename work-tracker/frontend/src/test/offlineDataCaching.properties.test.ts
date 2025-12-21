import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import * as fc from 'fast-check'
import { offlineService, SyncOperation } from '@/services/offlineService'
import { Activity, Story, Report, ActivityCategory, StoryStatus, ReportType, ReportStatus } from '@/types'

/**
 * Property-Based Tests for Offline Data Caching
 * 
 * **Property 12: Offline Data Caching**
 * **Validates: Requirements 7.4**
 * 
 * These tests verify that the offline caching system correctly stores,
 * retrieves, and synchronizes data when connectivity is lost and restored.
 */

// Simplified test data generators
const activityGenerator = fc.record({
  id: fc.uuid(),
  userId: fc.uuid(),
  title: fc.string({ minLength: 1, maxLength: 50 }),
  description: fc.option(fc.string({ maxLength: 100 })),
  category: fc.constantFrom(...Object.values(ActivityCategory)),
  tags: fc.array(fc.string({ minLength: 1, maxLength: 10 }), { maxLength: 3 }),
  impactLevel: fc.integer({ min: 1, max: 5 }),
  date: fc.date({ min: new Date('2020-01-01'), max: new Date('2025-12-31') }).map(d => d.toISOString().split('T')[0]),
  durationMinutes: fc.option(fc.integer({ min: 1, max: 240 })),
  metadata: fc.record({ key: fc.string() }),
  createdAt: fc.date().map(d => d.toISOString()),
  updatedAt: fc.date().map(d => d.toISOString())
}) as fc.Arbitrary<Activity>

const storyGenerator = fc.record({
  id: fc.uuid(),
  userId: fc.uuid(),
  title: fc.string({ minLength: 1, maxLength: 50 }),
  situation: fc.string({ minLength: 1, maxLength: 200 }),
  task: fc.string({ minLength: 1, maxLength: 200 }),
  action: fc.string({ minLength: 1, maxLength: 200 }),
  result: fc.string({ minLength: 1, maxLength: 200 }),
  impactMetrics: fc.record({ metric: fc.string() }),
  tags: fc.array(fc.string({ minLength: 1, maxLength: 10 }), { maxLength: 3 }),
  status: fc.constantFrom(...Object.values(StoryStatus)),
  aiEnhanced: fc.boolean(),
  createdAt: fc.date().map(d => d.toISOString()),
  updatedAt: fc.date().map(d => d.toISOString())
}) as fc.Arbitrary<Story>

describe('Offline Data Caching Properties', () => {
  beforeEach(async () => {
    // Initialize offline service for each test
    await offlineService.initialize()
    await offlineService.clearCache()
    
    // Mock navigator.onLine
    Object.defineProperty(navigator, 'onLine', {
      writable: true,
      value: true
    })
  })

  afterEach(async () => {
    // Clean up after each test
    await offlineService.clearCache()
    vi.restoreAllMocks()
  })

  describe('Activity Caching Properties', () => {
    it('Property 12.1: Cached activities preserve data integrity', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(activityGenerator, { minLength: 1, maxLength: 5 }),
          async (activities) => {
            // Ensure all activities have the same userId for testing
            const userId = activities[0].userId
            const normalizedActivities = activities.map(a => ({ ...a, userId }))
            
            // Cache activities
            await offlineService.cacheActivities(normalizedActivities)
            
            // Retrieve cached activities
            const cachedActivities = await offlineService.getCachedActivities(userId)
            
            // All original activities should be present in cache
            expect(cachedActivities).toHaveLength(normalizedActivities.length)
            
            // Each cached activity should match its original
            for (const original of normalizedActivities) {
              const cached = cachedActivities.find(c => c.id === original.id)
              expect(cached).toBeDefined()
              expect(cached).toEqual(original)
            }
          }
        ),
        { numRuns: 10 }
      )
    })

    it('Property 12.2: Activity cache updates preserve consistency', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(activityGenerator, { minLength: 1, maxLength: 3 }),
          async (activities) => {
            const userId = activities[0].userId
            const normalizedActivities = activities.map(a => ({ ...a, userId }))
            
            // Cache initial activities
            await offlineService.cacheActivities(normalizedActivities)
            
            // Create updated versions
            const updatedActivities = normalizedActivities.map(a => ({
              ...a,
              title: `Updated ${a.title}`,
              updatedAt: new Date().toISOString()
            }))
            
            // Update cache
            await offlineService.cacheActivities(updatedActivities)
            
            // Verify updates are reflected
            const cachedActivities = await offlineService.getCachedActivities(userId)
            
            expect(cachedActivities).toHaveLength(updatedActivities.length)
            
            for (const updated of updatedActivities) {
              const cached = cachedActivities.find(c => c.id === updated.id)
              expect(cached).toBeDefined()
              expect(cached!.title).toBe(updated.title)
            }
          }
        ),
        { numRuns: 8 }
      )
    })
  })

  describe('Story Caching Properties', () => {
    it('Property 12.3: Cached stories maintain STAR format integrity', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(storyGenerator, { minLength: 1, maxLength: 3 }),
          async (stories) => {
            const userId = stories[0].userId
            const normalizedStories = stories.map(s => ({ ...s, userId }))
            
            // Cache stories
            await offlineService.cacheStories(normalizedStories)
            
            // Retrieve and verify
            const cachedStories = await offlineService.getCachedStories(userId)
            
            expect(cachedStories).toHaveLength(normalizedStories.length)
            
            for (const original of normalizedStories) {
              const cached = cachedStories.find(c => c.id === original.id)
              expect(cached).toBeDefined()
              
              // Verify STAR format fields are preserved
              expect(cached!.situation).toBe(original.situation)
              expect(cached!.task).toBe(original.task)
              expect(cached!.action).toBe(original.action)
              expect(cached!.result).toBe(original.result)
              expect(cached!.status).toBe(original.status)
            }
          }
        ),
        { numRuns: 8 }
      )
    })
  })

  describe('Sync Queue Properties', () => {
    it('Property 12.4: Sync queue maintains operation integrity', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(
            fc.record({
              operation: fc.constantFrom(...Object.values(SyncOperation)),
              entityType: fc.constantFrom('activities', 'stories', 'reports'),
              entityId: fc.uuid(),
              data: fc.option(fc.record({ title: fc.string() }))
            }),
            { minLength: 1, maxLength: 5 }
          ),
          async (operations) => {
            // Add operations to sync queue
            for (const op of operations) {
              await offlineService.addToSyncQueue(
                op.operation,
                op.entityType as any,
                op.entityId,
                op.data
              )
            }
            
            // Retrieve pending operations
            const pendingOps = await offlineService.getPendingSyncOperations()
            
            // Should have all operations
            expect(pendingOps).toHaveLength(operations.length)
            
            // Each operation should be preserved correctly
            for (const original of operations) {
              const queued = pendingOps.find(p => 
                p.operation === original.operation &&
                p.entityType === original.entityType &&
                p.entityId === original.entityId
              )
              
              expect(queued).toBeDefined()
              expect(queued!.retryCount).toBe(0)
            }
          }
        ),
        { numRuns: 8 }
      )
    })

    it('Property 12.5: Sync operations can be removed without affecting others', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(
            fc.record({
              operation: fc.constantFrom(...Object.values(SyncOperation)),
              entityType: fc.constantFrom('activities', 'stories', 'reports'),
              entityId: fc.uuid()
            }),
            { minLength: 2, maxLength: 4 }
          ),
          async (operations) => {
            // Add all operations
            for (const op of operations) {
              await offlineService.addToSyncQueue(
                op.operation,
                op.entityType as any,
                op.entityId
              )
            }
            
            // Get initial queue
            const initialQueue = await offlineService.getPendingSyncOperations()
            const operationToRemove = initialQueue[0]
            
            // Remove one operation
            await offlineService.removeSyncOperation(operationToRemove.id)
            
            // Verify remaining operations
            const remainingQueue = await offlineService.getPendingSyncOperations()
            expect(remainingQueue).toHaveLength(operations.length - 1)
            
            // Removed operation should not be present
            const removedOp = remainingQueue.find(op => op.id === operationToRemove.id)
            expect(removedOp).toBeUndefined()
          }
        ),
        { numRuns: 6 }
      )
    })
  })

  describe('Cache Metadata Properties', () => {
    it('Property 12.6: Cache metadata reflects actual cache state', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.record({
            activities: fc.array(activityGenerator, { maxLength: 3 }),
            stories: fc.array(storyGenerator, { maxLength: 2 })
          }),
          async ({ activities, stories }) => {
            // Normalize user IDs
            const userId = 'test-user-id'
            const normalizedActivities = activities.map(a => ({ ...a, userId }))
            const normalizedStories = stories.map(s => ({ ...s, userId }))
            
            // Cache data
            if (normalizedActivities.length > 0) {
              await offlineService.cacheActivities(normalizedActivities)
            }
            if (normalizedStories.length > 0) {
              await offlineService.cacheStories(normalizedStories)
            }
            
            // Get cache info
            const cacheInfo = await offlineService.getCacheInfo()
            
            // Verify counts match (at least what we added)
            expect(cacheInfo.activitiesCount).toBeGreaterThanOrEqual(normalizedActivities.length)
            expect(cacheInfo.storiesCount).toBeGreaterThanOrEqual(normalizedStories.length)
            
            // Last sync should be recent
            expect(cacheInfo.lastSync).toBeGreaterThan(0)
          }
        ),
        { numRuns: 6 }
      )
    })
  })
})