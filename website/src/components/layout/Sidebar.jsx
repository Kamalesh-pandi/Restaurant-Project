import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { 
  Utensils, 
  Grid, 
  ShoppingBag, 
  Calendar, 
  Users, 
  BarChart3, 
  Package, 
  LogOut, 
  ChevronLeft, 
  ChevronRight,
  TrendingUp,
  Building,
  Flame
} from 'lucide-react';

export default function Sidebar({ activeView, setActiveView, roleTitle, roleLogo }) {
  const { role, primaryRole, username, logout, switchRole } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [collapsed, setCollapsed] = useState(false);

  // Menu items for Admin Dashboard
  const adminNav = [
    { key: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { key: 'staff', label: 'Staff & Admins', icon: Users },
    { key: 'menu', label: 'Menu Catalog & QR', icon: ShoppingBag },
    { key: 'floor', label: 'Floor Plan', icon: Grid },
    { key: 'chain', label: 'Chain & Outlets', icon: Building },
    { key: 'stations', label: 'Kitchen Stations', icon: Flame },
    { key: 'reservations', label: 'Reservations & Waitlist', icon: Calendar },
    { key: 'inventory', label: 'Inventory & Stock', icon: Package },
    { key: 'reports', label: 'Reports & Analytics', icon: TrendingUp },
  ];

  const currentNav = adminNav;

  return (
    <div
      className={`bg-surface border-end border-custom d-flex flex-column transition-all ${
        collapsed ? 'sidebar-collapsed' : 'sidebar-expanded'
      }`}
      style={{
        width: collapsed ? '80px' : '240px',
        minHeight: '100vh',
        transition: 'width 0.2s ease-in-out',
        zIndex: 1020,
      }}
    >
      {/* Brand Header */}
      <div className="p-3 border-bottom border-custom d-flex align-items-center justify-content-between">
        <div className="d-flex align-items-center gap-2 overflow-hidden">
          <img 
            src="/logo.png" 
            alt="Spice Haven" 
            className="rounded-circle flex-shrink-0 shadow-sm"
            style={{ width: '36px', height: '36px', objectFit: 'cover', border: '1px solid rgba(0,0,0,0.08)' }} 
          />
          {!collapsed && (
            <div className="overflow-hidden">
              <span className="fw-bold fs-6 text-main text-nowrap d-block lh-sm">
                {roleLogo || 'Spice Haven'}
              </span>
              <span className="text-muted-custom text-nowrap d-block" style={{ fontSize: '0.62rem', letterSpacing: '0.05em' }}>
                RESTAURANT &amp; POS
              </span>
            </div>
          )}
        </div>
        <button
          className="btn btn-sm btn-outline-secondary border-custom text-main p-1 rounded-circle"
          onClick={() => setCollapsed(!collapsed)}
          title={collapsed ? 'Expand Sidebar' : 'Collapse Sidebar'}
        >
          {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        </button>
      </div>

      {/* Navigation List */}
      <div className="flex-grow-1 p-2 overflow-auto">
        <div className="nav flex-column gap-1">
          {currentNav.map((item) => {
            const IconComp = item.icon;
            const isActive = activeView === item.key;
            return (
              <button
                key={item.key}
                className={`btn w-100 touch-btn border-0 text-start d-flex align-items-center justify-content-between px-3 py-2 rounded-3 transition-all ${
                  isActive
                    ? 'bg-blue-light text-blue fw-bold shadow-sm'
                    : 'text-main hover-bg-card'
                }`}
                onClick={() => setActiveView(item.key)}
                title={item.label}
              >
                <div className="d-flex align-items-center gap-3">
                  <IconComp size={18} />
                  {!collapsed && <span className="small">{item.label}</span>}
                </div>
                {!collapsed && item.badge && (
                  <span className="badge bg-danger rounded-pill small">{item.badge}</span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Footer Controls - Prominent Logout Button */}
      <div className="p-2 border-top border-custom">
        <button
          className="btn w-100 text-danger text-start d-flex align-items-center gap-3 px-3 py-2 touch-btn border-0 hover-bg-card rounded-3 fw-bold"
          onClick={() => {
            logout();
            navigate('/login');
          }}
          title="Logout from Session"
        >
          <LogOut size={18} />
          {!collapsed && <span className="small">Logout</span>}
        </button>
      </div>
    </div>
  );
}
