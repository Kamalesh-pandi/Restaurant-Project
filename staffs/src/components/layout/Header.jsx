import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { 
  Search, 
  Bell, 
  User, 
  Wifi, 
  WifiOff, 
  Shuffle, 
  Sun, 
  Moon, 
  Flame
} from 'lucide-react';

export default function Header({ title, searchPlaceholder = "Search orders, tables, guests..." }) {
  const { session, role, primaryRole, username, theme, toggleTheme, isWsConnected, switchRole } = useAuth();
  const navigate = useNavigate();
  const [showNotifications, setShowNotifications] = useState(false);

  const getSubRoleTitle = () => {
    return 'SYSTEM ADMIN';
  };

  return (
    <div className="bg-surface border-bottom border-custom px-4 py-3 d-flex align-items-center justify-content-between sticky-top shadow-sm">
      {/* Title / Search */}
      <div className="d-flex align-items-center gap-4 flex-grow-1 me-3">
        <h4 className="fw-bold text-main m-0 d-none d-md-block text-nowrap">{title || 'Dashboard'}</h4>
        <div className="input-group" style={{ maxWidth: '400px' }}>
          <span className="input-group-text bg-card-custom border-custom text-muted-custom border-end-0">
            <Search size={18} />
          </span>
          <input
            type="text"
            className="form-control bg-card-custom border-custom text-main border-start-0 ps-0"
            placeholder={searchPlaceholder}
          />
        </div>
      </div>

      {/* Header Actions & Profile */}
      <div className="d-flex align-items-center gap-3">
        {/* Live WS Status */}
        <div className="d-flex align-items-center gap-2 px-3 py-1 rounded-pill bg-success bg-opacity-10 text-success border border-success small fw-semibold">
          <span className="bg-success rounded-circle" style={{ width: '8px', height: '8px' }}></span>
          <span className="d-none d-lg-inline">KITCHEN LIVE</span>
        </div>

        {/* Notifications Bell */}
        <div className="dropdown position-relative">
          <button
            className="btn btn-outline-secondary border-custom text-main rounded-circle p-2 touch-btn"
            type="button"
            onClick={() => setShowNotifications(!showNotifications)}
            title="Notifications"
          >
            <Bell size={18} />
            <span className="position-absolute top-0 start-100 translate-middle p-1 bg-danger border border-light rounded-circle"></span>
          </button>
        </div>

        {/* Theme Toggle */}
        <button className="btn btn-outline-secondary border-custom text-main p-2 rounded-circle touch-btn" onClick={toggleTheme} title={`Current Theme: ${theme.toUpperCase()} (Click to change)`}>
          {theme === 'dark' ? (
            <Moon size={18} className="text-info" />
          ) : theme === 'orange' ? (
            <Flame size={18} className="text-danger" />
          ) : (
            <Sun size={18} className="text-warning" />
          )}
        </button>

        {/* User Profile Badge */}
        {username && (
          <div className="d-flex align-items-center gap-2 ps-2 border-start border-custom">
            <div className="bg-blue-light p-2 rounded-circle text-blue">
              <User size={20} />
            </div>
            <div className="d-none d-sm-block text-start">
              <span className="fw-bold d-block text-main lh-1" style={{ fontSize: '0.9rem' }}>{username}</span>
              <span className="text-muted-custom d-block mt-1" style={{ fontSize: '0.68rem' }}>{getSubRoleTitle()}</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
