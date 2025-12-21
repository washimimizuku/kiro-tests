import { Routes, Route } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'

import Layout from '@/components/Layout'
import ProtectedRoute from '@/components/ProtectedRoute'
import OfflineIndicator from '@/components/OfflineIndicator'
import HomePage from '@/pages/HomePage'
import LoginPage from '@/pages/LoginPage'
import RegisterPage from '@/pages/RegisterPage'
import ActivitiesPage from '@/pages/ActivitiesPage'
import StoriesPage from '@/pages/StoriesPage'
import ReportsPage from '@/pages/ReportsPage'
import NotFoundPage from '@/pages/NotFoundPage'

function App() {
  return (
    <>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/" element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }>
          <Route index element={<HomePage />} />
          <Route path="activities" element={<ActivitiesPage />} />
          <Route path="stories" element={<StoriesPage />} />
          <Route path="reports" element={<ReportsPage />} />
        </Route>
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
      
      <OfflineIndicator />
      
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 4000,
          style: {
            background: '#363636',
            color: '#fff',
          },
        }}
      />
    </>
  )
}

export default App