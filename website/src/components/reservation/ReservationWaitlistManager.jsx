import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  Calendar, 
  Clock, 
  Users, 
  Plus, 
  CheckCircle2, 
  AlertTriangle, 
  Phone, 
  Search, 
  X, 
  UserCheck, 
  XCircle, 
  TrendingUp, 
  BarChart2, 
  Utensils, 
  MessageSquare, 
  ShieldAlert, 
  Sparkles,
  Filter,
  Globe
} from 'lucide-react';

export default function ReservationWaitlistManager({ showToast }) {
  // Data States
  const [reservations, setReservations] = useState([]);
  const [waitlist, setWaitlist] = useState([]);
  const [tables, setTables] = useState([]);
  const [outlets, setOutlets] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(false);

  // Filters & Tabs
  const [activeTab, setActiveTab] = useState('RESERVATIONS'); // 'RESERVATIONS' or 'WAITLIST'
  const [selectedStatusFilter, setSelectedStatusFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  // Modals
  const [showReservationModal, setShowReservationModal] = useState(false);
  const [isOnlineBookingToggle, setIsOnlineBookingToggle] = useState(false);
  const [resForm, setResForm] = useState({
    guestName: '',
    guestPhone: '',
    partySize: 2,
    date: new Date().toISOString().substring(0, 10),
    time: '19:30',
    tableId: '',
    specialRequests: '',
    dietaryRequirements: '',
    preOrderItems: '',
    outletId: ''
  });

  const [showWaitlistModal, setShowWaitlistModal] = useState(false);
  const [waitlistForm, setWaitlistForm] = useState({
    guestName: '',
    guestPhone: '',
    partySize: 2,
    outletId: ''
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [resData, waitData, tblsData, outsData, analyticsData] = await Promise.all([
        apiRequest('/api/v1/reservations').catch(() => []),
        apiRequest('/api/v1/waitlist').catch(() => []),
        apiRequest('/api/v1/tables').catch(() => []),
        apiRequest('/api/v1/chain/outlets').catch(() => []),
        apiRequest('/api/v1/reservations/analytics').catch(() => null),
      ]);

      const resList = Array.isArray(resData) ? resData : [];
      const waitList = Array.isArray(waitData) ? waitData : [];
      const tblList = Array.isArray(tblsData) ? tblsData : [];
      const outList = Array.isArray(outsData) ? outsData : [];

      setReservations(resList);
      setWaitlist(waitList);
      setTables(tblList);
      setOutlets(outList);
      setAnalytics(analyticsData);

      if (outList.length > 0) {
        setResForm(prev => ({ ...prev, outletId: outList[0].id || outList[0].outletId }));
        setWaitlistForm(prev => ({ ...prev, outletId: outList[0].id || outList[0].outletId }));
      }
    } catch (err) {
      console.error('Error fetching reservation & waitlist data:', err);
    } finally {
      setLoading(false);
    }
  };

  // 1. Create Reservation
  const handleSaveReservation = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        guestName: resForm.guestName.trim(),
        guestPhone: resForm.guestPhone.trim(),
        partySize: parseInt(resForm.partySize) || 2,
        date: resForm.date,
        time: resForm.time.length === 5 ? `${resForm.time}:00` : resForm.time,
        tableId: resForm.tableId || null,
        specialRequests: resForm.specialRequests.trim(),
        dietaryRequirements: resForm.dietaryRequirements.trim(),
        preOrderItems: resForm.preOrderItems.trim(),
        outletId: resForm.outletId || (outlets[0]?.id || null),
        status: 'CONFIRMED'
      };

      const endpoint = isOnlineBookingToggle ? '/api/v1/reservations/online' : '/api/v1/reservations';
      const created = await apiRequest(endpoint, 'POST', payload);

      if (showToast) {
        showToast(
          `Reservation confirmed for ${created.guestName}! Confirmation SMS sent to +91${created.guestPhone}.`,
          'success'
        );
      }

      setShowReservationModal(false);
      resetResForm();
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create reservation', 'error');
    }
  };

  const resetResForm = () => {
    setIsOnlineBookingToggle(false);
    setResForm({
      guestName: '',
      guestPhone: '',
      partySize: 2,
      date: new Date().toISOString().substring(0, 10),
      time: '19:30',
      tableId: '',
      specialRequests: '',
      dietaryRequirements: '',
      preOrderItems: '',
      outletId: outlets[0]?.id || ''
    });
  };

  // 2. Update Reservation Status
  const handleUpdateStatus = async (resId, newStatus) => {
    try {
      await apiRequest(`/api/v1/reservations/${resId}/status?status=${newStatus}`, 'PUT');
      if (showToast) showToast(`Reservation status updated to ${newStatus}`, 'info');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Status update failed', 'error');
    }
  };

  // 3. Cancel Reservation by Guest / Restaurant
  const handleCancelByRestaurant = async (resId) => {
    if (!window.confirm('Cancel this reservation?')) return;
    try {
      await apiRequest(`/api/v1/reservations/${resId}/cancel`, 'POST');
      if (showToast) showToast('Reservation cancelled from dashboard', 'warning');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Cancel failed', 'error');
    }
  };

  // 4. Create Waitlist Entry
  const handleSaveWaitlist = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        guestName: waitlistForm.guestName.trim(),
        guestPhone: waitlistForm.guestPhone.trim(),
        partySize: parseInt(waitlistForm.partySize) || 2,
        outletId: waitlistForm.outletId || (outlets[0]?.id || null)
      };
      await apiRequest('/api/v1/waitlist', 'POST', payload);
      if (showToast) showToast(`Guest ${waitlistForm.guestName} added to waitlist!`, 'success');
      setShowWaitlistModal(false);
      setWaitlistForm({ guestName: '', guestPhone: '', partySize: 2, outletId: outlets[0]?.id || '' });
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Waitlist add failed', 'error');
    }
  };

  // 5. Seat Waitlist Guest
  const handleSeatWaitlist = async (waitlistId, tableId) => {
    try {
      await apiRequest(`/api/v1/waitlist/${waitlistId}/seat?tableId=${tableId}`, 'PUT');
      if (showToast) showToast('Waitlist guest seated at table!', 'success');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Seating failed', 'error');
    }
  };

  // 6. Cancel Waitlist Entry
  const handleCancelWaitlist = async (waitlistId) => {
    try {
      await apiRequest(`/api/v1/waitlist/${waitlistId}/cancel`, 'PUT');
      if (showToast) showToast('Waitlist entry cancelled', 'info');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Cancel failed', 'error');
    }
  };

  // Status helper color badge
  const getStatusBadge = (status) => {
    switch (status) {
      case 'ARRIVED': return 'bg-success text-white';
      case 'CONFIRMED': return 'bg-primary text-white';
      case 'NO_SHOW': return 'bg-dark text-white';
      case 'CANCELLED': return 'bg-danger text-white';
      default: return 'bg-secondary text-white';
    }
  };

  // Filtered Reservations
  const filteredReservations = reservations.filter(r => {
    const matchesStatus = selectedStatusFilter === 'ALL' || r.status === selectedStatusFilter;
    const matchesSearch = !searchQuery || 
      (r.guestName && r.guestName.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (r.guestPhone && r.guestPhone.includes(searchQuery));
    return matchesStatus && matchesSearch;
  });

  return (
    <div className="reservation-waitlist-manager">
      {/* Header & Analytics Summary Bar */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <Calendar size={22} className="text-secondary-custom" />
              Table Reservations & Host Stand Waitlist
            </h5>
            <span className="text-muted-custom small">
              Manage guest bookings, SMS confirmation links, online reservations, waitlist queue & booking conversion metrics
            </span>
          </div>

          <div className="d-flex flex-wrap gap-2">
            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowWaitlistModal(true)}>
              <Users size={14} className="me-1 text-danger" /> Add Waitlist Guest
            </button>

            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => { resetResForm(); setShowReservationModal(true); }}>
              <Plus size={14} className="me-1" /> New Table Reservation
            </button>
          </div>
        </div>

        {/* Analytics & Metrics Strip */}
        {analytics && (
          <div className="row g-3 pt-2 border-top border-custom align-items-center">
            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">Total Bookings:</span>
                <span className="fw-bold text-main">{analytics.totalBookings || 0}</span>
              </div>
            </div>

            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">Conversion Rate:</span>
                <span className="fw-bold text-success">{analytics.bookingConversionRate ? analytics.bookingConversionRate.toFixed(1) : 0}%</span>
              </div>
            </div>

            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">No-Show Rate:</span>
                <span className="fw-bold text-danger">{analytics.noShowRate ? analytics.noShowRate.toFixed(1) : 0}%</span>
              </div>
            </div>

            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">Peak Hours:</span>
                <span className="fw-bold text-secondary-custom small">{analytics.peakBookingTimes?.join(', ') || '19:00, 20:00'}</span>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Tabs & Search Filter */}
      <div className="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
        <div className="d-flex gap-2 overflow-auto">
          <button
            className={`btn btn-sm rounded-pill px-3 ${activeTab === 'RESERVATIONS' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setActiveTab('RESERVATIONS')}
          >
            Reservations List ({reservations.length})
          </button>

          <button
            className={`btn btn-sm rounded-pill px-3 ${activeTab === 'WAITLIST' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setActiveTab('WAITLIST')}
          >
            Waiting List Queue ({waitlist.length})
          </button>
        </div>

        {activeTab === 'RESERVATIONS' && (
          <div className="d-flex gap-2 align-items-center">
            <div className="input-group input-group-sm" style={{ width: '220px' }}>
              <span className="input-group-text bg-card-custom border-custom text-muted-custom"><Search size={14} /></span>
              <input
                type="text"
                className="form-control bg-card-custom border-custom text-main"
                placeholder="Search guest or phone..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>

            <select
              className="form-select form-select-sm bg-card-custom border-custom text-main"
              style={{ width: '150px' }}
              value={selectedStatusFilter}
              onChange={(e) => setSelectedStatusFilter(e.target.value)}
            >
              <option value="ALL">All Statuses</option>
              <option value="CONFIRMED">CONFIRMED</option>
              <option value="ARRIVED">ARRIVED</option>
              <option value="NO_SHOW">NO_SHOW</option>
              <option value="CANCELLED">CANCELLED</option>
            </select>
          </div>
        )}
      </div>

      {/* TAB 1: RESERVATIONS DIRECTORY */}
      {activeTab === 'RESERVATIONS' && (
        <div className="card bg-surface border-custom shadow-sm p-3">
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Guest Name</th>
                  <th>Phone Number</th>
                  <th>Party Size</th>
                  <th>Date & Time</th>
                  <th>Table</th>
                  <th>Special Notes</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredReservations.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="text-center py-4 text-muted-custom">
                      No reservations found matching current filters.
                    </td>
                  </tr>
                ) : (
                  filteredReservations.map((r) => {
                    const rId = r.reservationId || r.id;
                    const assignedTable = tables.find(t => (t.tableId || t.id) === r.tableId);

                    return (
                      <tr key={rId}>
                        <td className="fw-bold text-main">
                          {r.isOnlineBooking && <Globe size={13} className="me-1 text-primary" title="Online Booking" />}
                          {r.guestName}
                        </td>
                        <td className="text-muted-custom small"><Phone size={13} className="me-1" />+91 {r.guestPhone}</td>
                        <td><span className="badge bg-secondary text-white">{r.partySize} Pax</span></td>
                        <td className="text-muted-custom small">
                          {r.date} @ {r.time ? String(r.time).substring(0, 5) : '19:30'}
                        </td>
                        <td>
                          {assignedTable ? (
                            <span className="badge bg-secondary text-white">Table {assignedTable.tableNumber}</span>
                          ) : (
                            <span className="text-muted-custom small">Unassigned</span>
                          )}
                        </td>
                        <td className="small text-muted-custom">
                          {r.specialRequests || r.dietaryRequirements ? (
                            <span title={`Dietary: ${r.dietaryRequirements || 'None'}`}>
                              {r.specialRequests || r.dietaryRequirements}
                            </span>
                          ) : (
                            'None'
                          )}
                        </td>
                        <td>
                          <span className={`badge ${getStatusBadge(r.status)}`}>
                            {r.status || 'CONFIRMED'}
                          </span>
                        </td>
                        <td>
                          <div className="d-flex gap-1">
                            {r.status !== 'ARRIVED' && r.status !== 'CANCELLED' && (
                              <button
                                className="btn btn-xs btn-success fw-bold"
                                onClick={() => handleUpdateStatus(rId, 'ARRIVED')}
                              >
                                Mark Arrived
                              </button>
                            )}

                            {r.status === 'CONFIRMED' && (
                              <button
                                className="btn btn-xs btn-dark"
                                onClick={() => handleUpdateStatus(rId, 'NO_SHOW')}
                              >
                                No-Show
                              </button>
                            )}

                            {r.status !== 'CANCELLED' && (
                              <button
                                className="btn btn-xs btn-outline-danger"
                                onClick={() => handleCancelByRestaurant(rId)}
                              >
                                Cancel
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: WAITLIST QUEUE */}
      {activeTab === 'WAITLIST' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h6 className="fw-bold text-main m-0">Waiting List Queue ({waitlist.length})</h6>
            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowWaitlistModal(true)}>
              + Add Waiting Guest
            </button>
          </div>

          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Guest Name</th>
                  <th>Phone Number</th>
                  <th>Party Size</th>
                  <th>Waiting Since</th>
                  <th>Status</th>
                  <th>Seat Table Action</th>
                </tr>
              </thead>
              <tbody>
                {waitlist.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="text-center py-4 text-muted-custom">No guests currently waiting.</td>
                  </tr>
                ) : (
                  waitlist.map((w) => {
                    const wId = w.id || w.waitlistId;
                    const suitableTables = tables.filter(t => t.status === 'AVAILABLE' && t.capacity >= w.partySize);

                    return (
                      <tr key={wId}>
                        <td className="fw-bold text-main">{w.guestName}</td>
                        <td className="text-muted-custom"><Phone size={13} className="me-1" />{w.guestPhone}</td>
                        <td><span className="badge bg-secondary text-white">{w.partySize} Guests</span></td>
                        <td className="text-muted-custom small">
                          <Clock size={13} className="me-1" />
                          {w.createdAt ? new Date(w.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Just now'}
                        </td>
                        <td>
                          <span className={`badge ${w.status === 'WAITING' ? 'bg-warning text-dark' : w.status === 'NOTIFIED' ? 'bg-info text-dark' : w.status === 'SEATED' ? 'bg-success' : 'bg-secondary'}`}>
                            {w.status}
                          </span>
                        </td>
                        <td>
                          {w.status !== 'SEATED' && w.status !== 'CANCELLED' ? (
                            <div className="d-flex gap-2">
                              <select
                                className="form-select form-select-sm bg-card-custom border-custom text-main"
                                style={{ width: '160px' }}
                                onChange={(e) => {
                                  if (e.target.value) handleSeatWaitlist(wId, e.target.value);
                                }}
                              >
                                <option value="">Assign Table...</option>
                                {suitableTables.map(t => (
                                  <option key={t.tableId || t.id} value={t.tableId || t.id}>
                                    Table {t.tableNumber} ({t.capacity} cap)
                                  </option>
                                ))}
                              </select>

                              <button className="btn btn-sm btn-outline-danger" onClick={() => handleCancelWaitlist(wId)}>
                                Cancel
                              </button>
                            </div>
                          ) : (
                            <span className="text-muted-custom small">Seated</span>
                          )}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 1: CREATE RESERVATION FORM                           */}
      {/* ========================================================= */}
      {showReservationModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-lg modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">New Table Reservation</h5>
                <button type="button" className="btn-close" onClick={() => setShowReservationModal(false)}></button>
              </div>

              <form onSubmit={handleSaveReservation}>
                <div className="modal-body">
                  <div className="row g-3 mb-3">
                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Guest Name *</label>
                      <input
                        type="text"
                        className="form-control"
                        required
                        placeholder="e.g. Vikramaditya Singh"
                        value={resForm.guestName}
                        onChange={(e) => setResForm({ ...resForm, guestName: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Mobile Phone (for SMS) *</label>
                      <input
                        type="tel"
                        className="form-control"
                        required
                        placeholder="9876543210"
                        value={resForm.guestPhone}
                        onChange={(e) => setResForm({ ...resForm, guestPhone: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="row g-3 mb-3">
                    <div className="col-6 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Party Size *</label>
                      <input
                        type="number"
                        min="1"
                        className="form-control"
                        required
                        value={resForm.partySize}
                        onChange={(e) => setResForm({ ...resForm, partySize: e.target.value })}
                      />
                    </div>

                    <div className="col-6 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Booking Date *</label>
                      <input
                        type="date"
                        className="form-control"
                        required
                        value={resForm.date}
                        onChange={(e) => setResForm({ ...resForm, date: e.target.value })}
                      />
                    </div>

                    <div className="col-6 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Booking Time *</label>
                      <input
                        type="time"
                        className="form-control"
                        required
                        value={resForm.time}
                        onChange={(e) => setResForm({ ...resForm, time: e.target.value })}
                      />
                    </div>

                    <div className="col-6 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Assign Table</label>
                      <select
                        className="form-select"
                        value={resForm.tableId}
                        onChange={(e) => setResForm({ ...resForm, tableId: e.target.value })}
                      >
                        <option value="">Auto / Optional</option>
                        {tables.map(t => (
                          <option key={t.tableId || t.id} value={t.tableId || t.id}>
                            Table {t.tableNumber} ({t.capacity} cap)
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="row g-3 mb-3">
                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Special Requests</label>
                      <textarea
                        className="form-control"
                        rows="2"
                        placeholder="e.g. Quiet corner table, Birthday celebration"
                        value={resForm.specialRequests}
                        onChange={(e) => setResForm({ ...resForm, specialRequests: e.target.value })}
                      ></textarea>
                    </div>

                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Dietary Requirements / Allergies</label>
                      <textarea
                        className="form-control"
                        rows="2"
                        placeholder="e.g. Gluten-free, Jain preparation"
                        value={resForm.dietaryRequirements}
                        onChange={(e) => setResForm({ ...resForm, dietaryRequirements: e.target.value })}
                      ></textarea>
                    </div>
                  </div>

                  <div className="form-check form-switch">
                    <input
                      className="form-check-input"
                      type="checkbox"
                      id="onlineBookingSwitch"
                      checked={isOnlineBookingToggle}
                      onChange={(e) => setIsOnlineBookingToggle(e.target.checked)}
                    />
                    <label className="form-check-label text-main small fw-bold" htmlFor="onlineBookingSwitch">
                      Tag as Online Customer Booking
                    </label>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowReservationModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Confirm Reservation & Send SMS
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: ADD WAITLIST GUEST FORM                          */}
      {/* ========================================================= */}
      {showWaitlistModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Add Guest to Waitlist</h5>
                <button type="button" className="btn-close" onClick={() => setShowWaitlistModal(false)}></button>
              </div>

              <form onSubmit={handleSaveWaitlist}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Guest Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Neha Gupta"
                      value={waitlistForm.guestName}
                      onChange={(e) => setWaitlistForm({ ...waitlistForm, guestName: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Mobile Phone (for SMS) *</label>
                    <input
                      type="tel"
                      className="form-control"
                      required
                      placeholder="9876543210"
                      value={waitlistForm.guestPhone}
                      onChange={(e) => setWaitlistForm({ ...waitlistForm, guestPhone: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Party Size *</label>
                    <input
                      type="number"
                      min="1"
                      className="form-control"
                      required
                      value={waitlistForm.partySize}
                      onChange={(e) => setWaitlistForm({ ...waitlistForm, partySize: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowWaitlistModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Add to Waitlist
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
