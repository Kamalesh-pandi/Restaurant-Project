import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import StaffLogin from './pages/StaffLogin';
import StaffDashboard from './pages/StaffDashboard';

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public: Staff Login */}
          <Route path="/login" element={<StaffLogin />} />

          {/* Protected: Staff Dashboard (role-based workspace rendered inside) */}
          <Route path="/dashboard" element={<StaffDashboard />} />

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
