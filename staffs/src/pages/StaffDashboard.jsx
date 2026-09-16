import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import StaffSidebar from '../components/layout/StaffSidebar';
import StaffHeader from '../components/layout/StaffHeader';
import ManagerWorkspace from '../components/roles/ManagerWorkspace';
import CashierWorkspace from '../components/roles/CashierWorkspace';
import CaptainWorkspace from '../components/roles/CaptainWorkspace';
import KitchenWorkspace from '../components/roles/KitchenWorkspace';

import FloorPlanManager from '../components/floor/FloorPlanManager';
import ReservationWaitlistManager from '../components/reservation/ReservationWaitlistManager';
import KitchenStationManager from '../components/kitchen/KitchenStationManager';

const ROLE_DEFAULT_VIEW = {
  MANAGER:  'overview',
  CASHIER:  'billing',
  CAPTAIN:  'orders',
  KITCHEN:  'kds',
};

const VIEW_TITLES = {
  overview:     'Overview & Analytics',
  staff:        'Staff & Shifts',
  menu:         'Menu Catalog',
  floor:        'Floor Plan Canvas',
  stations:     'Kitchen Stations',
  reservations: 'Reservations & Waitlist',
  inventory:    'Inventory & Stock',
  reports:      'Reports & Analytics',
  billing:      'POS Billing & Checkout',
  orders:       'Take Table Order',
  kds:          'Kitchen Display System (KDS)',
  discounts:    'Discounts & Promotions',
};

export default function StaffDashboard() {
  const { role, session, showToast } = useAuth();
  const navigate = useNavigate();
  const [activeView, setActiveView] = useState(ROLE_DEFAULT_VIEW[role] || 'overview');

  useEffect(() => {
    if (!session.token) {
      navigate('/login', { replace: true });
    }
  }, [session.token, navigate]);

  useEffect(() => {
    setActiveView(ROLE_DEFAULT_VIEW[role] || 'overview');
  }, [role]);

  if (!session.token) return null;

  const renderWorkspace = () => {
    if (role === 'MANAGER') {
      return <ManagerWorkspace activeView={activeView} setActiveView={setActiveView} />;
    }

    if (role === 'CASHIER') {
      if (activeView === 'floor') return <FloorPlanManager showToast={showToast} />;
      if (activeView === 'reservations') return <ReservationWaitlistManager showToast={showToast} />;
      return <CashierWorkspace />;
    }

    if (role === 'CAPTAIN') {
      if (activeView === 'reservations') return <ReservationWaitlistManager showToast={showToast} />;
      if (activeView === 'orders') return <CaptainWorkspace />;
      return <FloorPlanManager showToast={showToast} />;
    }

    if (role === 'KITCHEN') {
      if (activeView === 'stations') return <KitchenStationManager showToast={showToast} />;
      return <KitchenWorkspace />;
    }

    return <ManagerWorkspace activeView={activeView} setActiveView={setActiveView} />;
  };

  return (
    <div className="d-flex min-vh-100 bg-primary-custom">
      {/* Sidebar */}
      <StaffSidebar activeView={activeView} setActiveView={setActiveView} />

      {/* Main Content */}
      <div className="flex-grow-1 d-flex flex-column overflow-hidden">
        <StaffHeader title={VIEW_TITLES[activeView] || 'Staff Portal'} />

        <div className="flex-grow-1 p-4 overflow-auto">
          {renderWorkspace()}
        </div>
      </div>
    </div>
  );
}
