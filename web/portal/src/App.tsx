import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom"

import { ThemeProvider } from "@/components/theme-provider"
import { AuthProvider } from "@/contexts/auth-context"
import { ProtectedLayout } from "@/components/auth/protected-layout"
import DashboardPage from "@/pages/dashboard"
import PatientsPage from "@/pages/patients"
import PatientWorkspacePage from "@/pages/patient-workspace"
import CaregiversPage from "@/pages/caregivers"
import NotificationsPage from "@/pages/notifications"
import DocumentsPage from "@/pages/documents"
import SubscriptionsPage from "@/pages/subscriptions"
import ReportsPage from "@/pages/reports"
import SettingsPage from "@/pages/settings"
import AuditTrailPage from "@/pages/audit"
import LoginPage from "@/pages/auth/login"

function App() {
  return (
    <ThemeProvider defaultTheme="light" storageKey="digital-nurse-theme">
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<ProtectedLayout />}>
              <Route index element={<DashboardPage />} />
              <Route path="patients" element={<PatientsPage />} />
              <Route path="patients/:slug" element={<PatientWorkspacePage />} />
              <Route path="caregivers" element={<CaregiversPage />} />
              <Route path="notifications" element={<NotificationsPage />} />
              <Route path="documents" element={<DocumentsPage />} />
              <Route path="subscriptions" element={<SubscriptionsPage />} />
              <Route path="reports" element={<ReportsPage />} />
              <Route path="settings" element={<SettingsPage />} />
              <Route path="audit" element={<AuditTrailPage />} />
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </ThemeProvider>
  )
}

export default App
