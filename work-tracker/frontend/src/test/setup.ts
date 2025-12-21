import { expect, afterEach, vi } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

// Extend Vitest's expect with jest-dom matchers
expect.extend(matchers)

// Enhanced IndexedDB mock for testing
const createMockIDBRequest = (result?: any, error?: any) => {
  const request = {
    result,
    error,
    onsuccess: null as any,
    onerror: null as any,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }
  
  // Simulate async behavior
  setTimeout(() => {
    if (error && request.onerror) {
      request.onerror({ target: request } as any)
    } else if (request.onsuccess) {
      request.onsuccess({ target: request } as any)
    }
  }, 0)
  
  return request
}

const createMockObjectStore = () => {
  const store = new Map<string, any>()
  
  return {
    add: vi.fn().mockImplementation((value) => {
      const key = value.id || `key_${Date.now()}`
      store.set(key, value)
      return createMockIDBRequest(key)
    }),
    put: vi.fn().mockImplementation((value) => {
      const key = value.id || `key_${Date.now()}`
      store.set(key, value)
      return createMockIDBRequest(key)
    }),
    get: vi.fn().mockImplementation((key) => {
      const value = store.get(key)
      return createMockIDBRequest(value)
    }),
    getAll: vi.fn().mockImplementation(() => {
      const values = Array.from(store.values())
      return createMockIDBRequest(values)
    }),
    delete: vi.fn().mockImplementation((key) => {
      const existed = store.has(key)
      store.delete(key)
      return createMockIDBRequest(existed)
    }),
    clear: vi.fn().mockImplementation(() => {
      store.clear()
      return createMockIDBRequest(undefined)
    }),
    count: vi.fn().mockImplementation(() => {
      return createMockIDBRequest(store.size)
    }),
    createIndex: vi.fn(),
    index: vi.fn().mockReturnValue({
      get: vi.fn().mockImplementation((key) => {
        // Simple index simulation - find by userId
        const values = Array.from(store.values())
        const found = values.find(v => v.userId === key)
        return createMockIDBRequest(found)
      }),
      getAll: vi.fn().mockImplementation((key) => {
        // Simple index simulation - filter by userId
        const values = Array.from(store.values())
        const filtered = key ? values.filter(v => v.userId === key) : values
        return createMockIDBRequest(filtered)
      })
    }),
    _store: store // For testing access
  }
}

const createMockTransaction = () => {
  const stores = new Map<string, any>()
  
  return {
    objectStore: vi.fn().mockImplementation((name) => {
      if (!stores.has(name)) {
        stores.set(name, createMockObjectStore())
      }
      return stores.get(name)
    }),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
    _stores: stores // For testing access
  }
}

const createMockDatabase = () => {
  const stores = new Map<string, any>()
  
  return {
    createObjectStore: vi.fn().mockImplementation((name) => {
      const store = createMockObjectStore()
      stores.set(name, store)
      return store
    }),
    transaction: vi.fn().mockImplementation((storeNames, mode) => {
      const transaction = createMockTransaction()
      // Pre-populate transaction with existing stores
      storeNames.forEach((name: string) => {
        if (stores.has(name)) {
          transaction._stores.set(name, stores.get(name))
        } else {
          const newStore = createMockObjectStore()
          stores.set(name, newStore)
          transaction._stores.set(name, newStore)
        }
      })
      return transaction
    }),
    objectStoreNames: {
      contains: vi.fn().mockImplementation((name) => stores.has(name))
    },
    close: vi.fn(),
    _stores: stores // For testing access
  }
}

const mockIndexedDB = {
  open: vi.fn().mockImplementation((name, version) => {
    const db = createMockDatabase()
    const request = createMockIDBRequest(db)
    
    // Simulate upgrade needed for new databases
    setTimeout(() => {
      if (request.onupgradeneeded) {
        request.onupgradeneeded({ target: { result: db } } as any)
      }
    }, 0)
    
    return request
  }),
  deleteDatabase: vi.fn().mockImplementation(() => createMockIDBRequest(undefined))
}

// Mock localStorage with proper implementation
const createMockLocalStorage = () => {
  let store: Record<string, string> = {}
  
  return {
    getItem: vi.fn((key: string) => store[key] || null),
    setItem: vi.fn((key: string, value: string) => {
      store[key] = String(value)
    }),
    removeItem: vi.fn((key: string) => {
      delete store[key]
    }),
    clear: vi.fn(() => {
      store = {}
    }),
    get length() {
      return Object.keys(store).length
    },
    key: vi.fn((index: number) => Object.keys(store)[index] || null),
    _store: store // For testing access
  }
}

const mockLocalStorage = createMockLocalStorage()

// Set up global mocks
Object.defineProperty(global, 'indexedDB', {
  value: mockIndexedDB,
  writable: true
})

Object.defineProperty(global, 'localStorage', {
  value: mockLocalStorage,
  writable: true
})

Object.defineProperty(global, 'IDBKeyRange', {
  value: {
    bound: vi.fn(),
    only: vi.fn(),
    lowerBound: vi.fn(),
    upperBound: vi.fn()
  },
  writable: true
})

// Mock navigator.onLine
Object.defineProperty(navigator, 'onLine', {
  writable: true,
  value: true
})

// Mock WebSocket for sync tests
class MockWebSocket {
  static instances: MockWebSocket[] = []
  
  readyState = WebSocket.OPEN
  onopen: ((event: Event) => void) | null = null
  onmessage: ((event: MessageEvent) => void) | null = null
  onclose: ((event: CloseEvent) => void) | null = null
  onerror: ((event: Event) => void) | null = null
  
  sentMessages: string[] = []
  
  constructor(public url: string) {
    MockWebSocket.instances.push(this)
    
    // Simulate connection
    setTimeout(() => {
      if (this.onopen) {
        this.onopen(new Event('open'))
      }
    }, 0)
  }
  
  send(data: string) {
    this.sentMessages.push(data)
  }
  
  close() {
    this.readyState = WebSocket.CLOSED
    if (this.onclose) {
      this.onclose(new CloseEvent('close'))
    }
  }
  
  static reset() {
    MockWebSocket.instances = []
  }
}

Object.defineProperty(global, 'WebSocket', {
  value: MockWebSocket,
  writable: true
})

// Cleanup after each test
afterEach(() => {
  cleanup()
  vi.clearAllMocks()
  mockLocalStorage.clear()
  MockWebSocket.reset()
})