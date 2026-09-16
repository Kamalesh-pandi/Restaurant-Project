import React, { useState, useEffect, useCallback } from 'react';
import { apiRequest } from '../../services/apiClient';
import { useAuth } from '../../context/AuthContext';
import { wsService } from '../../services/websocketService';
import StaffShiftManager from '../staff/StaffShiftManager';
import MenuCatalogManager from '../menu/MenuCatalogManager';
import FloorPlanManager from '../floor/FloorPlanManager';
import KitchenStationManager from '../kitchen/KitchenStationManager';
import ReservationWaitlistManager from '../reservation/ReservationWaitlistManager';
import InventoryStockManager from '../inventory/InventoryStockManager';
import ReportsAnalyticsManager from '../reports/ReportsAnalyticsManager';
import DiscountPromotionsManager from '../discounts/DiscountPromotionsManager';
import {
  BarChart3, Users, Grid, DollarSign, Clock, TrendingUp,
  RefreshCw, AlertTriangle, ShoppingBag, Flame, Calendar, Package, Tag
} from 'lucide-react';

export default function ManagerWorkspace({ activeView, setActiveView }) {
  const { showToast } = useAuth();

  // Data states for Overview
  const [metrics, setMetrics] = useState({ totalRevenue: 0, totalOrders: 0, activeTables: '0/0', staffOnline: 0, pendingOrders: 0 });
  const [orders, setOrders] = useState([]);
  const [inventoryAlerts, setInventoryAlerts] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchOverviewData = useCallback(async () => {
    setLoading(true);
    try {
      const [staffData, tablesData, ordersData, billsData, alertsData] = await Promise.all([
        apiRequest('/api/staff').catch(() => []),
        apiRequest('/api/v1/tables').catch(() => []),
        apiRequest('/api/v1/orders').catch(() => []),
        apiRequest('/api/v1/bills').catch(() => []),
        apiRequest('/api/v1/inventory/alerts').catch(() => []),
      ]);
      const staff  = Array.isArray(staffData)  ? staffData  : [];
      const tbls   = Array.isArray(tablesData)  ? tablesData  : [];
      const ords   = Array.isArray(ordersData)  ? ordersData  : [];
      const bills  = Array.isArray(billsData)   ? billsData   : [];
      const alerts = Array.isArray(alertsData)  ? alertsData  : [];

      const billMap = {};
      bills.forEach(b => {
        if (b.orderId) billMap[b.orderId] = b;
      });

      const tableMap = {};
      tbls.forEach(t => {
        const id = t.tableId || t.id;
        if (id) tableMap[id] = t.tableNumber;
      });

      const enrichedOrders = await Promise.all(ords.map(async (o) => {
        const oId = o.orderId || o.id;
        const matchingBill = billMap[oId];
        let amount = matchingBill?.total != null 
          ? Number(matchingBill.total) 
          : (o.totalAmount != null && Number(o.totalAmount) > 0 ? Number(o.totalAmount) : 0);

        if (amount === 0 && oId) {
          try {
            const rawItems = await apiRequest(`/api/v1/orders/${oId}/items`).catch(() => []);
            if (Array.isArray(rawItems) && rawItems.length > 0) {
              amount = rawItems.reduce((sum, it) => sum + ((Number(it.unitPrice) || 0) * (it.quantity || 1)), 0);
            }
          } catch (_) {}
        }

        const tableNum = o.tableNumber || (o.tableId ? tableMap[o.tableId] : null);

        return {
          ...o,
          tableNumber: tableNum || '—',
          total: amount,
          bill: matchingBill
        };
      }));

      setOrders(enrichedOrders);
      setInventoryAlerts(alerts);

      const totalRev = bills
        .filter(b => (b.isSettled ?? b.settled))
        .reduce((acc, b) => acc + (Number(b.total) || 0), 0);
      const pendingOrds   = ords.filter(o => o.status === 'NEW' || o.status === 'PREPARING').length;
      const occupiedTbls  = tbls.filter(t => t.status === 'OCCUPIED').length;

      setMetrics({
        totalRevenue:  totalRev,
        totalOrders:   ords.length,
        activeTables:  `${occupiedTbls}/${tbls.length}`,
        staffOnline:   staff.filter(s => s.active !== false).length,
        pendingOrders: pendingOrds,
      });
    } catch (err) {
      console.error('Manager overview fetch error:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (activeView === 'overview') {
      fetchOverviewData();
      const unsub1 = wsService.subscribe('/topic/tables', () => fetchOverviewData());
      const unsub2 = wsService.subscribe('/topic/orders', () => fetchOverviewData());
      return () => { unsub1(); unsub2(); };
    }
  }, [activeView, fetchOverviewData]);

  // Route views
  if (activeView === 'staff') {
    return <StaffShiftManager showToast={showToast} isManagerView={true} />;
  }
  if (activeView === 'menu') {
    return <MenuCatalogManager showToast={showToast} />;
  }
  if (activeView === 'floor') {
    return <FloorPlanManager showToast={showToast} />;
  }
  if (activeView === 'stations') {
    return <KitchenStationManager showToast={showToast} />;
  }
  if (activeView === 'reservations') {
    return <ReservationWaitlistManager showToast={showToast} />;
  }
  if (activeView === 'inventory') {
    return <InventoryStockManager showToast={showToast} />;
  }
  if (activeView === 'reports') {
    return <ReportsAnalyticsManager showToast={showToast} />;
  }
  if (activeView === 'discounts') {
    return <DiscountPromotionsManager showToast={showToast} />;
  }

  // Default: Overview Tab
  return (
    <div className="fade-in">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h5 className="fw-extrabold text-main m-0">Operational Overview</h5>
        <button className="btn btn-outline-secondary border-custom text-main touch-btn" onClick={fetchOverviewData} disabled={loading}>
          <RefreshCw size={15} className={loading ? 'spin me-1' : 'me-1'} /> Refresh
        </button>
      </div>

      <div className="row g-3 mb-4">
        {[
          { label: 'Total Revenue',  value: `₹${metrics.totalRevenue.toLocaleString()}`, icon: DollarSign, color: '#ea580c' },
          { label: 'Total Orders',   value: metrics.totalOrders,                          icon: BarChart3,  color: '#2563eb' },
          { label: 'Active Tables',  value: metrics.activeTables,                          icon: Grid,       color: '#9333ea' },
          { label: 'Staff Online',   value: metrics.staffOnline,                           icon: Users,      color: '#16a34a' },
          { label: 'Pending Orders', value: metrics.pendingOrders,                         icon: Clock,      color: '#d97706' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="col-12 col-sm-6 col-lg-4 col-xl">
            <div className="metric-card">
              <div className="d-flex align-items-center gap-3">
                <div className="metric-icon" style={{ background: `${color}1a` }}>
                  <Icon size={22} style={{ color }} />
                </div>
                <div>
                  <span className="text-muted-custom small fw-semibold d-block">{label}</span>
                  <span className="fw-extrabold text-main" style={{ fontSize: '1.4rem' }}>{value}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Action Cards */}
      <div className="card p-3 mb-4">
        <h6 className="fw-bold text-main mb-3">MANAGER QUICK ACTIONS</h6>
        <div className="d-flex flex-wrap gap-2">
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('staff')}>
            <Users size={14} className="me-1" /> Staff Roster & Shifts
          </button>
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('menu')}>
            <ShoppingBag size={14} className="me-1" /> Menu Catalog
          </button>
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('floor')}>
            <Grid size={14} className="me-1" /> Floor Plan Canvas
          </button>
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('stations')}>
            <Flame size={14} className="me-1" /> Kitchen Stations
          </button>
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('reservations')}>
            <Calendar size={14} className="me-1" /> Reservations & Waitlist
          </button>
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('inventory')}>
            <Package size={14} className="me-1" /> Stock & GRN
          </button>
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('reports')}>
            <TrendingUp size={14} className="me-1" /> Sales Reports & Analytics
          </button>
          <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setActiveView('discounts')}>
            <Tag size={14} className="me-1" /> Discounts & Promos
          </button>
        </div>
      </div>

      {/* Recent Orders List */}
      <div className="row g-3">
        <div className="col-12 col-lg-8">
          <div className="card p-3">
            <h6 className="fw-bold text-main mb-3">Recent Orders</h6>
            <div className="table-responsive">
              <table className="table table-sm table-hover mb-0">
                <thead>
                  <tr>
                    <th className="text-muted-custom small">Table</th>
                    <th className="text-muted-custom small">Type</th>
                    <th className="text-muted-custom small">Status</th>
                    <th className="text-muted-custom small">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {orders.slice(0, 8).map((o) => (
                    <tr key={o.orderId || o.id}>
                      <td className="text-main small fw-semibold">{o.tableNumber || o.tableId || '—'}</td>
                      <td className="text-main small">{o.orderType || o.type || '—'}</td>
                      <td>
                        <span className={`badge small ${o.status === 'COMPLETED' ? 'bg-success' : o.status === 'PREPARING' ? 'bg-warning text-dark' : 'bg-secondary'}`}>
                          {o.status}
                        </span>
                      </td>
                      <td className="text-main small fw-semibold">₹{(o.total || 0).toFixed(0)}</td>
                    </tr>
                  ))}
                  {orders.length === 0 && (
                    <tr><td colSpan={4} className="text-center text-muted-custom py-3">No active orders</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Low Stock Alerts */}
        <div className="col-12 col-lg-4">
          <div className="card p-3">
            <div className="d-flex align-items-center justify-content-between mb-3">
              <h6 className="fw-bold text-main m-0">Inventory Alerts</h6>
              {inventoryAlerts.length > 0 && (
                <span className="badge bg-warning text-dark">{inventoryAlerts.length} Alerts</span>
              )}
            </div>
            {inventoryAlerts.length === 0 ? (
              <div className="text-center text-muted-custom py-4 small">
                All inventory items are in healthy stock levels!
              </div>
            ) : (
              <div className="d-flex flex-column gap-2 overflow-auto" style={{ maxHeight: 260 }}>
                {inventoryAlerts.map((a, i) => (
                  <div key={i} className="p-2 rounded-3 bg-card-custom border border-warning d-flex align-items-center gap-2">
                    <AlertTriangle size={15} className="text-warning flex-shrink-0" />
                    <div>
                      <span className="fw-bold text-main small d-block">{a.ingredientName || a.name}</span>
                      <span className="text-muted-custom style-micro" style={{ fontSize: '0.7rem' }}>
                        Stock: {a.currentStock} {a.unit} (Min: {a.threshold})
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
