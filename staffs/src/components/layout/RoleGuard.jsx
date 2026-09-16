import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

export default function RoleGuard({ allowedRoles }) {
  const { session, role } = useAuth();

  if (!session || !session.token) {
    return <Navigate to="/login" replace />;
  }

  // Check allowed roles if specified, otherwise default to authenticated
  if (allowedRoles && Array.isArray(allowedRoles) && allowedRoles.length > 0) {
    const currentRole = role || session.primaryRole || session.role;
    if (allowedRoles.includes(currentRole) || currentRole === 'ADMIN' || currentRole === 'MANAGER') {
      return <Outlet />;
    }
    return <Navigate to="/dashboard" replace />;
  }

  return <Outlet />;
}

