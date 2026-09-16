import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import {
  Utensils,
  BarChart3,
  Grid,
  DollarSign,
  ChefHat,
  Users,
  ChevronLeft,
  ChevronRight,
  LogOut,
  Flame,
  ShoppingBag,
  Calendar,
  Package,
  TrendingUp,
  Tag,
} from 'lucide-react';

const ROLE_NAV = {
  MANAGER: [
    { key: 'overview',     label: 'Overview',            icon: BarChart3 },
    { key: 'staff',        label: 'Staff & Shifts',      icon: Users },
    { key: 'menu',         label: 'Menu Catalog',        icon: ShoppingBag },
    { key: 'floor',        label: 'Floor Plan',          icon: Grid },
    { key: 'stations',     label: 'Kitchen Stations',    icon: Flame },
    { key: 'reservations', label: 'Reservations',        icon: Calendar },
    { key: 'inventory',    label: 'Inventory & Stock',   icon: Package },
    { key: 'reports',      label: 'Reports & Analytics', icon: TrendingUp },
    { key: 'discounts',    label: 'Discounts & Promos',  icon: Tag },
  ],
  CASHIER: [
    { key: 'billing',      label: 'Billing & POS',       icon: DollarSign },
    { key: 'floor',        label: 'Floor Plan',          icon: Grid },
    { key: 'reservations', label: 'Reservations',        icon: Calendar },
  ],
  CAPTAIN: [
    { key: 'orders',       label: 'Floor & Orders',      icon: Utensils },
    { key: 'floor',        label: 'Canvas Layout',       icon: Grid },
    { key: 'reservations', label: 'Waitlist',            icon: Calendar },
  ],
  KITCHEN: [
    { key: 'kds',          label: 'Kitchen Display',     icon: Flame },
    { key: 'stations',     label: 'Kitchen Stations',    icon: ChefHat },
  ],
};

const ROLE_COLORS = {
  MANAGER: '#ea580c',
  CASHIER: '#ea580c',
  CAPTAIN: '#ea580c',
  KITCHEN: '#ea580c',
};

export default function StaffSidebar({ activeView, setActiveView }) {
  const { role, username, primaryRole, logout } = useAuth();
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);

  const currentRole = role || primaryRole || 'MANAGER';
  const nav = ROLE_NAV[currentRole] || ROLE_NAV.MANAGER;
  const roleColor = ROLE_COLORS[currentRole] || '#6b7280';

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div
      className="bg-surface border-end border-custom d-flex flex-column"
      style={{
        width: collapsed ? '80px' : '240px',
        minHeight: '100vh',
        transition: 'width 0.2s ease-in-out',
        zIndex: 1020,
        flexShrink: 0,
      }}
    >
      {/* Brand Header */}
      <div className="p-3 border-bottom border-custom d-flex align-items-center justify-content-between">
        <div className="d-flex align-items-center gap-2 overflow-hidden">
          <div className="bg-blue text-white p-2 rounded-3 d-flex align-items-center justify-content-center shadow-sm" style={{ flexShrink: 0 }}>
            <Utensils size={20} className="text-white" />
          </div>
          {!collapsed && (
            <span className="fw-bold fs-5 text-main text-nowrap">
              Staff Portal
            </span>
          )}
        </div>
        <button
          className="btn btn-sm btn-outline-secondary border-custom text-main p-1 rounded-circle"
          onClick={() => setCollapsed(!collapsed)}
          title={collapsed ? 'Expand Sidebar' : 'Collapse Sidebar'}
          style={{ flexShrink: 0 }}
        >
          {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        </button>
      </div>

      {/* Role Badge */}
      {!collapsed && (
        <div className="px-3 py-2 border-bottom border-custom">
          <span
            className="role-badge d-block text-center"
            style={{ background: `${roleColor}22`, color: roleColor }}
          >
            {currentRole}
          </span>
        </div>
      )}

      {/* Navigation List */}
      <div className="flex-grow-1 p-2 overflow-auto">
        <div className="nav flex-column gap-1">
          {nav.map((item) => {
            const IconComp = item.icon;
            const isActive = activeView === item.key;
            return (
              <button
                key={item.key}
                id={`nav-${item.key}`}
                className={`btn w-100 touch-btn border-0 text-start d-flex align-items-center justify-content-between px-3 py-2 rounded-3 transition-all ${
                  isActive
                    ? 'bg-blue-light text-blue fw-bold shadow-sm'
                    : 'text-main hover-bg-card'
                }`}
                onClick={() => setActiveView(item.key)}
                title={item.label}
              >
                <div className="d-flex align-items-center gap-3">
                  <IconComp size={18} style={{ flexShrink: 0 }} />
                  {!collapsed && <span className="small">{item.label}</span>}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Footer Controls */}
      <div className="p-2 border-top border-custom">
        {!collapsed && username && (
          <div className="px-2 py-2 mb-2 bg-card-custom rounded-3">
            <span className="fw-bold d-block text-main small lh-1" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {username}
            </span>
            <span className="text-muted-custom" style={{ fontSize: '0.68rem' }}>{currentRole}</span>
          </div>
        )}
        <button
          className="btn w-100 text-danger text-start d-flex align-items-center gap-3 px-3 py-2 touch-btn border-0 hover-bg-card rounded-3 fw-bold"
          onClick={handleLogout}
          title="Logout from Session"
        >
          <LogOut size={18} style={{ flexShrink: 0 }} />
          {!collapsed && <span className="small">Logout</span>}
        </button>
      </div>
    </div>
  );
}
