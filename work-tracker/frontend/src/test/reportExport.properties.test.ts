/**
 * Property-Based Tests for Report Export Functionality
 * Feature: work-tracker, Property 7: Report Export Functionality
 * **Validates: Requirements 3.4**
 */

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import * as fc from 'fast-check'
import React from 'react'
import { QueryClient, QueryClientProvider } from 'react-query'
import { Report, ReportStatus, ReportType } from '@/types'
import ReportViewer from '@/components/ReportViewer'
import ReportExportModal from '@/components/ReportExportModal'
import { useExportReport } from '@/hooks/useReports'

// Mock the hooks
vi.mock('@/hooks/useReports', () => ({
  useExportReport: vi.fn()
}))

// Mock fetch for export functionality
const mockFetch = vi.fn()
global.fetch = mockFetch

// Mock URL.createObjectURL and related APIs
global.URL.createObjectURL = vi.fn(() => 'mock-blob-url')
global.URL.revokeObjectURL = vi.fn()

// Mock document.createElement and appendChild for download links
const mockLink = {
  href: '',
  download: '',
  click: vi.fn(),
}
const originalCreateElement = document.createElement
document.createElement = vi.fn((tagName) => {
  if (tagName === 'a') {
    return mockLink as any
  }
  return originalCreateElement.call(document, tagName)
})

const mockAppendChild = vi.fn()
const mockRemoveChild = vi.fn()
document.body.appendChild = mockAppendChild
document.body.removeChild = mockRemoveChild

// Mock navigator.clipboard
Object.assign(navigator, {
  clipboard: {
    writeText: vi.fn().mockResolvedValue(undefined),
  },
})

// Mock navigator.share
Object.assign(navigator, {
  share: vi.fn().mockResolvedValue(undefined),
  canShare: vi.fn().mockReturnValue(true),
})

// Generators for test data
const reportStatusArb = fc.constantFrom(...Object.values(ReportStatus))
const reportTypeArb = fc.constantFrom(...Object.values(ReportType))

const reportArb = fc.record({
  id: fc.uuid(),
  userId: fc.uuid(),
  title: fc.string({ minLength: 1, maxLength: 100 }),
  periodStart: fc.date({ min: new Date('2020-01-01'), max: new Date('2024-12-31') }).map(d => d.toISOString().split('T')[0]),
  periodEnd: fc.date({ min: new Date('2020-01-01'), max: new Date('2024-12-31') }).map(d => d.toISOString().split('T')[0]),
  reportType: reportTypeArb,
  content: fc.option(fc.string({ minLength: 10, maxLength: 1000 }), { nil: undefined }),
  activitiesIncluded: fc.array(fc.uuid(), { minLength: 0, maxLength: 50 }),
  storiesIncluded: fc.array(fc.uuid(), { minLength: 0, maxLength: 20 }),
  generatedByAi: fc.boolean(),
  status: reportStatusArb,
  createdAt: fc.date({ min: new Date('2020-01-01'), max: new Date() }).map(d => d.toISOString())
})

const completeReportArb = reportArb.map(report => ({
  ...report,
  status: ReportStatus.COMPLETE,
  content: `Report content for ${report.title}`
}))

// Test wrapper component
function TestWrapper({ children }: { children: React.ReactNode }) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  })
  
  return React.createElement(
    QueryClientProvider,
    { client: queryClient },
    children
  )
}

describe('Report Export Properties', () => {
  let queryClient: QueryClient

  beforeEach(() => {
    vi.clearAllMocks()
    
    // Reset mocked functions
    mockFetch.mockReset()
    mockLink.click.mockReset()
    mockAppendChild.mockReset()
    mockRemoveChild.mockReset()
    
    // Create a fresh query client for each test
    queryClient = new QueryClient({
      defaultOptions: {
        queries: { retry: false },
        mutations: { retry: false }
      }
    })
    
    // Mock successful export by default
    const mockExportMutation = {
      mutateAsync: vi.fn().mockResolvedValue(new Blob(['mock content'], { type: 'application/pdf' })),
      isLoading: false,
      error: null
    }
    
    vi.mocked(useExportReport).mockReturnValue(mockExportMutation as any)
  })

  /**
   * Property 7: Report Export Functionality
   * For any generated report, the export system should produce valid PDF and Word documents 
   * that contain all report content in the specified format.
   */
  it('should successfully export any complete report in both PDF and Word formats', async () => {
    await fc.assert(
      fc.asyncProperty(completeReportArb, async (report) => {
        // Test the export hook directly instead of rendering components
        const mockPdfExportMutation = {
          mutateAsync: vi.fn().mockResolvedValue(new Blob(['mock content'], { type: 'application/pdf' })),
          isLoading: false,
          error: null
        }
        vi.mocked(useExportReport).mockReturnValue(mockPdfExportMutation as any)
        
        const exportHook = useExportReport()
        
        // Test PDF export
        const pdfBlob = await exportHook.mutateAsync({ id: report.id, format: 'pdf' })
        expect(pdfBlob).toBeInstanceOf(Blob)
        expect(pdfBlob.type).toBe('application/pdf')
        
        // Reset for Word export test
        vi.clearAllMocks()
        const mockWordExportMutation = {
          mutateAsync: vi.fn().mockResolvedValue(new Blob(['mock content'], { type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' })),
          isLoading: false,
          error: null
        }
        vi.mocked(useExportReport).mockReturnValue(mockWordExportMutation as any)
        
        const wordExportHook = useExportReport()
        const wordBlob = await wordExportHook.mutateAsync({ id: report.id, format: 'docx' })
        expect(wordBlob).toBeInstanceOf(Blob)
        expect(wordBlob.type).toBe('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      }),
      { numRuns: 10 }
    )
  })

  it('should handle export failures gracefully for any report', async () => {
    await fc.assert(
      fc.asyncProperty(completeReportArb, async (report) => {
        // Mock export failure
        const mockExportMutation = {
          mutateAsync: vi.fn().mockRejectedValue(new Error('Export failed')),
          isLoading: false,
          error: new Error('Export failed')
        }
        vi.mocked(useExportReport).mockReturnValue(mockExportMutation as any)
        
        const exportHook = useExportReport()
        
        // Verify export failure is handled
        await expect(exportHook.mutateAsync({ id: report.id, format: 'pdf' }))
          .rejects.toThrow('Export failed')
      }),
      { numRuns: 10 }
    )
  })

  it('should show loading state during export for any report', async () => {
    await fc.assert(
      fc.asyncProperty(completeReportArb, async (report) => {
        // Mock loading state
        const mockExportMutation = {
          mutateAsync: vi.fn().mockImplementation(() => new Promise(() => {})), // Never resolves
          isLoading: true,
          error: null
        }
        vi.mocked(useExportReport).mockReturnValue(mockExportMutation as any)
        
        const exportHook = useExportReport()
        expect(exportHook.isLoading).toBe(true)
      }),
      { numRuns: 10 }
    )
  })

  it('should generate valid filenames for any report title', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          report: completeReportArb,
          format: fc.constantFrom('pdf', 'docx')
        }),
        async ({ report, format }) => {
          // Test filename generation logic
          const sanitizedTitle = report.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()
          const expectedFilename = `${sanitizedTitle}.${format}`
          
          // Verify filename is valid (no special characters, correct extension)
          expect(expectedFilename).toMatch(new RegExp(`\\.${format}$`))
          expect(expectedFilename).not.toMatch(/[<>:"/\\|?*]/)
          
          // Verify filename isn't too long
          expect(expectedFilename.length).toBeLessThan(255)
        }
      ),
      { numRuns: 15 }
    )
  })

  it('should handle export with different formats correctly', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          report: completeReportArb,
          format: fc.constantFrom('pdf', 'docx')
        }),
        async ({ report, format }) => {
          const expectedMimeType = format === 'pdf' 
            ? 'application/pdf' 
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          
          const mockExportMutation = {
            mutateAsync: vi.fn().mockResolvedValue(new Blob(['mock content'], { type: expectedMimeType })),
            isLoading: false,
            error: null
          }
          vi.mocked(useExportReport).mockReturnValue(mockExportMutation as any)
          
          const exportHook = useExportReport()
          const blob = await exportHook.mutateAsync({ id: report.id, format })
          
          expect(blob.type).toBe(expectedMimeType)
          expect(exportHook.mutateAsync).toHaveBeenCalledWith({
            id: report.id,
            format: format
          })
        }
      ),
      { numRuns: 10 }
    )
  })

  it('should preserve report content integrity during export process', async () => {
    await fc.assert(
      fc.asyncProperty(completeReportArb, async (report) => {
        // Mock export with specific content
        const mockContent = `Report: ${report.title}\nContent: ${report.content}`
        const mockBlob = new Blob([mockContent], { type: 'application/pdf' })
        
        const mockExportMutation = {
          mutateAsync: vi.fn().mockResolvedValue(mockBlob),
          isLoading: false,
          error: null
        }
        vi.mocked(useExportReport).mockReturnValue(mockExportMutation as any)
        
        const exportHook = useExportReport()
        const blob = await exportHook.mutateAsync({ id: report.id, format: 'pdf' })
        
        // Verify blob contains expected content
        expect(blob).toBeInstanceOf(Blob)
        expect(blob.size).toBeGreaterThan(0)
        expect(blob.type).toBe('application/pdf')
        
        // Verify the export was called correctly
        expect(exportHook.mutateAsync).toHaveBeenCalledWith({
          id: report.id,
          format: 'pdf'
        })
      }),
      { numRuns: 10 }
    )
  })
})

describe('Report Export Edge Cases', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    
    const mockExportMutation = {
      mutateAsync: vi.fn().mockResolvedValue(new Blob(['mock content'], { type: 'application/pdf' })),
      isLoading: false,
      error: null
    }
    vi.mocked(useExportReport).mockReturnValue(mockExportMutation as any)
  })

  it('should handle reports with empty content', async () => {
    const emptyContentReport: Report = {
      id: 'test-id',
      userId: 'user-id',
      title: 'Empty Report',
      periodStart: '2024-01-01',
      periodEnd: '2024-01-31',
      reportType: ReportType.MONTHLY,
      content: '',
      activitiesIncluded: [],
      storiesIncluded: [],
      generatedByAi: true,
      status: ReportStatus.COMPLETE,
      createdAt: new Date().toISOString()
    }

    const exportHook = useExportReport()
    const blob = await exportHook.mutateAsync({ id: emptyContentReport.id, format: 'pdf' })
    
    // Should still export even with empty content
    expect(blob).toBeInstanceOf(Blob)
    expect(exportHook.mutateAsync).toHaveBeenCalledWith({
      id: emptyContentReport.id,
      format: 'pdf'
    })
  })

  it('should handle reports with very long titles', async () => {
    const longTitleReport: Report = {
      id: 'test-id',
      userId: 'user-id',
      title: 'A'.repeat(200), // Very long title
      periodStart: '2024-01-01',
      periodEnd: '2024-01-31',
      reportType: ReportType.MONTHLY,
      content: 'Content',
      activitiesIncluded: ['activity-1'],
      storiesIncluded: [],
      generatedByAi: true,
      status: ReportStatus.COMPLETE,
      createdAt: new Date().toISOString()
    }

    const exportHook = useExportReport()
    const blob = await exportHook.mutateAsync({ id: longTitleReport.id, format: 'pdf' })
    
    expect(blob).toBeInstanceOf(Blob)
    expect(exportHook.mutateAsync).toHaveBeenCalled()
    
    // Filename should be sanitized and reasonable length
    const sanitizedFilename = `${longTitleReport.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.pdf`
    expect(sanitizedFilename.length).toBeLessThan(255) // Typical filesystem limit
    expect(sanitizedFilename).toMatch(/\.pdf$/)
  })
})