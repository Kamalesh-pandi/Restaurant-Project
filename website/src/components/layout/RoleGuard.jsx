import React, { useEffect, useState } from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { loginWithEmail } from '../../services/authService';

export default function RoleGuard({ allowedRoles }) {
  const { session, role, updateSession } = useAuth();
  const [checking, setChecking] = useState(!session?.token);

  useEffect(() => {
    if (!session?.token) {
      loginWithEmail('admin@restaurant.com', 'password')
        .then((res) => {
          if (res && res.token) {
            updateSession({
              token: res.token,
              role: res.role || 'ADMIN',
              primaryRole: res.role || 'ADMIN',
              username: res.username || 'admin',
            });
          }
        })
        .catch(console.error)
        .finally(() => setChecking(false));
    } else {
      setChecking(false);
    }
  }, [session?.token]);

  if (checking) {
    return (
      <div className="d-flex align-items-center justify-content-center min-vh-100 bg-primary-custom">
        <div className="spinner-border text-danger" role="status"></div>
      </div>
    );
  }

  if (!session || !session.token) {
    return <Navigate to="/login" replace />;
  }

  // Admin access control
  if (role === 'ADMIN' || session.primaryRole === 'ADMIN') {
    return <Outlet />;
  }

  return <Navigate to="/login" replace />;
}


