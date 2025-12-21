import { useState } from 'react'
import { SyncConflict, ConflictResolution } from '@/services/syncService'
import { Activity, Story, Report } from '@/types'
import { AlertTriangle, Clock, User, Smartphone } from 'lucide-react'

interface ConflictResolutionModalProps {
  conflict: SyncConflict
  isOpen: boolean
  onResolve: (resolution: ConflictResolution) => void
  onClose: () => void
}

export function ConflictResolutionModal({
  conflict,
  isOpen,
  onResolve,
  onClose
}: ConflictResolutionModalProps) {
  const [selectedResolution, setSelectedResolution] = useState<'local' | 'remote' | 'merge'>('local')
  const [mergedData, setMergedData] = useState<any>(null)

  if (!isOpen) return null

  const handleResolve = () => {
    const resolution: ConflictResolution = {
      entityId: conflict.entityId,
      entityType: conflict.entityType,
      resolution: selectedResolution,
      mergedData: selectedResolution === 'merge' ? mergedData : undefined
    }

    onResolve(resolution)
    onClose()
  }

  const formatTimestamp = (timestamp: number) => {
    return new Date(timestamp).toLocaleString()
  }

  const getConflictTitle = () => {
    switch (conflict.conflictType) {
      case 'concurrent_edit':
        return 'Concurrent Edit Conflict'
      case 'delete_edit':
        return 'Delete-Edit Conflict'
      case 'version_mismatch':
        return 'Version Mismatch'
      default:
        return 'Data Conflict'
    }
  }

  const getConflictDescription = () => {
    switch (conflict.conflictType) {
      case 'concurrent_edit':
        return 'This item was edited on multiple devices at the same time.'
      case 'delete_edit':
        return 'This item was deleted on one device but edited on another.'
      case 'version_mismatch':
        return 'The item versions are out of sync between devices.'
      default:
        return 'There is a conflict between different versions of this item.'
    }
  }

  const renderDataComparison = () => {
    const localData = conflict.localData
    const remoteData = conflict.remoteData

    if (conflict.entityType === 'activity') {
      return renderActivityComparison(localData, remoteData)
    } else if (conflict.entityType === 'story') {
      return renderStoryComparison(localData, remoteData)
    } else if (conflict.entityType === 'report') {
      return renderReportComparison(localData, remoteData)
    }

    return null
  }

  const renderActivityComparison = (local: Activity | null, remote: Activity | null) => (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Local Version */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-blue-600">
          <Smartphone className="w-5 h-5" />
          <h4 className="font-semibold">This Device</h4>
          <span className="text-sm text-gray-500">
            {formatTimestamp(conflict.localTimestamp)}
          </span>
        </div>
        
        {local ? (
          <div className="bg-blue-50 p-4 rounded-lg space-y-2">
            <div>
              <label className="text-sm font-medium text-gray-700">Title:</label>
              <p className="text-gray-900">{local.title}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Description:</label>
              <p className="text-gray-900">{local.description || 'No description'}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Category:</label>
              <p className="text-gray-900">{local.category}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Impact Level:</label>
              <p className="text-gray-900">{local.impactLevel}/5</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Tags:</label>
              <p className="text-gray-900">{local.tags.join(', ') || 'No tags'}</p>
            </div>
          </div>
        ) : (
          <div className="bg-red-50 p-4 rounded-lg text-red-700">
            Item was deleted on this device
          </div>
        )}
      </div>

      {/* Remote Version */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-green-600">
          <User className="w-5 h-5" />
          <h4 className="font-semibold">Other Device</h4>
          <span className="text-sm text-gray-500">
            {formatTimestamp(conflict.remoteTimestamp)}
          </span>
        </div>
        
        {remote ? (
          <div className="bg-green-50 p-4 rounded-lg space-y-2">
            <div>
              <label className="text-sm font-medium text-gray-700">Title:</label>
              <p className="text-gray-900">{remote.title}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Description:</label>
              <p className="text-gray-900">{remote.description || 'No description'}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Category:</label>
              <p className="text-gray-900">{remote.category}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Impact Level:</label>
              <p className="text-gray-900">{remote.impactLevel}/5</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Tags:</label>
              <p className="text-gray-900">{remote.tags.join(', ') || 'No tags'}</p>
            </div>
          </div>
        ) : (
          <div className="bg-red-50 p-4 rounded-lg text-red-700">
            Item was deleted on other device
          </div>
        )}
      </div>
    </div>
  )

  const renderStoryComparison = (local: Story | null, remote: Story | null) => (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Local Version */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-blue-600">
          <Smartphone className="w-5 h-5" />
          <h4 className="font-semibold">This Device</h4>
          <span className="text-sm text-gray-500">
            {formatTimestamp(conflict.localTimestamp)}
          </span>
        </div>
        
        {local ? (
          <div className="bg-blue-50 p-4 rounded-lg space-y-3">
            <div>
              <label className="text-sm font-medium text-gray-700">Title:</label>
              <p className="text-gray-900">{local.title}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Situation:</label>
              <p className="text-gray-900 text-sm">{local.situation.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Task:</label>
              <p className="text-gray-900 text-sm">{local.task.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Action:</label>
              <p className="text-gray-900 text-sm">{local.action.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Result:</label>
              <p className="text-gray-900 text-sm">{local.result.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Status:</label>
              <p className="text-gray-900">{local.status}</p>
            </div>
          </div>
        ) : (
          <div className="bg-red-50 p-4 rounded-lg text-red-700">
            Story was deleted on this device
          </div>
        )}
      </div>

      {/* Remote Version */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-green-600">
          <User className="w-5 h-5" />
          <h4 className="font-semibold">Other Device</h4>
          <span className="text-sm text-gray-500">
            {formatTimestamp(conflict.remoteTimestamp)}
          </span>
        </div>
        
        {remote ? (
          <div className="bg-green-50 p-4 rounded-lg space-y-3">
            <div>
              <label className="text-sm font-medium text-gray-700">Title:</label>
              <p className="text-gray-900">{remote.title}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Situation:</label>
              <p className="text-gray-900 text-sm">{remote.situation.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Task:</label>
              <p className="text-gray-900 text-sm">{remote.task.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Action:</label>
              <p className="text-gray-900 text-sm">{remote.action.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Result:</label>
              <p className="text-gray-900 text-sm">{remote.result.substring(0, 100)}...</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Status:</label>
              <p className="text-gray-900">{remote.status}</p>
            </div>
          </div>
        ) : (
          <div className="bg-red-50 p-4 rounded-lg text-red-700">
            Story was deleted on other device
          </div>
        )}
      </div>
    </div>
  )

  const renderReportComparison = (local: Report | null, remote: Report | null) => (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Local Version */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-blue-600">
          <Smartphone className="w-5 h-5" />
          <h4 className="font-semibold">This Device</h4>
        </div>
        
        {local ? (
          <div className="bg-blue-50 p-4 rounded-lg space-y-2">
            <div>
              <label className="text-sm font-medium text-gray-700">Title:</label>
              <p className="text-gray-900">{local.title}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Type:</label>
              <p className="text-gray-900">{local.reportType}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Period:</label>
              <p className="text-gray-900">{local.periodStart} to {local.periodEnd}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Status:</label>
              <p className="text-gray-900">{local.status}</p>
            </div>
          </div>
        ) : (
          <div className="bg-red-50 p-4 rounded-lg text-red-700">
            Report was deleted on this device
          </div>
        )}
      </div>

      {/* Remote Version */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-green-600">
          <User className="w-5 h-5" />
          <h4 className="font-semibold">Other Device</h4>
        </div>
        
        {remote ? (
          <div className="bg-green-50 p-4 rounded-lg space-y-2">
            <div>
              <label className="text-sm font-medium text-gray-700">Title:</label>
              <p className="text-gray-900">{remote.title}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Type:</label>
              <p className="text-gray-900">{remote.reportType}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Period:</label>
              <p className="text-gray-900">{remote.periodStart} to {remote.periodEnd}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Status:</label>
              <p className="text-gray-900">{remote.status}</p>
            </div>
          </div>
        ) : (
          <div className="bg-red-50 p-4 rounded-lg text-red-700">
            Report was deleted on other device
          </div>
        )}
      </div>
    </div>
  )

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-6 h-6 text-orange-500" />
            <div>
              <h2 className="text-xl font-semibold text-gray-900">{getConflictTitle()}</h2>
              <p className="text-sm text-gray-600">{getConflictDescription()}</p>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="px-6 py-4 space-y-6">
          {/* Data Comparison */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Compare Versions</h3>
            {renderDataComparison()}
          </div>

          {/* Resolution Options */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Choose Resolution</h3>
            <div className="space-y-3">
              <label className="flex items-start gap-3 p-3 border rounded-lg cursor-pointer hover:bg-gray-50">
                <input
                  type="radio"
                  name="resolution"
                  value="local"
                  checked={selectedResolution === 'local'}
                  onChange={(e) => setSelectedResolution(e.target.value as any)}
                  className="mt-1"
                />
                <div>
                  <div className="font-medium text-gray-900">Keep This Device Version</div>
                  <div className="text-sm text-gray-600">
                    Use the version from this device and discard changes from other devices
                  </div>
                </div>
              </label>

              <label className="flex items-start gap-3 p-3 border rounded-lg cursor-pointer hover:bg-gray-50">
                <input
                  type="radio"
                  name="resolution"
                  value="remote"
                  checked={selectedResolution === 'remote'}
                  onChange={(e) => setSelectedResolution(e.target.value as any)}
                  className="mt-1"
                />
                <div>
                  <div className="font-medium text-gray-900">Keep Other Device Version</div>
                  <div className="text-sm text-gray-600">
                    Use the version from the other device and discard local changes
                  </div>
                </div>
              </label>

              <label className="flex items-start gap-3 p-3 border rounded-lg cursor-pointer hover:bg-gray-50">
                <input
                  type="radio"
                  name="resolution"
                  value="merge"
                  checked={selectedResolution === 'merge'}
                  onChange={(e) => setSelectedResolution(e.target.value as any)}
                  className="mt-1"
                />
                <div>
                  <div className="font-medium text-gray-900">Merge Automatically</div>
                  <div className="text-sm text-gray-600">
                    Automatically combine changes from both versions (uses most recent timestamp)
                  </div>
                </div>
              </label>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-3">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleResolve}
            className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
          >
            Resolve Conflict
          </button>
        </div>
      </div>
    </div>
  )
}