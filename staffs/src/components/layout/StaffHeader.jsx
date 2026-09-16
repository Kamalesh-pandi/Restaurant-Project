import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import {
  Search, Bell, User, Wifi, WifiOff, Sun, Moon, Flame, Volume2, VolumeX, LogOut,
} from 'lucide-react';

const ROLE_LABELS = {
  MANAGER: 'RESTAURANT MANAGER',
  CASHIER: 'CASHIER / POS OPERATOR',
  CAPTAIN: 'FLOOR CAPTAIN',
  KITCHEN: 'KITCHEN STAFF',
};

export default function StaffHeader({ title, searchPlaceholder = 'Search orders, tables, guests...' }) {
  const { username, role, theme, toggleTheme, isWsConnected, isAudioMuted, toggleAudioMute, logout } = useAuth();
  const navigate = useNavigate();
  const [showNotifications, setShowNotifications] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div
      className="bg-surface border-bottom border-custom px-4 py-3 d-flex align-items-center justify-content-between sticky-top shadow-sm"
      style={{ zIndex: 1010 }}
    >
      {/* Title / Search */}
      <div className="d-flex align-items-center gap-4 flex-grow-1 me-3">
        <h4 className="fw-bold text-main m-0 d-none d-md-block text-nowrap">{title || 'Staff Portal'}</h4>
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
        {/* Live WS Status — matches website "KITCHEN LIVE" badge */}
        <div
          className={`d-flex align-items-center gap-2 px-3 py-1 rounded-pill small fw-semibold ${
            isWsConnected
              ? 'bg-success bg-opacity-10 text-success border border-success'
              : 'bg-danger bg-opacity-10 text-danger border border-danger'
          }`}
        >
          <span
            className={`rounded-circle ${isWsConnected ? 'bg-success' : 'bg-danger'}`}
            style={{ width: '8px', height: '8px' }}
          />
          {isWsConnected ? (
            <>
              <Wifi size={13} />
              <span className="d-none d-lg-inline">KITCHEN LIVE</span>
            </>
          ) : (
            <>
              <WifiOff size={13} />
              <span className="d-none d-lg-inline">OFFLINE</span>
            </>
          )}
        </div>

        {/* Audio Toggle */}
        <button
          className="btn btn-outline-secondary border-custom text-main p-2 rounded-circle touch-btn"
          onClick={toggleAudioMute}
          title={isAudioMuted ? 'Unmute sound alerts' : 'Mute sound alerts'}
        >
          {isAudioMuted ? <VolumeX size={18} className="text-muted" /> : <Volume2 size={18} className="text-blue" />}
        </button>

        {/* Notifications Bell */}
        <div className="dropdown position-relative">
          <button
            className="btn btn-outline-secondary border-custom text-main rounded-circle p-2 touch-btn"
            type="button"
            onClick={() => setShowNotifications(!showNotifications)}
            title="Notifications"
          >
            <Bell size={18} />
            <span className="position-absolute top-0 start-100 translate-middle p-1 bg-danger border border-light rounded-circle" />
          </button>
        </div>

        {/* Theme Toggle */}
        <button
          className="btn btn-outline-secondary border-custom text-main p-2 rounded-circle touch-btn"
          onClick={toggleTheme}
          title={`Current Theme: ${theme.toUpperCase()} (Click to change)`}
        >
          {theme === 'dark'   ? <Moon size={18} className="text-info" /> :
           theme === 'orange' ? <Flame size={18} className="text-danger" /> :
                                <Sun size={18} className="text-warning" />}
        </button>

        {/* User Profile & Role Badge */}
        {username && (
          <div className="d-flex align-items-center gap-2 ps-2 border-start border-custom">
            <div className="bg-blue-light p-2 rounded-circle text-blue">
              <User size={20} />
            </div>
            <div className="d-none d-sm-block text-start">
              <span className="fw-bold d-block text-main lh-1" style={{ fontSize: '0.9rem' }}>{username}</span>
              <div className="mt-1">
                <span
                  className="badge bg-card-custom border border-custom text-main fw-semibold py-1 px-2 d-inline-flex align-items-center gap-1"
                  style={{ fontSize: '0.72rem', letterSpacing: '0.02em' }}
                >
                  {role === 'CASHIER' ? '💵 Cashier' :
                   role === 'CAPTAIN' ? '🍽️ Captain' :
                   role === 'KITCHEN' ? '👨‍🍳 Kitchen' :
                   role === 'MANAGER' ? '👑 Manager' : role}
                </span>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
