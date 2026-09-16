import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  Flame, 
  Plus, 
  Trash2, 
  Clock, 
  CheckCircle2, 
  AlertTriangle, 
  RefreshCw, 
  ChefHat, 
  Layers, 
  Activity, 
  Play, 
  RotateCcw, 
  Filter, 
  Utensils, 
  Zap, 
  BarChart2,
  Check,
  X
} from 'lucide-react';

export default function KitchenStationManager({ showToast }) {
  // Data States
  const [stations, setStations] = useState([]);
  const [selectedStationId, setSelectedStationId] = useState(null);
  const [stationKdsTickets, setStationKdsTickets] = useState([]);
  const [recalledTickets, setRecalledTickets] = useState([]);
  const [performanceMetrics, setPerformanceMetrics] = useState(null);
  const [assignedMenuItems, setAssignedMenuItems] = useState([]);
  const [loading, setLoading] = useState(false);

  // Tabs: 'KDS_LIVE', 'STATIONS_CONFIG', 'STATION_MENU'
  const [activeTab, setActiveTab] = useState('KDS_LIVE');

  // Modals
  const [showAddStationModal, setShowAddStationModal] = useState(false);
  const [newStationName, setNewStationName] = useState('');

  useEffect(() => {
    fetchStations();
  }, []);

  useEffect(() => {
    if (selectedStationId) {
      fetchStationData(selectedStationId);
    }
  }, [selectedStationId]);

  const fetchStations = async () => {
    setLoading(true);
    try {
      const res = await apiRequest('/api/v1/kitchen-stations');
      const stList = Array.isArray(res) ? res : [];
      setStations(stList);
      if (stList.length > 0 && !selectedStationId) {
        setSelectedStationId(stList[0].id);
      }
    } catch (err) {
      console.error('Error fetching kitchen stations:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStationData = async (stationId) => {
    try {
      const [kdsRes, recalledRes, perfRes, menuRes] = await Promise.all([
        apiRequest(`/api/v1/kds/${stationId}/orders`).catch(() => []),
        apiRequest(`/api/v1/kds/${stationId}/recalled`).catch(() => []),
        apiRequest(`/api/v1/kds/performance?stationId=${stationId}`).catch(() => null),
        apiRequest('/api/v1/menu/items').catch(() => []),
      ]);

      setStationKdsTickets(Array.isArray(kdsRes) ? kdsRes : []);
      setRecalledTickets(Array.isArray(recalledRes) ? recalledRes : []);
      setPerformanceMetrics(perfRes);

      const allDishes = Array.isArray(menuRes) ? menuRes : [];
      setAssignedMenuItems(allDishes.filter(item => item.stationId === stationId));
    } catch (err) {
      console.error('Error fetching station details:', err);
    }
  };

  // 1. Create Kitchen Station
  const handleCreateStation = async (e) => {
    e.preventDefault();
    if (!newStationName.trim()) return;

    try {
      const res = await apiRequest('/api/v1/kitchen-stations', 'POST', {
        name: newStationName.trim().toUpperCase()
      });
      if (showToast) showToast(`Kitchen station '${res.name}' created!`, 'success');
      setShowAddStationModal(false);
      setNewStationName('');
      fetchStations();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create station', 'error');
    }
  };

  // 2. Delete Kitchen Station
  const handleDeleteStation = async (stationId) => {
    if (!window.confirm('Are you sure you want to delete this kitchen station?')) return;
    try {
      await apiRequest(`/api/v1/kitchen-stations/${stationId}`, 'DELETE');
      if (showToast) showToast('Kitchen station deleted', 'success');
      if (selectedStationId === stationId) {
        setSelectedStationId(null);
      }
      fetchStations();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to delete station', 'error');
    }
  };

  // 3. Bump KDS Ticket Item
  const handleBumpItem = async (itemId) => {
    try {
      await apiRequest(`/api/v1/kds/items/${itemId}/bump`, 'PUT');
      if (showToast) showToast('Ticket item bumped to next status!', 'success');
      if (selectedStationId) fetchStationData(selectedStationId);
    } catch (err) {
      if (showToast) showToast(err.message || 'Bump failed', 'error');
    }
  };

  // 4. Recall Bumped Item
  const handleRecallItem = async (itemId) => {
    try {
      await apiRequest(`/api/v1/kds/items/${itemId}/bump`, 'PUT');
      if (showToast) showToast('Ticket recalled back to preparation queue', 'info');
      if (selectedStationId) fetchStationData(selectedStationId);
    } catch (err) {
      if (showToast) showToast(err.message || 'Recall failed', 'error');
    }
  };

  // Active station entity
  const currentStation = stations.find(s => s.id === selectedStationId);

  // Color helper for KDS Tickets
  const getTicketHeaderColor = (colorCode) => {
    switch (colorCode) {
      case 'RED': return 'bg-danger text-white';
      case 'AMBER': return 'bg-warning text-dark';
      default: return 'bg-success text-white';
    }
  };

  return (
    <div className="kitchen-station-manager">
      {/* Top Controls & Station Selector */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <ChefHat size={22} className="text-secondary-custom" />
              Kitchen Stations & KDS Preparation Display System
            </h5>
            <span className="text-muted-custom small">
              Live preparation tickets, station routing, cook time analytics & preparation status bump controls
            </span>
          </div>

          <div className="d-flex flex-wrap gap-2">
            <button
              className="btn btn-outline-secondary touch-btn btn-sm"
              onClick={() => selectedStationId && fetchStationData(selectedStationId)}
            >
              <RefreshCw size={14} className="me-1" /> Refresh KDS Live
            </button>

            <button
              className="btn btn-secondary touch-btn btn-sm fw-bold"
              onClick={() => setShowAddStationModal(true)}
            >
              <Plus size={14} className="me-1" /> Add Kitchen Station
            </button>
          </div>
        </div>

        {/* Station Tabs / Selector Pills */}
        <div className="d-flex gap-2 overflow-auto pb-1 border-top border-custom pt-3">
          {stations.map((st) => (
            <button
              key={st.id}
              className={`btn btn-sm rounded-pill px-3 text-nowrap d-flex align-items-center gap-2 ${
                selectedStationId === st.id ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'
              }`}
              onClick={() => setSelectedStationId(st.id)}
            >
              <Flame size={14} />
              {st.name}
            </button>
          ))}
        </div>

        {/* Selected Station Performance Summary */}
        {currentStation && performanceMetrics && (
          <div className="row g-3 mt-2 pt-2 border-top border-custom align-items-center">
            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">Live Active Tickets:</span>
                <span className="fw-bold text-danger">{performanceMetrics.currentOrdersCount || 0} Tickets</span>
              </div>
            </div>

            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">Avg Prep Speed:</span>
                <span className="fw-bold text-secondary-custom">
                  {performanceMetrics.averagePrepTimeMinutes ? performanceMetrics.averagePrepTimeMinutes.toFixed(1) : 0} mins
                </span>
              </div>
            </div>

            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">Completed Dishes:</span>
                <span className="fw-bold text-success">{performanceMetrics.itemsSoldCount || 0} Items</span>
              </div>
            </div>

            <div className="col-6 col-md-3">
              <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
                <span className="small text-muted-custom">Assigned Dishes:</span>
                <span className="fw-bold text-main">{assignedMenuItems.length} Menu Items</span>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Main Tab Controls */}
      <div className="d-flex gap-2 mb-4 overflow-auto">
        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'KDS_LIVE' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('KDS_LIVE')}
        >
          KDS Live Station Queue ({stationKdsTickets.length})
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'STATION_MENU' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('STATION_MENU')}
        >
          Assigned Station Dishes ({assignedMenuItems.length})
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'STATIONS_CONFIG' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('STATIONS_CONFIG')}
        >
          Manage All Kitchen Stations ({stations.length})
        </button>
      </div>

      {/* TAB 1: KDS LIVE TICKETS QUEUE */}
      {activeTab === 'KDS_LIVE' && (
        <div>
          <div className="row g-3">
            {stationKdsTickets.length === 0 ? (
              <div className="col-12 text-center py-5 card bg-surface border-custom">
                <ChefHat size={40} className="mx-auto mb-2 opacity-50 text-muted-custom" />
                <h6 className="fw-bold text-main">No Pending Orders at '{currentStation?.name || 'Station'}'</h6>
                <p className="text-muted-custom small m-0">All tickets have been prepared and bumped!</p>
              </div>
            ) : (
              stationKdsTickets.map((ticket) => {
                const isVoided = ticket.status === 'VOIDED';

                return (
                  <div key={ticket.itemId} className="col-12 col-sm-6 col-md-4 col-xl-3">
                    <div className={`card bg-surface border-custom shadow-sm h-100 overflow-hidden ${isVoided ? 'border-danger' : ''}`}>
                      {/* Ticket Card Header */}
                      <div className={`p-2 d-flex justify-content-between align-items-center ${isVoided ? 'bg-danger text-white' : getTicketHeaderColor(ticket.colorCode)}`}>
                        <span className="fw-bold text-uppercase small">
                          TBL: {ticket.tableNumber || 'N/A'} • {ticket.orderType || 'DINE-IN'}
                        </span>
                        <span className="badge bg-dark text-white text-xs">
                          <Clock size={11} className="me-1" />
                          {ticket.minutesElapsed || 0}m
                        </span>
                      </div>

                      {/* Ticket Card Body */}
                      <div className="card-body p-3 d-flex flex-column justify-content-between">
                        <div>
                          <h6 className={`fw-bold m-0 ${isVoided ? 'text-danger text-decoration-line-through' : 'text-main'}`}>
                            {ticket.quantity}x {ticket.menuItemName}
                          </h6>

                          {ticket.course && (
                            <span className="badge bg-secondary text-white text-xs my-1">
                              Course: {ticket.course}
                            </span>
                          )}

                          {ticket.modifiers && (
                            <p className="text-muted-custom small mb-2 bg-card-custom p-2 rounded border border-custom">
                              <strong>Add-ons:</strong> {ticket.modifiers}
                            </p>
                          )}

                          {isVoided && (
                            <div className="alert alert-danger p-2 small mb-2">
                              <strong>VOIDED:</strong> {ticket.voidReason || 'Cancelled by staff'}
                            </div>
                          )}
                        </div>

                        {/* Bump Action Button */}
                        {!isVoided && (
                          <button
                            className="btn btn-secondary w-100 touch-btn fw-bold btn-sm mt-3 d-flex align-items-center justify-content-center gap-1"
                            onClick={() => handleBumpItem(ticket.itemId)}
                          >
                            <CheckCircle2 size={16} /> Bump / Prepared
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* Recalled Bumps Section */}
          {recalledTickets.length > 0 && (
            <div className="mt-5 card bg-surface border-custom shadow-sm p-3">
              <h6 className="fw-bold text-main mb-3 d-flex align-items-center gap-2">
                <RotateCcw size={16} className="text-warning" />
                Recently Bumped / Prepared Tickets (Click to Recall)
              </h6>
              <div className="d-flex flex-wrap gap-2">
                {recalledTickets.map((r) => (
                  <div key={r.itemId} className="p-2 bg-card-custom rounded border border-custom d-flex align-items-center gap-3">
                    <div>
                      <span className="fw-bold text-main small d-block">{r.quantity}x {r.menuItemName}</span>
                      <span className="text-muted-custom text-xs">Table {r.tableNumber}</span>
                    </div>
                    <button className="btn btn-xs btn-outline-warning" onClick={() => handleRecallItem(r.itemId)}>
                      Recall
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* TAB 2: ASSIGNED STATION MENU ITEMS */}
      {activeTab === 'STATION_MENU' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <h6 className="fw-bold text-main mb-3">
            Menu Dishes Assigned to '{currentStation?.name || 'Station'}'
          </h6>
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Dish Name</th>
                  <th>Category</th>
                  <th>Dine-in Price</th>
                  <th>Food Type</th>
                  <th>Availability</th>
                </tr>
              </thead>
              <tbody>
                {assignedMenuItems.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="text-center py-4 text-muted-custom">
                      No menu dishes assigned to this kitchen station yet. Link dishes via the Menu Catalog page.
                    </td>
                  </tr>
                ) : (
                  assignedMenuItems.map((item) => (
                    <tr key={item.itemId || item.id}>
                      <td className="fw-bold text-main">{item.name}</td>
                      <td className="text-muted-custom small">{item.category?.name || 'General'}</td>
                      <td className="fw-bold text-danger">₹{item.price}</td>
                      <td><span className="badge bg-secondary text-white">{item.foodType || 'Starter'}</span></td>
                      <td>
                        <span className={`badge ${item.available !== false ? 'bg-success' : 'bg-danger'}`}>
                          {item.available !== false ? 'AVAILABLE' : '86\'d'}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 3: MANAGE KITCHEN STATIONS CONFIGURATION */}
      {activeTab === 'STATIONS_CONFIG' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h6 className="fw-bold text-main m-0">All Kitchen Cooking Stations ({stations.length})</h6>
            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowAddStationModal(true)}>
              + Add New Station
            </button>
          </div>

          <div className="row g-3">
            {stations.map((st) => (
              <div key={st.id} className="col-12 col-sm-6 col-md-4">
                <div className="card bg-surface border-custom shadow-sm p-3 d-flex flex-row align-items-center justify-content-between">
                  <div className="d-flex align-items-center gap-3">
                    <div className="p-3 bg-secondary bg-opacity-10 text-secondary-custom rounded-circle">
                      <Flame size={24} />
                    </div>
                    <div>
                      <h6 className="fw-bold text-main m-0">{st.name}</h6>
                      <span className="text-muted-custom small">Active Preparation Station</span>
                    </div>
                  </div>

                  <button className="btn btn-sm btn-outline-danger border-0" onClick={() => handleDeleteStation(st.id)}>
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL: ADD KITCHEN STATION FORM                            */}
      {/* ========================================================= */}
      {showAddStationModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Add Kitchen Preparation Station</h5>
                <button type="button" className="btn-close" onClick={() => setShowAddStationModal(false)}></button>
              </div>

              <form onSubmit={handleCreateStation}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">
                      Station Name (e.g. HOT KITCHEN, GRILL, PASTRY, BEVERAGE) *
                    </label>
                    <input
                      type="text"
                      className="form-control text-uppercase"
                      required
                      placeholder="e.g. GRILL STATION"
                      value={newStationName}
                      onChange={(e) => setNewStationName(e.target.value)}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddStationModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Save Station
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
