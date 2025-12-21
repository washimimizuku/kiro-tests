import { useState } from 'react'
import { useSync, useConflicts } from '@/hooks/useSync'
import { ConflictResolutionModal } from '@/components/ConflictResolutionModal'
import { SyncConflict } from '@/services/syncService'
import { RefreshCw, Wifi, WifiOff, AlertTriangle, Clock, CheckCircle } from 'lucide-react'

export function SyncStatusIndicator() {
  const [syncState, syncActions] = useSync()
  const conflicts = useConflicts()
  const [showDetails, setShowDetails] = useState(false)
  const [selectedConflict, setSelectedConflict] = useState<SyncConflict | null>(null)

  const { status } = syncState

  // Don't show if not initialized
  if (!syncState.isInitialized) return null

  const getStatusIcon = () => {
    if (conflicts.length > 0) {
      return <AlertTriangle className="w-5 h-5 text-orange-500" />
    }
    if (status.syncInProgress) {
      return <RefreshCw className="w-5 h-5 text-blue-500 animate-spin" />
    }
    if (status.isConnected) {
      return <CheckCircle className="w-5 h-5 text-green-500" />
    }
    return <WifiOff className="w-5 h-5 text-red-500" />
  }

  const getStatusText = () => {
    if (conflicts.length > 0) {
      return `${conflicts.length} conflict${conflicts.length === 1 ? '' : 's'}`
    }
    if (status.syncInProgress) {
      return 'Syncing...'
    }
    if (status.isConnected) {
      return 'Synced'
    }
    return 'Offline'
  }

  const getStatusColor = () => {
    if (conflicts.length > 0) return 'bg-orange-500'
    if (status.syncInProgress) return 'bg-blue-500'
    if (status.isConnected) return 'bg-green-500'
    return 'bg-red-500'
  }

  return (
    <>
      <div className="relative">
        {/* Main status button */}
        <button
          onClick={() => setShowDetails(!showDetails)}
          className={`
            flex items-center gap-2 px-3 py-2 rounded-lg text-white text-sm font-medium
            transition-all duration-300 hover:scale-105 ${getStatusColor()}
          `}
          aria-label="Sync status"
        >
          {getStatusIcon()}
          <span>{getStatusText()}</span>
        </button>

        {/* Details dropdown */}
        {showDetails && (
          <div className="absolute top-full right-0 mt-2 w-80 bg-white rounded-lg shadow-xl border border-gray-200 z-50">
            {/* Header */}
            <div className="px-4 py-3 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-gray-900">Sync Status</h3>
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
              {/* Connection Status */}
              <div className="flex items-start gap-3">
                <div className={`p-2 rounded-lg ${status.isConnected ? 'bg-green-100' : 'bg-red-100'}`}>
                  {status.isConnected ? (
                    <Wifi className="w-5 h-5 text-green-600" />
                  ) : (
                    <WifiOff className="w-5 h-5 text-red-600" />
                  )}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">
                    {status.isConnected ? 'Connected' : 'Disconnected'}
                  </p>
                  <p className="text-xs text-gray-500">
                    {status.isConnected 
                      ? 'Real-time sync active' 
                      : 'Changes will sync when connection is restored'
                    }
                  </p>
                </div>
              </div>

              {/* Sync Progress */}
              {status.syncInProgress && (
                <div className="flex items-start gap-3">
                  <div className="p-2 rounded-lg bg-blue-100">
                    <RefreshCw className="w-5 h-5 text-blue-600 animate-spin" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium text-gray-900">Syncing</p>
                    <p className="text-xs text-gray-500">Updating data across devices</p>
                  </div>
                </div>
              )}

              {/* Conflicts */}
              {conflicts.length > 0 && (
                <div className="space-y-3">
                  <div className="flex items-start gap-3">
                    <div className="p-2 rounded-lg bg-orange-100">
                      <AlertTriangle className="w-5 h-5 text-orange-600" />
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-gray-900">
                        {conflicts.length} Conflict{conflicts.length === 1 ? '' : 's'}
                      </p>
                      <p className="text-xs text-gray-500">
                        Items edited on multiple devices need resolution
                      </p>
                    </div>
                  </div>

                  {/* Conflict List */}
                  <div className="space-y-2 max-h-40 overflow-y-auto">
                    {conflicts.map((conflict, index) => (
                      <div
                        key={`${conflict.entityType}-${conflict.entityId}`}
                        className="flex items-center justify-between p-2 bg-orange-50 rounded border border-orange-200"
                      >
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {conflict.entityType === 'activity' && conflict.localData?.title}
                            {conflict.entityType === 'story' && conflict.localData?.title}
                            {conflict.entityType === 'report' && conflict.localData?.title}
                            {!conflict.localData && `Deleted ${conflict.entityType}`}
                          </p>
                          <p className="text-xs text-gray-500 capitalize">
                            {conflict.conflictType.replace('_', ' ')}
                          </p>
                        </div>
                        <button
                          onClick={() => setSelectedConflict(conflict)}
                          className="ml-2 px-2 py-1 text-xs bg-orange-500 text-white rounded hover:bg-orange-600 transition-colors"
                        >
                          Resolve
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Last Sync */}
              {status.lastSync > 0 && (
                <div className="flex items-start gap-3">
                  <div className="p-2 rounded-lg bg-gray-100">
                    <Clock className="w-5 h-5 text-gray-600" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium text-gray-900">Last Sync</p>
                    <p className="text-xs text-gray-500">
                      {new Date(status.lastSync).toLocaleString()}
                    </p>
                  </div>
                </div>
              )}

              {/* Device Info */}
              <div className="pt-2 border-t border-gray-200">
                <p className="text-xs text-gray-500">
                  Device ID: {status.deviceId.substring(0, 12)}...
                </p>
              </div>

              {/* Actions */}
              <div className="flex gap-2 pt-2">
                {status.isConnected && !status.syncInProgress && (
                  <button
                    onClick={async () => {
                      await syncActions.requestSync()
                      setShowDetails(false)
                    }}
                    className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 text-sm font-medium transition-colors"
                  >
                    <RefreshCw className="w-4 h-4" />
                    Sync Now
                  </button>
                )}
                
                {!status.isConnected && (
                  <button
                    onClick={async () => {
                      await syncActions.initialize()
                      setShowDetails(false)
                    }}
                    className="flex-1 px-3 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 text-sm font-medium transition-colors"
                  >
                    Reconnect
                  </button>
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Conflict Resolution Modal */}
      {selectedConflict && (
        <ConflictResolutionModal
          conflict={selectedConflict}
          isOpen={!!selectedConflict}
          onResolve={async (resolution) => {
            await syncActions.resolveConflict(resolution)
            setSelectedConflict(null)
          }}
          onClose={() => setSelectedConflict(null)}
        />
      )}
    </>
  )
}