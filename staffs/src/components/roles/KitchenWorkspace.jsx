import React, { useState, useEffect, useRef, useCallback } from 'react';
import { apiRequest } from '../../services/apiClient';
import { useAuth } from '../../context/AuthContext';
import { wsService } from '../../services/websocketService';
import { playOrderChime, playOrderReadyChime } from '../../services/audioService';
import {
  Flame, CheckCircle2, Clock, RefreshCw, ChefHat, AlertCircle,
  CheckCheck,
} from 'lucide-react';

function useTimer(startTime) {
  const [elapsed, setElapsed] = useState(0);
  useEffect(() => {
    const start = startTime ? new Date(startTime).getTime() : Date.now();
    const interval = setInterval(() => {
      setElapsed(Math.floor((Date.now() - start) / 1000));
    }, 1000);
    return () => clearInterval(interval);
  }, [startTime]);
  const m = Math.floor(elapsed / 60);
  const s = elapsed % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}

function KdsTimerBadge({ startTime }) {
  const elapsed  = useTimer(startTime);
  const minutes  = parseInt(elapsed.split(':')[0]);
  const isUrgent = minutes >= 10;
  return (
    <span className={`kds-timer ${isUrgent ? 'urgent' : 'text-muted-custom'}`}>
      <Clock size={12} className="me-1" style={{ verticalAlign: 'middle' }} />
      {elapsed}
    </span>
  );
}

function groupKdsTickets(rawList) {
  if (!Array.isArray(rawList)) return [];
  const map = new Map();

  for (const raw of rawList) {
    if (raw.items && Array.isArray(raw.items)) {
      map.set(raw.orderId || raw.id, raw);
      continue;
    }

    const orderId = raw.orderId || raw.id;
    if (!orderId) continue;

    if (!map.has(orderId)) {
      map.set(orderId, {
        orderId,
        id: orderId,
        tableNumber: (raw.tableNumber && raw.tableNumber !== 'N/A') ? `Table ${raw.tableNumber}` : null,
        orderType: raw.orderType || 'DINE_IN',
        customerName: raw.customerName,
        customerPhone: raw.customerPhone,
        notes: raw.notes,
        status: raw.status === 'READY' ? 'READY' : (raw.status === 'NEW' ? 'NEW' : 'PREPARING'),
        createdAt: raw.kotFiredAt || raw.createdAt || new Date().toISOString(),
        stationId: raw.stationId,
        stationName: raw.stationName,
        deliveryPartnerName: raw.deliveryPartnerName,
        deliveryPartnerPhone: raw.deliveryPartnerPhone,
        items: [],
      });
    }

    const ticket = map.get(orderId);
    ticket.items.push({
      orderItemId: raw.itemId,
      id: raw.itemId,
      itemName: raw.menuItemName,
      name: raw.menuItemName,
      quantity: raw.quantity || 1,
      modifiers: raw.modifiers,
      course: raw.course,
      status: raw.status || 'PENDING',
      stationId: raw.stationId,
      stationName: raw.stationName,
    });

    if (raw.stationId && !ticket.stationId) ticket.stationId = raw.stationId;
    if (raw.stationName && !ticket.stationName) ticket.stationName = raw.stationName;
    if (raw.deliveryPartnerName && !ticket.deliveryPartnerName) {
      ticket.deliveryPartnerName = raw.deliveryPartnerName;
      ticket.deliveryPartnerPhone = raw.deliveryPartnerPhone;
    }
    if (raw.status === 'PREPARING' && ticket.status === 'NEW') ticket.status = 'PREPARING';
  }

  return Array.from(map.values());
}

export default function KitchenWorkspace() {
  const { showToast } = useAuth();

  const [tickets, setTickets]     = useState([]);
  const [stations, setStations]   = useState([]);
  const [selectedStation, setSelectedStation] = useState('ALL');
  const [loading, setLoading]     = useState(false);
  const prevTicketIds = useRef(new Set());

  const fetchKds = useCallback(async () => {
    setLoading(true);
    try {
      const [kdsData, stationsData] = await Promise.all([
        apiRequest('/api/v1/kds').catch(() => []),
        apiRequest('/api/v1/kitchen-stations').catch(() => []),
      ]);
      const kds = Array.isArray(kdsData) ? kdsData : [];
      const sts = Array.isArray(stationsData) ? stationsData : [];

      setStations(sts);

      const grouped = groupKdsTickets(kds);

      // Sound chime on new orders
      const newIds = new Set(grouped.map(t => t.orderId || t.id));
      let hasNew = false;
      newIds.forEach(id => { if (!prevTicketIds.current.has(id)) hasNew = true; });
      if (hasNew && prevTicketIds.current.size > 0) playOrderChime();
      prevTicketIds.current = newIds;

      setTickets(grouped);
    } catch (err) { console.error('KDS fetch error:', err); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => {
    fetchKds();
    const u1 = wsService.subscribe('/topic/orders', () => fetchKds());
    const u2 = wsService.subscribe('/topic/alerts', (data) => {
      if (data?.type === 'ORDER_READY') playOrderReadyChime();
      if (data?.type === 'NEW_ORDER' || data?.type === 'ORDER_NEW') playOrderChime();
      fetchKds();
    });
    return () => { u1(); u2(); };
  }, [fetchKds]);

  const handleUpdateItemStatus = async (orderId, itemId, newStatus) => {
    try {
      await apiRequest(`/api/v1/kds/orders/${orderId}/items/${itemId}/status?status=${newStatus}`, 'PUT')
        .catch(() => apiRequest(`/api/v1/kds/items/${itemId}/bump`, 'PUT'));
      if (newStatus === 'READY') playOrderReadyChime();
      fetchKds();
    } catch (err) { showToast(err.message || 'Status update failed', 'error'); }
  };

  const handleMarkOrderReady = async (orderId) => {
    try {
      await apiRequest(`/api/v1/kds/orders/${orderId}/ready`, 'PUT');
      playOrderReadyChime();
      showToast('Order marked as ready! 🎉', 'success');
      fetchKds();
    } catch (err) { showToast(err.message || 'Action failed', 'error'); }
  };

  const handleMarkOrderServed = async (orderId, isDelivery = false) => {
    try {
      await apiRequest(`/api/v1/kds/orders/${orderId}/served`, 'PUT');
      showToast(isDelivery ? 'Food served & delivery partner assigned!' : 'Order marked as served!', 'success');
      fetchKds();
    } catch (err) { showToast(err.message || 'Action failed', 'error'); }
  };

  const handleAssignDeliveryPartner = async (orderId) => {
    try {
      const res = await apiRequest(`/api/v1/delivery-management/orders/${orderId}/auto-assign`, 'POST');
      showToast(`Assigned to ${res?.partnerName || 'Delivery Partner'}!`, 'success');
      fetchKds();
    } catch (err) {
      showToast(err.message || 'Could not assign rider', 'error');
    }
  };

  const filteredTickets = tickets.filter(t => {
    if (selectedStation === 'ALL') return true;
    const hasStationItem = (t.items || []).some(
      item => item.stationId === selectedStation || item.stationName === selectedStation
    );
    return t.stationId === selectedStation || t.stationName === selectedStation || hasStationItem;
  });

  const pendingTickets = filteredTickets.filter(t => t.status !== 'SERVED' && t.status !== 'COMPLETED');

  const getTicketStatusClass = (status) => {
    if (status === 'NEW')       return 'status-new';
    if (status === 'PREPARING') return 'status-preparing';
    if (status === 'READY')     return 'status-ready';
    return '';
  };

  const getItemStatusIcon = (status) => {
    if (status === 'READY' || status === 'SERVED')
      return <CheckCircle2 size={14} className="text-success" />;
    if (status === 'PREPARING')
      return <Flame size={14} className="text-warning" />;
    return <Clock size={14} className="text-muted-custom" />;
  };

  const nextStatus = { 'PENDING': 'PREPARING', 'PREPARING': 'READY', 'READY': 'SERVED' };

  return (
    <div className="fade-in">
      {/* Station Filter Bar */}
      <div className="d-flex align-items-center gap-2 mb-4 flex-wrap">
        <div className="d-flex align-items-center gap-2 me-1">
          <Flame size={18} className="text-blue" />
          <span className="fw-bold text-main">Kitchen Display</span>
        </div>
        <button
          className={`btn btn-sm touch-btn ${selectedStation === 'ALL' ? 'btn-blue' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setSelectedStation('ALL')}
        >
          All Stations
        </button>
        {stations.map(s => (
          <button
            key={s.id}
            className={`btn btn-sm touch-btn ${selectedStation === s.id ? 'btn-blue' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setSelectedStation(s.id)}
          >
            {s.name}
          </button>
        ))}
        <div className="ms-auto d-flex align-items-center gap-2">
          <span className="badge bg-danger">{pendingTickets.filter(t => t.status === 'NEW').length} New</span>
          <span className="badge bg-warning text-dark">{pendingTickets.filter(t => t.status === 'PREPARING').length} Cooking</span>
          <span className="badge bg-success">{pendingTickets.filter(t => t.status === 'READY').length} Ready</span>
          <button className="btn btn-sm btn-outline-secondary border-custom" onClick={fetchKds} disabled={loading}>
            <RefreshCw size={13} className={loading ? 'spin' : ''} />
          </button>
        </div>
      </div>

      {/* KDS Tickets Grid */}
      {pendingTickets.length === 0 ? (
        <div className="card p-5 text-center">
          <ChefHat size={52} className="text-muted-custom mx-auto mb-3" style={{ opacity: 0.3 }} />
          <h6 className="text-muted-custom fw-semibold">Kitchen is clear! No pending orders.</h6>
          <span className="text-muted-custom small">New orders will appear here automatically.</span>
        </div>
      ) : (
        <div className="row g-3">
          {pendingTickets.map((ticket) => {
            const orderId = ticket.orderId || ticket.id;
            return (
              <div key={orderId} className="col-12 col-md-6 col-xl-4">
                <div className={`kds-ticket p-3 ${getTicketStatusClass(ticket.status)}`}>
                  {/* Ticket Header */}
                  <div className="d-flex justify-content-between align-items-center mb-3">
                    <div>
                      <span className="fw-extrabold text-main" style={{ fontSize: '1.15rem' }}>
                        {ticket.tableNumber || (ticket.customerName ? `${ticket.customerName} (${ticket.orderType || 'Online'})` : `Order #${String(orderId).slice(-6)}`)}
                      </span>
                      {ticket.stationName && (
                        <span className="badge bg-secondary ms-2 small">{ticket.stationName}</span>
                      )}
                      {ticket.customerPhone && (
                        <div className="text-muted-custom" style={{ fontSize: '0.75rem' }}>📞 {ticket.customerPhone}</div>
                      )}
                    </div>
                    <div className="d-flex align-items-center gap-2">
                      <KdsTimerBadge startTime={ticket.createdAt || ticket.orderTime} />
                      <span className={`badge ${
                        ticket.status === 'NEW'       ? 'bg-danger' :
                        ticket.status === 'PREPARING' ? 'bg-warning text-dark' :
                        ticket.status === 'READY'     ? 'bg-success' : 'bg-secondary'
                      }`}>{ticket.status}</span>
                    </div>
                  </div>

                  {/* Items */}
                  <div className="mb-3">
                    {(ticket.items || []).map((item) => {
                      const itemId = item.orderItemId || item.id;
                      const isDone = item.status === 'READY' || item.status === 'SERVED';
                      const ns = nextStatus[item.status] || 'READY';
                      return (
                        <div
                          key={itemId}
                          className={`kds-item-row ${isDone ? 'item-done' : ''}`}
                          onClick={() => !isDone && handleUpdateItemStatus(orderId, itemId, ns)}
                          title={isDone ? 'Done' : `Click to mark as ${ns}`}
                        >
                          <div className="d-flex align-items-center gap-2">
                            {getItemStatusIcon(item.status)}
                            <span className="text-main small fw-semibold">{item.itemName || item.name}</span>
                          </div>
                          <div className="d-flex align-items-center gap-2">
                            <span className="text-muted-custom small fw-bold">× {item.quantity || 1}</span>
                          </div>
                        </div>
                      );
                    })}
                    {(!ticket.items || ticket.items.length === 0) && (
                      <div className="text-center text-muted-custom small py-2">No items</div>
                    )}
                  </div>

                  {ticket.notes && (
                    <div className="bg-warning bg-opacity-10 border border-warning rounded-2 p-2 mb-3 d-flex gap-2 align-items-start">
                      <AlertCircle size={13} className="text-warning flex-shrink-0 mt-1" />
                      <span className="small text-main">{ticket.notes}</span>
                    </div>
                  )}

                  {/* Ticket Actions */}
                  <div className="d-flex gap-2">
                    {ticket.status !== 'READY' && (
                      <button
                        className="btn btn-sm btn-outline-success flex-grow-1 touch-btn"
                        onClick={() => handleMarkOrderReady(orderId)}
                      >
                        <CheckCircle2 size={13} className="me-1" /> Mark Ready
                      </button>
                    )}
                    {ticket.status === 'READY' && (
                      <button
                        className="btn btn-sm btn-success flex-grow-1 touch-btn"
                        onClick={() => handleMarkOrderServed(orderId, ticket.orderType === 'DELIVERY' || ticket.orderType === 'DIRECT_ONLINE')}
                      >
                        <CheckCheck size={13} className="me-1" />
                        {(ticket.orderType === 'DELIVERY' || ticket.orderType === 'DIRECT_ONLINE') ? 'Served & Assign Rider' : 'Served'}
                      </button>
                    )}
                    {(ticket.orderType === 'DELIVERY' || ticket.orderType === 'DIRECT_ONLINE') && !ticket.deliveryPartnerName && (
                      <button
                        className="btn btn-sm btn-outline-primary touch-btn"
                        title="Assign Delivery Partner"
                        onClick={() => handleAssignDeliveryPartner(orderId)}
                      >
                        Assign Rider
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
