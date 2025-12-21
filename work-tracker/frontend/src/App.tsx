import { Routes, Route } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'

import Layout from '@/components/Layout'
import HomePage from '@/pages/HomePage'
import LoginPage from '@/pages/LoginPage'
import ActivitiesPage from '@/pages/ActivitiesPage'
import StoriesPage from '@/pages/StoriesPage'
import ReportsPage from '@/pages/ReportsPage'
import NotFoundPage from '@/pages/NotFoundPage'

function App() {
  return (
    <>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<Layout />}>
          <Route index element={<HomePage />} />
          <Route path="activities" element={<ActivitiesPage />} />
          <Route path="stories" element={<StoriesPage />} />
          <Route path="reports" element={<ReportsPage />} />
        </Route>
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
      
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