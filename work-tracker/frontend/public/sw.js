// Service Worker for Work Tracker offline functionality
const CACHE_NAME = 'work-tracker-v1'
const STATIC_CACHE_NAME = 'work-tracker-static-v1'
const DATA_CACHE_NAME = 'work-tracker-data-v1'

// Static assets to cache
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/offline.html'
]

// API endpoints to cache
const API_ENDPOINTS = [
  '/api/v1/activities',
  '/api/v1/stories',
  '/api/v1/reports'
]

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('Service Worker installing...')
  
  event.waitUntil(
    Promise.all([
      caches.open(STATIC_CACHE_NAME).then((cache) => {
        return cache.addAll(STATIC_ASSETS)
      }),
      caches.open(DATA_CACHE_NAME) // Initialize data cache
    ])
  )
  
  // Skip waiting to activate immediately
  self.skipWaiting()
})

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker activating...')
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== STATIC_CACHE_NAME && 
              cacheName !== DATA_CACHE_NAME &&
              cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName)
            return caches.delete(cacheName)
          }
        })
      )
    })
  )
  
  // Take control of all clients immediately
  self.clients.claim()
})

// Fetch event - implement caching strategies
self.addEventListener('fetch', (event) => {
  const { request } = event
  const url = new URL(request.url)
  
  // Handle API requests
  if (url.pathname.startsWith('/api/v1/')) {
    event.respondWith(handleApiRequest(request))
    return
  }
  
  // Handle static assets
  if (request.destination === 'document' || 
      request.destination === 'script' || 
      request.destination === 'style' ||
      request.destination === 'image') {
    event.respondWith(handleStaticRequest(request))
    return
  }
  
  // Default: network first
  event.respondWith(fetch(request))
})

// Handle API requests with cache-first strategy for GET requests
async function handleApiRequest(request) {
  const cache = await caches.open(DATA_CACHE_NAME)
  
  // For GET requests, try cache first
  if (request.method === 'GET') {
    try {
      // Try network first for fresh data
      const networkResponse = await fetch(request)
      
      if (networkResponse.ok) {
        // Cache successful responses
        cache.put(request, networkResponse.clone())
        return networkResponse
      }
      
      // If network fails, try cache
      const cachedResponse = await cache.match(request)
      if (cachedResponse) {
        console.log('Serving from cache:', request.url)
        return cachedResponse
      }
      
      // If no cache, return network error
      return networkResponse
    } catch (error) {
      console.log('Network failed, trying cache:', request.url)
      
      // Network failed, try cache
      const cachedResponse = await cache.match(request)
      if (cachedResponse) {
        return cachedResponse
      }
      
      // Return offline page for navigation requests
      if (request.destination === 'document') {
        return caches.match('/offline.html')
      }
      
      throw error
    }
  }
  
  // For non-GET requests, try network only
  // Store failed requests for later sync
  try {
    const response = await fetch(request)
    return response
  } catch (error) {
    // Store failed write operations for background sync
    if (request.method === 'POST' || request.method === 'PUT' || request.method === 'DELETE') {
      await storeFailedRequest(request)
    }
    throw error
  }
}

// Handle static assets with cache-first strategy
async function handleStaticRequest(request) {
  const cache = await caches.open(STATIC_CACHE_NAME)
  
  // Try cache first
  const cachedResponse = await cache.match(request)
  if (cachedResponse) {
    return cachedResponse
  }
  
  // If not in cache, try network and cache
  try {
    const networkResponse = await fetch(request)
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone())
    }
    return networkResponse
  } catch (error) {
    // For navigation requests, return offline page
    if (request.destination === 'document') {
      return caches.match('/offline.html')
    }
    throw error
  }
}

// Store failed requests for background sync
async function storeFailedRequest(request) {
  try {
    const requestData = {
      url: request.url,
      method: request.method,
      headers: Object.fromEntries(request.headers.entries()),
      body: request.method !== 'GET' ? await request.text() : null,
      timestamp: Date.now()
    }
    
    // Store in IndexedDB for background sync
    const db = await openDB()
    const transaction = db.transaction(['failed_requests'], 'readwrite')
    const store = transaction.objectStore('failed_requests')
    await store.add(requestData)
    
    console.log('Stored failed request for sync:', request.url)
  } catch (error) {
    console.error('Failed to store request for sync:', error)
  }
}

// Open IndexedDB for storing failed requests
function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('work-tracker-sync', 1)
    
    request.onerror = () => reject(request.error)
    request.onsuccess = () => resolve(request.result)
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result
      
      // Create object store for failed requests
      if (!db.objectStoreNames.contains('failed_requests')) {
        const store = db.createObjectStore('failed_requests', { 
          keyPath: 'id', 
          autoIncrement: true 
        })
        store.createIndex('timestamp', 'timestamp', { unique: false })
      }
    }
  })
}

// Background sync event
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(syncFailedRequests())
  }
})

// Sync failed requests when back online
async function syncFailedRequests() {
  try {
    const db = await openDB()
    const transaction = db.transaction(['failed_requests'], 'readwrite')
    const store = transaction.objectStore('failed_requests')
    const requests = await store.getAll()
    
    for (const requestData of requests) {
      try {
        const response = await fetch(requestData.url, {
          method: requestData.method,
          headers: requestData.headers,
          body: requestData.body
        })
        
        if (response.ok) {
          // Remove successfully synced request
          await store.delete(requestData.id)
          console.log('Synced failed request:', requestData.url)
        }
      } catch (error) {
        console.log('Failed to sync request:', requestData.url, error)
      }
    }
  } catch (error) {
    console.error('Background sync failed:', error)
  }
}

// Message event for communication with main thread
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting()
  }
  
  if (event.data && event.data.type === 'GET_CACHE_STATUS') {
    getCacheStatus().then((status) => {
      event.ports[0].postMessage(status)
    })
  }
})

// Get cache status for UI
async function getCacheStatus() {
  const dataCache = await caches.open(DATA_CACHE_NAME)
  const staticCache = await caches.open(STATIC_CACHE_NAME)
  
  const dataKeys = await dataCache.keys()
  const staticKeys = await staticCache.keys()
  
  return {
    dataCacheSize: dataKeys.length,
    staticCacheSize: staticKeys.length,
    isOnline: navigator.onLine
  }
}