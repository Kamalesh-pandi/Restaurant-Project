import React, { createContext, useContext, useState, useEffect } from 'react';
import { getStoredSession, clearSession } from '../services/authService';
import { wsService } from '../services/websocketService';
import { setMuted as setAudioMuted, isMuted as getAudioMuted } from '../services/audioService';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(getStoredSession());
  const [theme, setTheme] = useState(localStorage.getItem('staff_theme') || 'orange');
  const [isWsConnected, setIsWsConnected] = useState(false);
  const [isAudioMuted, setIsAudioMutedState] = useState(getAudioMuted());
  const [toastMessage, setToastMessage] = useState(null);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('staff_theme', theme);
  }, [theme]);

  useEffect(() => {
    if (session.token) {
      wsService.connect((connected) => setIsWsConnected(connected));
    } else {
      wsService.disconnect();
    }
  }, [session.token]);

  const showToast = (message, type = 'info') => {
    setToastMessage({ message, type, id: Date.now() });
    setTimeout(() => setToastMessage(null), 4000);
  };

  const handleLogout = () => {
    clearSession();
    setSession({ token: null, role: null, primaryRole: null, username: null, staffId: null });
    wsService.disconnect();
    showToast('Logged out successfully', 'info');
  };

  const toggleTheme = () => {
    setTheme((prev) => {
      if (prev === 'dark')   return 'orange';
      if (prev === 'orange') return 'light';
      return 'dark';
    });
  };

  const toggleAudioMute = () => {
    const nextMuted = !isAudioMuted;
    setAudioMuted(nextMuted);
    setIsAudioMutedState(nextMuted);
    showToast(nextMuted ? 'Sound Notifications Muted' : 'Sound Notifications Enabled', 'info');
  };

  const updateSession = (newSessionData) => {
    setSession(newSessionData);
  };

  return (
    <AuthContext.Provider
      value={{
        session,
        role: session.role,
        primaryRole: session.primaryRole,
        username: session.username,
        staffId: session.staffId,
        theme,
        toggleTheme,
        isWsConnected,
        isAudioMuted,
        toggleAudioMute,
        toastMessage,
        showToast,
        logout: handleLogout,
        updateSession,
      }}
    >
      {children}

      {/* Global Toast Notification */}
      {toastMessage && (
        <div className="pos-toast">
          <div
            className={`toast show align-items-center text-white border-0 shadow-lg bg-${
              toastMessage.type === 'error'
                ? 'danger'
                : toastMessage.type === 'success'
                ? 'success'
                : toastMessage.type === 'warning'
                ? 'warning'
                : 'dark'
            }`}
          >
            <div className="d-flex">
              <div className="toast-body fw-semibold">{toastMessage.message}</div>
              <button
                type="button"
                className="btn-close btn-close-white me-2 m-auto"
                onClick={() => setToastMessage(null)}
              />
            </div>
          </div>
        </div>
      )}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
}
