import { useEffect, useState } from 'react'
import { useOffline } from '@/hooks/useOffline'
import { WifiOff, Wifi, RefreshCw, Database } from 'lucide-react'

export function OfflineIndicator() {
  const [state, actions] = useOffline()
  const [showDetails, setShowDetails] = useState(false)

  // Show notification when going offline/online
  useEffect(() => {
    if (!state.isInitialized) return

    const handleOnline = () => {
      // Show brief online notification
      const notification = document.createElement('div')
      notification.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 animate-fade-in'
      notification.textContent = '✓ Back online'
      document.body.appendChild(notification)
      
      setTimeout(() => {
        notification.remove()
      }, 3000)
    }

    window.addEventListener('online', handleOnline)
    return () => window.removeEventListener('online', handleOnline)
  }, [state.isInitialized])

  if (!state.isInitialized) return null

  // Don't show indicator when online and no pending syncs
  if (state.isOnline && state.pendingSyncCount === 0) return null

  return (
    <div className="fixed bottom-4 right-4 z-50">
      {/* Main indicator button */}
      <button
        onClick={() => setShowDetails(!showDetails)}
        className={`
          flex items-center gap-2 px-4 py-2 rounded-lg shadow-lg
          transition-all duration-300 hover:scale-105
          ${state.isOnline 
            ? 'bg-blue-500 text-white' 
            : 'bg-orange-500 text-white animate-pulse'
          }
        `}
        aria-label={state.isOnline ? 'Online status' : 'Offline status'}
      >
        {state.isOnline ? (
          <Wifi className="w-5 h-5" />
        ) : (
          <WifiOff className="w-5 h-5" />
        )}
        
        <span className="font-medium">
          {state.isOnline ? 'Online' : 'Offline'}
        </span>
        
        {state.pendingSyncCount > 0 && (
          <span className="bg-white text-blue-600 px-2 py-0.5 rounded-full text-xs font-bold">
            {state.pendingSyncCount}
          </span>
        )}
      </button>

      {/* Details panel */}
      {showDetails && (
        <div className="absolute bottom-full right-0 mb-2 w-80 bg-white rounded-lg shadow-xl border border-gray-200 overflow-hidden">
          {/* Header */}
          <div className={`px-4 py-3 ${state.isOnline ? 'bg-blue-50' : 'bg-orange-50'}`}>
            <div className="flex items-center justify-between">
              <h3 className="font-semibold text-gray-900">
                {state.isOnline ? 'Online Status' : 'Offline Mode'}
              </h3>
              <button
                onClick={() => setShowDetails(false)}
                className="text-gray-500 hover:text-gray-700"
                aria-label="Close"
              >
                ×
              </button>
            </div>
          </div>

          {/* Content */}
          <div className="p-4 space-y-4">
            {/* Connection status */}
            <div className="flex items-start gap-3">
              <div className={`p-2 rounded-lg ${state.isOnline ? 'bg-green-100' : 'bg-orange-100'}`}>
                {state.isOnline ? (
                  <Wifi className="w-5 h-5 text-green-600" />
                ) : (
                  <WifiOff className="w-5 h-5 text-orange-600" />
                )}
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">
                  {state.isOnline ? 'Connected' : 'No Connection'}
                </p>
                <p className="text-xs text-gray-500 mt-0.5">
                  {state.isOnline 
                    ? 'All features available' 
                    : 'Limited functionality - changes will sync when online'
                  }
                </p>
              </div>
            </div>

            {/* Pending syncs */}
            {state.pendingSyncCount > 0 && (
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-blue-100">
                  <RefreshCw className="w-5 h-5 text-blue-600" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">
                    Pending Changes
                  </p>
                  <p className="text-xs text-gray-500 mt-0.5">
                    {state.pendingSyncCount} {state.pendingSyncCount === 1 ? 'change' : 'changes'} waiting to sync
                  </p>
                </div>
              </div>
            )}

            {/* Cache info */}
            {state.cacheInfo && (
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-purple-100">
                  <Database className="w-5 h-5 text-purple-600" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">
                    Cached Data
                  </p>
                  <div className="text-xs text-gray-500 mt-0.5 space-y-0.5">
                    <p>{state.cacheInfo.activitiesCount} activities</p>
                    <p>{state.cacheInfo.storiesCount} stories</p>
                    <p>{state.cacheInfo.reportsCount} reports</p>
                  </div>
                </div>
              </div>
            )}

            {/* Last sync time */}
            {state.lastSync > 0 && (
              <div className="text-xs text-gray-500 pt-2 border-t border-gray-200">
                Last synced: {new Date(state.lastSync).toLocaleString()}
              </div>
            )}

            {/* Actions */}
            <div className="flex gap-2 pt-2">
              {state.isOnline && state.pendingSyncCount > 0 && (
                <button
                  onClick={async () => {
                    await actions.syncData()
                    await actions.getCacheInfo()
                  }}
                  disabled={state.isSyncing}
                  className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium transition-colors"
                >
                  <RefreshCw className={`w-4 h-4 ${state.isSyncing ? 'animate-spin' : ''}`} />
                  {state.isSyncing ? 'Syncing...' : 'Sync Now'}
                </button>
              )}
              
              <button
                onClick={async () => {
                  if (confirm('Clear all cached data? This cannot be undone.')) {
                    await actions.clearCache()
                    await actions.getCacheInfo()
                  }
                }}
                className="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm font-medium transition-colors"
              >
                Clear Cache
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}