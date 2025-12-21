import { useState } from 'react'
import { Report } from '@/types'

interface ReportShareModalProps {
  report: Report
  isOpen: boolean
  onClose: () => void
}

interface ShareOptions {
  method: 'link' | 'email' | 'social'
  includePreview: boolean
  expiresIn: '1day' | '1week' | '1month' | 'never'
  allowComments: boolean
}

export default function ReportShareModal({ report, isOpen, onClose }: ReportShareModalProps) {
  const [shareOptions, setShareOptions] = useState<ShareOptions>({
    method: 'link',
    includePreview: true,
    expiresIn: '1week',
    allowComments: false
  })
  
  const [shareUrl, setShareUrl] = useState('')
  const [isGeneratingLink, setIsGeneratingLink] = useState(false)
  const [emailRecipients, setEmailRecipients] = useState('')
  const [emailMessage, setEmailMessage] = useState('')

  const generateShareLink = async () => {
    setIsGeneratingLink(true)
    try {
      // In a real implementation, this would call an API to generate a secure share link
      // For now, we'll simulate it
      await new Promise(resolve => setTimeout(resolve, 1000))
      const mockShareId = Math.random().toString(36).substring(7)
      const baseUrl = window.location.origin
      setShareUrl(`${baseUrl}/shared-reports/${mockShareId}`)
    } catch (error) {
      console.error('Failed to generate share link:', error)
    } finally {
      setIsGeneratingLink(false)
    }
  }

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text)
      // TODO: Show success toast
    } catch (error) {
      console.error('Failed to copy to clipboard:', error)
    }
  }

  const handleNativeShare = async () => {
    const shareData = {
      title: report.title,
      text: `Check out my ${report.reportType} report: ${report.title}`,
      url: shareUrl || window.location.href
    }

    if (navigator.share && navigator.canShare(shareData)) {
      try {
        await navigator.share(shareData)
        onClose()
      } catch (error) {
        console.error('Share failed:', error)
      }
    }
  }

  const handleEmailShare = () => {
    const subject = encodeURIComponent(`Report: ${report.title}`)
    const body = encodeURIComponent(`
${emailMessage}

Report: ${report.title}
Period: ${new Date(report.periodStart).toLocaleDateString()} - ${new Date(report.periodEnd).toLocaleDateString()}
Type: ${report.reportType}

${shareUrl ? `View report: ${shareUrl}` : 'Report link will be generated when shared.'}
    `.trim())
    
    const mailtoUrl = `mailto:${emailRecipients}?subject=${subject}&body=${body}`
    window.open(mailtoUrl)
  }

  const handleSocialShare = (platform: 'twitter' | 'linkedin' | 'facebook') => {
    const text = `Check out my ${report.reportType} report: ${report.title}`
    const url = shareUrl || window.location.href
    
    let shareUrl = ''
    switch (platform) {
      case 'twitter':
        shareUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(url)}`
        break
      case 'linkedin':
        shareUrl = `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url)}`
        break
      case 'facebook':
        shareUrl = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`
        break
    }
    
    window.open(shareUrl, '_blank', 'width=600,height=400')
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        {/* Background overlay */}
        <div 
          className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          onClick={onClose}
        ></div>

        {/* Modal */}
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div className="sm:flex sm:items-start">
              <div className="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
                  Share Report: {report.title}
                </h3>
                
                <div className="space-y-6">
                  {/* Share Method Selection */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Share Method
                    </label>
                    <div className="grid grid-cols-3 gap-3">
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="method"
                          value="link"
                          checked={shareOptions.method === 'link'}
                          onChange={(e) => setShareOptions(prev => ({ ...prev, method: e.target.value as 'link' | 'email' | 'social' }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Share Link</span>
                      </label>
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="method"
                          value="email"
                          checked={shareOptions.method === 'email'}
                          onChange={(e) => setShareOptions(prev => ({ ...prev, method: e.target.value as 'link' | 'email' | 'social' }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Email</span>
                      </label>
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="method"
                          value="social"
                          checked={shareOptions.method === 'social'}
                          onChange={(e) => setShareOptions(prev => ({ ...prev, method: e.target.value as 'link' | 'email' | 'social' }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Social Media</span>
                      </label>
                    </div>
                  </div>

                  {/* Share Options */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Share Settings
                    </label>
                    <div className="space-y-2">
                      <label className="flex items-center">
                        <input
                          type="checkbox"
                          checked={shareOptions.includePreview}
                          onChange={(e) => setShareOptions(prev => ({ ...prev, includePreview: e.target.checked }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Include report preview</span>
                      </label>
                      <label className="flex items-center">
                        <input
                          type="checkbox"
                          checked={shareOptions.allowComments}
                          onChange={(e) => setShareOptions(prev => ({ ...prev, allowComments: e.target.checked }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Allow comments on shared report</span>
                      </label>
                    </div>
                  </div>

                  {/* Link Expiration */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Link Expires
                    </label>
                    <select
                      value={shareOptions.expiresIn}
                      onChange={(e) => setShareOptions(prev => ({ ...prev, expiresIn: e.target.value as '1day' | '1week' | '1month' | 'never' }))}
                      className="input"
                    >
                      <option value="1day">1 Day</option>
                      <option value="1week">1 Week</option>
                      <option value="1month">1 Month</option>
                      <option value="never">Never</option>
                    </select>
                  </div>

                  {/* Share Link Method */}
                  {shareOptions.method === 'link' && (
                    <div className="space-y-3">
                      {!shareUrl ? (
                        <button
                          onClick={generateShareLink}
                          disabled={isGeneratingLink}
                          className="btn btn-primary"
                        >
                          {isGeneratingLink ? 'Generating Link...' : 'Generate Share Link'}
                        </button>
                      ) : (
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Share URL
                          </label>
                          <div className="flex">
                            <input
                              type="text"
                              value={shareUrl}
                              readOnly
                              className="input flex-1 mr-2"
                            />
                            <button
                              onClick={() => copyToClipboard(shareUrl)}
                              className="btn btn-secondary"
                            >
                              Copy
                            </button>
                          </div>
                          
                          {navigator.share && (
                            <button
                              onClick={handleNativeShare}
                              className="btn btn-secondary mt-2"
                            >
                              Share via Device
                            </button>
                          )}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Email Method */}
                  {shareOptions.method === 'email' && (
                    <div className="space-y-3">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Recipients (comma-separated)
                        </label>
                        <input
                          type="text"
                          value={emailRecipients}
                          onChange={(e) => setEmailRecipients(e.target.value)}
                          placeholder="email1@example.com, email2@example.com"
                          className="input"
                        />
                      </div>
                      
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Message (optional)
                        </label>
                        <textarea
                          value={emailMessage}
                          onChange={(e) => setEmailMessage(e.target.value)}
                          placeholder="Add a personal message..."
                          rows={3}
                          className="input"
                        />
                      </div>
                      
                      <button
                        onClick={handleEmailShare}
                        disabled={!emailRecipients.trim()}
                        className="btn btn-primary"
                      >
                        Open Email Client
                      </button>
                    </div>
                  )}

                  {/* Social Media Method */}
                  {shareOptions.method === 'social' && (
                    <div className="space-y-3">
                      <p className="text-sm text-gray-600">
                        Choose a platform to share your report:
                      </p>
                      
                      <div className="grid grid-cols-3 gap-3">
                        <button
                          onClick={() => handleSocialShare('twitter')}
                          className="btn btn-secondary flex items-center justify-center"
                        >
                          <svg className="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
                          </svg>
                          Twitter
                        </button>
                        
                        <button
                          onClick={() => handleSocialShare('linkedin')}
                          className="btn btn-secondary flex items-center justify-center"
                        >
                          <svg className="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                          </svg>
                          LinkedIn
                        </button>
                        
                        <button
                          onClick={() => handleSocialShare('facebook')}
                          className="btn btn-secondary flex items-center justify-center"
                        >
                          <svg className="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                          </svg>
                          Facebook
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
          
          <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              onClick={onClose}
              className="btn btn-secondary sm:w-auto"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}