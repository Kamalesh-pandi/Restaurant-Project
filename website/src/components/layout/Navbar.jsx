import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { 
  Utensils, 
  UserCheck, 
  LogOut, 
  Sun, 
  Moon, 
  Flame,
  Wifi, 
  WifiOff, 
  Shuffle, 
  Clock 
} from 'lucide-react';

export default function Navbar() {
  const { session, role, primaryRole, username, theme, toggleTheme, isWsConnected, logout, switchRole } = useAuth();
  const navigate = useNavigate();
  const [currentTime, setCurrentTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const getRoleBadgeColor = (r) => {
    return 'bg-danger text-white';
  };

  return (
    <nav className="navbar navbar-expand-lg bg-surface border-bottom border-custom px-3 py-2 sticky-top shadow-sm">
      <div className="container-fluid p-0">
        {/* Brand */}
        <div className="d-flex align-items-center gap-2">
          <img 
            src="/logo.png" 
            alt="Spice Haven" 
            className="rounded-circle shadow-sm"
            style={{ width: '38px', height: '38px', objectFit: 'cover', border: '1px solid rgba(0,0,0,0.08)' }} 
          />
          <div>
            <span className="fw-bold fs-5 tracking-wide text-main lh-1 d-block">SPICE HAVEN</span>
            <div className="d-flex align-items-center gap-2 text-muted-custom" style={{ fontSize: '0.72rem' }}>
              <Clock size={11} />
              <span>{currentTime}</span>
            </div>
          </div>
        </div>

        {/* Live WS Status & Staff Info */}
        <div className="d-flex align-items-center gap-3 ms-auto me-3">
          {/* WebSocket Status Indicator */}
          <div 
            className={`d-flex align-items-center gap-1 px-2 py-1 rounded-pill text-xs fw-medium ${isWsConnected ? 'bg-success bg-opacity-10 text-success border border-success' : 'bg-danger bg-opacity-10 text-danger border border-danger'}`}
            title={isWsConnected ? 'Live Real-time WebSocket Connected' : 'WebSocket Disconnected'}
          >
            {isWsConnected ? <Wifi size={14} /> : <WifiOff size={14} />}
            <span className="d-none d-sm-inline">{isWsConnected ? 'SYNC LIVE' : 'OFFLINE'}</span>
          </div>

          {/* Active User Badge */}
          {username && (
            <div className="d-flex align-items-center gap-2 bg-card-custom px-3 py-1 rounded-3">
              <UserCheck size={16} className="text-muted-custom" />
              <div>
                <span className="fw-semibold d-block lh-1 text-main" style={{ fontSize: '0.85rem' }}>{username}</span>
                <span className={`badge ${getRoleBadgeColor(role)} px-2 py-0 mt-1`} style={{ fontSize: '0.65rem' }}>
                  {role}
                </span>
              </div>
            </div>
          )}
        </div>

        {/* Action Controls */}
        <div className="d-flex align-items-center gap-2">
          {/* Theme Toggle */}
          <button
            className="btn btn-outline-secondary touch-btn px-2 border-custom text-main"
            onClick={toggleTheme}
            title={`Current Theme: ${theme.toUpperCase()} (Click to change)`}
          >
            {theme === 'dark' ? (
              <Moon size={18} className="text-info" />
            ) : theme === 'orange' ? (
              <Flame size={18} className="text-danger" />
            ) : (
              <Sun size={18} className="text-warning" />
            )}
          </button>

          {/* Logout */}
          <button
            className="btn btn-outline-danger touch-btn px-2"
            onClick={() => {
              logout();
              navigate('/login');
            }}
            title="Logout"
          >
            <LogOut size={18} />
            <span className="d-none d-md-inline ms-1 small">Logout</span>
          </button>
        </div>
      </div>
    </nav>
  );
}

