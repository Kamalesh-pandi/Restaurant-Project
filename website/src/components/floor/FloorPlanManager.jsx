import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  Grid, 
  Plus, 
  Users, 
  Edit, 
  Trash2, 
  Clock, 
  Move, 
  Layers, 
  RefreshCw, 
  CheckCircle2, 
  AlertTriangle, 
  Phone, 
  Search, 
  X, 
  UserCheck, 
  ArrowRightLeft, 
  Maximize2,
  Calendar,
  Sparkles,
  Utensils
} from 'lucide-react';

export default function FloorPlanManager({ showToast }) {
  // Data States
  const [tables, setTables] = useState([]);
  const [waitlist, setWaitlist] = useState([]);
  const [outlets, setOutlets] = useState([]);
  const [avgTurnTime, setAvgTurnTime] = useState(0);
  const [activeOrders, setActiveOrders] = useState([]);
  const [loading, setLoading] = useState(false);

  // Filters & Views
  const [selectedSection, setSelectedSection] = useState('ALL');
  const [selectedTable, setSelectedTable] = useState(null);
  const [viewMode, setViewMode] = useState('GRID'); // 'GRID' or 'CANVAS'
  const [activeTab, setActiveTab] = useState('FLOOR'); // 'FLOOR' or 'WAITLIST'

  // Modals
  const [showTableModal, setShowTableModal] = useState(false);
  const [editingTableId, setEditingTableId] = useState(null);
  const [tableForm, setTableForm] = useState({
    tableNumber: '',
    capacity: 4,
    section: 'Ground Floor',
    xPos: 0,
    yPos: 0,
    status: 'AVAILABLE',
    outletId: ''
  });

  const [showMergeModal, setShowMergeModal] = useState(false);
  const [primaryMergeTable, setPrimaryMergeTable] = useState(null);
  const [selectedSecondaryIds, setSelectedSecondaryIds] = useState([]);

  const [showTransferModal, setShowTransferModal] = useState(false);
  const [sourceTransferTable, setSourceTransferTable] = useState(null);
  const [destinationTransferId, setDestinationTransferId] = useState('');

  const [showWaitlistModal, setShowWaitlistModal] = useState(false);
  const [waitlistForm, setWaitlistForm] = useState({
    guestName: '',
    guestPhone: '',
    partySize: 2,
    outletId: ''
  });

  const [showCoversModal, setShowCoversModal] = useState(false);
  const [coversCount, setCoversCount] = useState(2);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [tblsRes, waitRes, outsRes, ordersRes, turnRes] = await Promise.all([
        apiRequest('/api/v1/tables').catch(() => []),
        apiRequest('/api/v1/waitlist').catch(() => []),
        apiRequest('/api/v1/chain/outlets').catch(() => []),
        apiRequest('/api/v1/orders').catch(() => []),
        apiRequest('/api/v1/tables/analytics/turn-time').catch(() => 0),
      ]);

      const tbls = Array.isArray(tblsRes) ? tblsRes : [];
      const wait = Array.isArray(waitRes) ? waitRes : [];
      const outs = Array.isArray(outsRes) ? outsRes : [];
      const ords = Array.isArray(ordersRes) ? ordersRes : [];

      setTables(tbls);
      setWaitlist(wait);
      setOutlets(outs);
      setActiveOrders(ords);
      setAvgTurnTime(typeof turnRes === 'number' ? turnRes : 0);

      if (outs.length > 0 && !tableForm.outletId) {
        setTableForm(prev => ({ ...prev, outletId: outs[0].id || outs[0].outletId }));
        setWaitlistForm(prev => ({ ...prev, outletId: outs[0].id || outs[0].outletId }));
      }
    } catch (err) {
      console.error('Error loading floor plan data:', err);
    } finally {
      setLoading(false);
    }
  };

  // Section lists derived dynamically
  const sections = ['ALL', ...Array.from(new Set(tables.map(t => t.section).filter(Boolean)))];

  // Save Table (Create / Edit)
  const handleSaveTable = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        tableNumber: tableForm.tableNumber.trim(),
        capacity: parseInt(tableForm.capacity) || 4,
        section: tableForm.section.trim(),
        xPos: parseInt(tableForm.xPos) || 0,
        yPos: parseInt(tableForm.yPos) || 0,
        status: tableForm.status || 'AVAILABLE',
        outletId: tableForm.outletId || (outlets[0]?.id || null)
      };

      if (editingTableId) {
        await apiRequest(`/api/v1/tables/${editingTableId}`, 'PUT', payload);
        if (showToast) showToast(`Table ${tableForm.tableNumber} updated!`, 'success');
      } else {
        await apiRequest('/api/v1/tables', 'POST', payload);
        if (showToast) showToast(`New table ${tableForm.tableNumber} created!`, 'success');
      }

      setShowTableModal(false);
      resetTableForm();
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to save table', 'error');
    }
  };

  const openAddTableModal = () => {
    setEditingTableId(null);
    setTableForm({
      tableNumber: `T-${tables.length + 1}`,
      capacity: 4,
      section: selectedSection === 'ALL' ? 'Ground Floor' : selectedSection,
      xPos: (tables.length % 5) * 150 + 20,
      yPos: Math.floor(tables.length / 5) * 150 + 20,
      status: 'AVAILABLE',
      outletId: outlets[0]?.id || ''
    });
    setShowTableModal(true);
  };

  const openEditTableModal = (tbl) => {
    setEditingTableId(tbl.tableId || tbl.id);
    setTableForm({
      tableNumber: tbl.tableNumber || '',
      capacity: tbl.capacity || 4,
      section: tbl.section || 'Ground Floor',
      xPos: tbl.xPos || 0,
      yPos: tbl.yPos || 0,
      status: tbl.status || 'AVAILABLE',
      outletId: tbl.outletId || ''
    });
    setShowTableModal(true);
  };

  const resetTableForm = () => {
    setEditingTableId(null);
    setTableForm({
      tableNumber: '',
      capacity: 4,
      section: 'Ground Floor',
      xPos: 0,
      yPos: 0,
      status: 'AVAILABLE',
      outletId: ''
    });
  };

  const handleDeleteTable = async (tableId) => {
    if (!window.confirm('Are you sure you want to delete this table?')) return;
    try {
      await apiRequest(`/api/v1/tables/${tableId}`, 'DELETE');
      if (showToast) showToast('Table deleted successfully', 'success');
      if (selectedTable?.tableId === tableId || selectedTable?.id === tableId) {
        setSelectedTable(null);
      }
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Delete failed', 'error');
    }
  };

  // Status Change (AVAILABLE, OCCUPIED, RESERVED, CLEANING)
  const handleUpdateStatus = async (tableId, newStatus) => {
    try {
      await apiRequest(`/api/v1/tables/${tableId}/status?status=${newStatus}`, 'PUT');
      if (showToast) showToast(`Table status changed to ${newStatus}`, 'info');
      fetchData();
      if (selectedTable && (selectedTable.tableId === tableId || selectedTable.id === tableId)) {
        setSelectedTable(prev => ({ ...prev, status: newStatus }));
      }
    } catch (err) {
      if (showToast) showToast(err.message || 'Status update failed', 'error');
    }
  };

  // Merge Tables Logic
  const openMergeModal = (primaryTbl) => {
    setPrimaryMergeTable(primaryTbl);
    setSelectedSecondaryIds([]);
    setShowMergeModal(true);
  };

  const handleExecuteMerge = async (e) => {
    e.preventDefault();
    if (!primaryMergeTable || selectedSecondaryIds.length === 0) return;
    const pId = primaryMergeTable.tableId || primaryMergeTable.id;
    try {
      await apiRequest(`/api/v1/tables/merge?primaryTableId=${pId}`, 'POST', selectedSecondaryIds);
      if (showToast) showToast(`Tables merged into Table ${primaryMergeTable.tableNumber}!`, 'success');
      setShowMergeModal(false);
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Merge failed', 'error');
    }
  };

  const handleUnmerge = async (primaryTableId) => {
    try {
      await apiRequest(`/api/v1/tables/unmerge?primaryTableId=${primaryTableId}`, 'POST');
      if (showToast) showToast('Merged secondary tables released!', 'success');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Unmerge failed', 'error');
    }
  };

  // Transfer Table Logic
  const openTransferModal = (sourceTbl) => {
    setSourceTransferTable(sourceTbl);
    setDestinationTransferId('');
    setShowTransferModal(true);
  };

  const handleExecuteTransfer = async (e) => {
    e.preventDefault();
    if (!sourceTransferTable || !destinationTransferId) return;
    const sId = sourceTransferTable.tableId || sourceTransferTable.id;
    try {
      await apiRequest(`/api/v1/tables/transfer?sourceTableId=${sId}&destinationTableId=${destinationTransferId}`, 'POST');
      if (showToast) showToast('Order transferred to destination table successfully!', 'success');
      setShowTransferModal(false);
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Transfer failed', 'error');
    }
  };

  // Covers / Guest Count Logic
  const handleUpdateCovers = async (e) => {
    e.preventDefault();
    if (!selectedTable) return;
    const tId = selectedTable.tableId || selectedTable.id;
    try {
      await apiRequest(`/api/v1/tables/${tId}/covers?count=${parseInt(coversCount) || 1}`, 'PUT');
      if (showToast) showToast(`Guest covers count updated to ${coversCount}!`, 'success');
      setShowCoversModal(false);
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Covers update failed', 'error');
    }
  };

  // Waitlist Operations
  const handleAddWaitlist = async (e) => {
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
      if (showToast) showToast(err.message || 'Failed to add to waitlist', 'error');
    }
  };

  const handleSeatWaitlist = async (waitlistId, tableId) => {
    try {
      await apiRequest(`/api/v1/waitlist/${waitlistId}/seat?tableId=${tableId}`, 'PUT');
      if (showToast) showToast('Waitlist guest seated at table!', 'success');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Seating failed', 'error');
    }
  };

  const handleCancelWaitlist = async (waitlistId) => {
    try {
      await apiRequest(`/api/v1/waitlist/${waitlistId}/cancel`, 'PUT');
      if (showToast) showToast('Waitlist entry cancelled', 'info');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Cancel failed', 'error');
    }
  };

  // Canvas Layout Save (Bulk Update)
  const handleSaveCanvasPositions = async () => {
    try {
      await apiRequest('/api/v1/tables/bulk', 'PUT', tables);
      if (showToast) showToast('Floor plan layout positions saved!', 'success');
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to save layout', 'error');
    }
  };

  // Filtered Tables
  const filteredTables = tables.filter(t => selectedSection === 'ALL' || t.section === selectedSection);

  // Status helper color
  const getStatusBadge = (status) => {
    switch (status) {
      case 'OCCUPIED': return 'bg-danger text-white';
      case 'RESERVED': return 'bg-primary text-white';
      case 'CLEANING': return 'bg-warning text-dark';
      default: return 'bg-success text-white';
    }
  };

  // Find linked order for table
  const getActiveOrderForTable = (tbl) => {
    if (!tbl) return null;
    const tId = tbl.tableId || tbl.id;
    const orderId = tbl.currentOrderId;
    return activeOrders.find(o => o.orderId === orderId || o.id === orderId || o.tableId === tId);
  };

  return (
    <div className="floor-plan-container">
      {/* Top Header & Analytics Summary Bar */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <Grid size={20} className="text-secondary-custom" />
              Floor Plan & Host Stand Control
            </h5>
            <span className="text-muted-custom small">
              Real-time table occupancy, table merging, order transfer, guest turn-time & waitlist SMS alerts
            </span>
          </div>

          {/* Action Buttons */}
          <div className="d-flex flex-wrap gap-2">
            <div className="btn-group">
              <button
                className={`btn btn-sm ${activeTab === 'FLOOR' ? 'btn-secondary fw-bold' : 'btn-outline-secondary'}`}
                onClick={() => setActiveTab('FLOOR')}
              >
                <Grid size={15} className="me-1" /> Floor Layout
              </button>
              <button
                className={`btn btn-sm ${activeTab === 'WAITLIST' ? 'btn-secondary fw-bold' : 'btn-outline-secondary'}`}
                onClick={() => setActiveTab('WAITLIST')}
              >
                <Users size={15} className="me-1" /> Waitlist ({waitlist.length})
              </button>
            </div>

            {activeTab === 'FLOOR' && (
              <div className="btn-group me-2">
                <button
                  className={`btn btn-sm ${viewMode === 'GRID' ? 'btn-primary' : 'btn-outline-secondary'}`}
                  onClick={() => setViewMode('GRID')}
                >
                  Grid View
                </button>
                <button
                  className={`btn btn-sm ${viewMode === 'CANVAS' ? 'btn-primary' : 'btn-outline-secondary'}`}
                  onClick={() => setViewMode('CANVAS')}
                >
                  Interactive Canvas
                </button>
              </div>
            )}

            {viewMode === 'CANVAS' && (
              <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={handleSaveCanvasPositions}>
                <Move size={14} className="me-1" /> Save Layout
              </button>
            )}

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowWaitlistModal(true)}>
              <Plus size={14} className="me-1 text-danger" /> Add Waitlist Guest
            </button>

            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={openAddTableModal}>
              <Plus size={14} className="me-1" /> Add New Table
            </button>
          </div>
        </div>

        {/* Analytics & Metrics Strip */}
        <div className="row g-3 mt-2 pt-2 border-top border-custom align-items-center">
          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
              <span className="small text-muted-custom">Total Tables:</span>
              <span className="fw-bold text-main">{tables.length}</span>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
              <span className="small text-muted-custom">Occupancy Rate:</span>
              <span className="fw-bold text-danger">
                {tables.length > 0 ? Math.round((tables.filter(t => t.status === 'OCCUPIED').length / tables.length) * 100) : 0}%
              </span>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
              <span className="small text-muted-custom">Avg Turn Time:</span>
              <span className="fw-bold text-secondary-custom">{avgTurnTime ? avgTurnTime.toFixed(1) : 0} mins</span>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom d-flex justify-content-between align-items-center">
              <span className="small text-muted-custom">Waiting Guests:</span>
              <span className="fw-bold text-warning">{waitlist.filter(w => w.status === 'WAITING').length} Parties</span>
            </div>
          </div>
        </div>
      </div>

      {/* TAB 1: FLOOR LAYOUT */}
      {activeTab === 'FLOOR' && (
        <div className="row g-4">
          {/* Main Floor Area */}
          <div className="col-12 col-lg-8 col-xl-9">
            <div className="card bg-surface border-custom shadow-sm p-3">
              {/* Section Filters */}
              <div className="d-flex justify-content-between align-items-center mb-3">
                <div className="d-flex gap-2 overflow-auto pb-1">
                  {sections.map((sec) => (
                    <button
                      key={sec}
                      className={`btn btn-sm rounded-pill px-3 text-nowrap ${selectedSection === sec ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
                      onClick={() => setSelectedSection(sec)}
                    >
                      {sec === 'ALL' ? 'All Sections' : sec}
                    </button>
                  ))}
                </div>

                {/* Legend */}
                <div className="d-none d-md-flex gap-3 small text-muted-custom">
                  <span className="d-flex align-items-center gap-1"><span className="rounded-circle bg-success" style={{ width: '10px', height: '10px' }}></span> Available</span>
                  <span className="d-flex align-items-center gap-1"><span className="rounded-circle bg-danger" style={{ width: '10px', height: '10px' }}></span> Occupied</span>
                  <span className="d-flex align-items-center gap-1"><span className="rounded-circle bg-primary" style={{ width: '10px', height: '10px' }}></span> Reserved</span>
                  <span className="d-flex align-items-center gap-1"><span className="rounded-circle bg-warning" style={{ width: '10px', height: '10px' }}></span> Cleaning</span>
                </div>
              </div>

              {/* View Mode: Grid View */}
              {viewMode === 'GRID' && (
                <div className="row g-3" style={{ minHeight: '400px' }}>
                  {loading ? (
                    <div className="text-center py-5">
                      <div className="spinner-border text-danger" role="status"></div>
                    </div>
                  ) : filteredTables.length === 0 ? (
                    <div className="text-center py-5 text-muted-custom">No tables found in this section.</div>
                  ) : (
                    filteredTables.map((tbl) => {
                      const tId = tbl.tableId || tbl.id;
                      const isSelected = selectedTable && (selectedTable.tableId === tId || selectedTable.id === tId);
                      const isMergedSecondary = Boolean(tbl.parentTableId);

                      return (
                        <div key={tId} className="col-6 col-sm-4 col-md-3 col-xl-2">
                          <div
                            className={`card touch-card p-3 text-center border transition-all position-relative cursor-pointer ${
                              isSelected ? 'border-danger shadow-lg bg-secondary-light' : 'bg-surface border-custom'
                            }`}
                            onClick={() => setSelectedTable(tbl)}
                          >
                            {isMergedSecondary && (
                              <span className="position-absolute top-0 start-0 m-1 badge bg-dark text-white text-xs">
                                <Layers size={10} className="me-1" /> Merged
                              </span>
                            )}

                            <h5 className="fw-bold text-main m-0">{tbl.tableNumber}</h5>
                            <span className="text-muted-custom small d-block my-1">{tbl.capacity} Seats</span>
                            <span className={`badge ${getStatusBadge(tbl.status)} small`}>
                              {tbl.status || 'AVAILABLE'}
                            </span>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              )}

              {/* View Mode: Interactive Canvas */}
              {viewMode === 'CANVAS' && (
                <div
                  className="position-relative bg-card-custom rounded-3 border border-custom p-3 overflow-auto"
                  style={{ minHeight: '500px', height: '600px', backgroundImage: 'radial-gradient(var(--border-color) 1px, transparent 0)', backgroundSize: '24px 24px' }}
                >
                  {filteredTables.map((tbl) => {
                    const tId = tbl.tableId || tbl.id;
                    const isSelected = selectedTable && (selectedTable.tableId === tId || selectedTable.id === tId);

                    return (
                      <div
                        key={tId}
                        className={`position-absolute p-3 rounded-3 shadow-sm text-center cursor-move border transition-all ${
                          isSelected ? 'border-danger shadow-lg bg-secondary-light' : 'bg-surface border-custom'
                        }`}
                        style={{
                          left: `${tbl.xPos || 20}px`,
                          top: `${tbl.yPos || 20}px`,
                          width: '120px',
                          height: '110px'
                        }}
                        onClick={() => setSelectedTable(tbl)}
                      >
                        <span className={`badge ${getStatusBadge(tbl.status)} position-absolute top-0 end-0 m-1 text-xs`}>
                          {tbl.status || 'AV'}
                        </span>
                        <h6 className="fw-bold text-main m-0 mt-2">{tbl.tableNumber}</h6>
                        <span className="text-muted-custom small d-block">{tbl.capacity} Seats</span>
                        <span className="text-muted-custom text-xs d-block">{tbl.section}</span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Right Control Drawer: Selected Table Details & Actions */}
          <div className="col-12 col-lg-4 col-xl-3">
            <div className="card bg-surface border-custom shadow-sm p-3 h-100 d-flex flex-column justify-content-between">
              {selectedTable ? (
                <div>
                  <div className="d-flex justify-content-between align-items-center mb-2">
                    <h5 className="fw-bold text-main m-0">Table {selectedTable.tableNumber}</h5>
                    <span className={`badge ${getStatusBadge(selectedTable.status)}`}>
                      {selectedTable.status || 'AVAILABLE'}
                    </span>
                  </div>

                  <p className="text-muted-custom small mb-3">
                    Section: <strong>{selectedTable.section || 'Main Floor'}</strong> • Capacity: <strong>{selectedTable.capacity} Persons</strong>
                  </p>

                  {/* Active Order Details */}
                  {selectedTable.status === 'OCCUPIED' && (
                    <div className="p-3 bg-card-custom rounded-3 border border-custom mb-3">
                      <span className="text-muted-custom small fw-semibold d-block mb-1">
                        ACTIVE ORDER: #{selectedTable.currentOrderId ? String(selectedTable.currentOrderId).substring(0, 6) : 'LIVE'}
                      </span>
                      {getActiveOrderForTable(selectedTable) && (
                        <div className="d-flex justify-content-between align-items-center fw-bold text-main my-1">
                          <span>Total Amount:</span>
                          <span className="text-danger">₹{getActiveOrderForTable(selectedTable).totalAmount || 0}</span>
                        </div>
                      )}
                      <div className="d-flex justify-content-between align-items-center border-top border-custom pt-2 mt-2">
                        <span className="small text-muted-custom">Guest Covers:</span>
                        <button className="btn btn-sm btn-outline-secondary py-0 px-2 text-xs" onClick={() => setShowCoversModal(true)}>
                          {getActiveOrderForTable(selectedTable)?.covers || selectedTable.capacity} Guests (Edit)
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Status Toggle Buttons */}
                  <h6 className="fw-bold text-main mb-2">Update Table Status</h6>
                  <div className="row g-2 mb-3">
                    {['AVAILABLE', 'OCCUPIED', 'RESERVED', 'CLEANING'].map((st) => (
                      <div key={st} className="col-6">
                        <button
                          className={`btn btn-sm w-100 text-nowrap ${selectedTable.status === st ? 'btn-secondary fw-bold' : 'btn-outline-secondary'}`}
                          onClick={() => handleUpdateStatus(selectedTable.tableId || selectedTable.id, st)}
                        >
                          {st}
                        </button>
                      </div>
                    ))}
                  </div>

                  {/* Operations (Merge, Transfer, Edit, Delete) */}
                  <h6 className="fw-bold text-main mb-2">Table Operations</h6>
                  <div className="d-flex flex-column gap-2 mb-3">
                    {selectedTable.status === 'OCCUPIED' && (
                      <button className="btn btn-outline-secondary w-100 touch-btn btn-sm text-start" onClick={() => openTransferModal(selectedTable)}>
                        <ArrowRightLeft size={14} className="me-2 text-danger" /> Transfer Order to Other Table
                      </button>
                    )}

                    {selectedTable.parentTableId ? (
                      <button className="btn btn-outline-danger w-100 touch-btn btn-sm text-start" onClick={() => handleUnmerge(selectedTable.parentTableId)}>
                        <Layers size={14} className="me-2" /> Unmerge from Parent Table
                      </button>
                    ) : (
                      <button className="btn btn-outline-secondary w-100 touch-btn btn-sm text-start" onClick={() => openMergeModal(selectedTable)}>
                        <Layers size={14} className="me-2 text-primary" /> Merge Tables
                      </button>
                    )}

                    <button className="btn btn-outline-secondary w-100 touch-btn btn-sm text-start" onClick={() => openEditTableModal(selectedTable)}>
                      <Edit size={14} className="me-2" /> Edit Table Settings
                    </button>

                    <button className="btn btn-outline-danger w-100 touch-btn btn-sm text-start" onClick={() => handleDeleteTable(selectedTable.tableId || selectedTable.id)}>
                      <Trash2 size={14} className="me-2" /> Delete Table
                    </button>
                  </div>
                </div>
              ) : (
                <div className="text-center py-5 text-muted-custom my-auto">
                  <Grid size={40} className="mb-2 opacity-50" />
                  <p className="small">Select a table on floor plan to view order details & status actions.</p>
                </div>
              )}

              {selectedTable && (
                <button className="btn btn-outline-secondary w-100 touch-btn mt-auto" onClick={() => setSelectedTable(null)}>
                  Close Table Panel
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: WAITLIST MANAGEMENT */}
      {activeTab === 'WAITLIST' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h6 className="fw-bold text-main m-0">Host Stand Waiting List ({waitlist.length})</h6>
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
                  <th>Seat Action</th>
                </tr>
              </thead>
              <tbody>
                {waitlist.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="text-center py-4 text-muted-custom">No guests currently waiting on waitlist.</td>
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
                                style={{ width: '150px' }}
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
                            <span className="text-muted-custom small">Completed</span>
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
      {/* MODAL 1: ADD / EDIT TABLE FORM                             */}
      {/* ========================================================= */}
      {showTableModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">
                  {editingTableId ? 'Edit Table Settings' : 'Create New Table'}
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowTableModal(false)}></button>
              </div>

              <form onSubmit={handleSaveTable}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Table Number / Label *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. T-01, VIP-02"
                      value={tableForm.tableNumber}
                      onChange={(e) => setTableForm({ ...tableForm, tableNumber: e.target.value })}
                    />
                  </div>

                  <div className="row g-3 mb-3">
                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">Seating Capacity *</label>
                      <input
                        type="number"
                        min="1"
                        className="form-control"
                        required
                        value={tableForm.capacity}
                        onChange={(e) => setTableForm({ ...tableForm, capacity: e.target.value })}
                      />
                    </div>

                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">Section / Floor *</label>
                      <input
                        type="text"
                        className="form-control"
                        required
                        placeholder="e.g. Ground Floor, Terrace"
                        value={tableForm.section}
                        onChange={(e) => setTableForm({ ...tableForm, section: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Initial Status</label>
                    <select
                      className="form-select"
                      value={tableForm.status}
                      onChange={(e) => setTableForm({ ...tableForm, status: e.target.value })}
                    >
                      <option value="AVAILABLE">AVAILABLE (Green)</option>
                      <option value="OCCUPIED">OCCUPIED (Red)</option>
                      <option value="RESERVED">RESERVED (Blue)</option>
                      <option value="CLEANING">CLEANING (Yellow)</option>
                    </select>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowTableModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    {editingTableId ? 'Save Changes' : 'Create Table'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: MERGE TABLES                                      */}
      {/* ========================================================= */}
      {showMergeModal && primaryMergeTable && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <Layers size={20} className="text-secondary-custom" />
                  Merge Tables into Table {primaryMergeTable.tableNumber}
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowMergeModal(false)}></button>
              </div>

              <form onSubmit={handleExecuteMerge}>
                <div className="modal-body">
                  <p className="text-muted-custom small mb-3">
                    Select secondary available tables to combine with <strong>Table {primaryMergeTable.tableNumber}</strong> for large party seating:
                  </p>

                  <div className="d-flex flex-column gap-2 max-vh-50 overflow-auto">
                    {tables
                      .filter(t => (t.tableId || t.id) !== (primaryMergeTable.tableId || primaryMergeTable.id) && t.status === 'AVAILABLE')
                      .map((t) => {
                        const tId = t.tableId || t.id;
                        const isChecked = selectedSecondaryIds.includes(tId);

                        return (
                          <div
                            key={tId}
                            className={`p-3 rounded-3 border border-custom cursor-pointer d-flex justify-content-between align-items-center ${
                              isChecked ? 'bg-secondary-light border-danger' : 'bg-card-custom'
                            }`}
                            onClick={() => {
                              setSelectedSecondaryIds(prev =>
                                isChecked ? prev.filter(x => x !== tId) : [...prev, tId]
                              );
                            }}
                          >
                            <div>
                              <span className="fw-bold text-main d-block">Table {t.tableNumber}</span>
                              <span className="text-muted-custom small">{t.section} • {t.capacity} Seats</span>
                            </div>
                            <input type="checkbox" className="form-check-input" checked={isChecked} readOnly />
                          </div>
                        );
                      })}
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowMergeModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4" disabled={selectedSecondaryIds.length === 0}>
                    Confirm Merge ({selectedSecondaryIds.length} Secondary Tables)
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 3: TRANSFER ORDER TO OTHER TABLE                    */}
      {/* ========================================================= */}
      {showTransferModal && sourceTransferTable && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <ArrowRightLeft size={20} className="text-danger" />
                  Transfer Table {sourceTransferTable.tableNumber} Order
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowTransferModal(false)}></button>
              </div>

              <form onSubmit={handleExecuteTransfer}>
                <div className="modal-body">
                  <p className="text-main mb-2">
                    Relocate guests and active bill from <strong>Table {sourceTransferTable.tableNumber}</strong>.
                  </p>

                  <label className="form-label text-muted-custom small fw-semibold">Select Destination Available Table *</label>
                  <select
                    className="form-select border-custom"
                    required
                    value={destinationTransferId}
                    onChange={(e) => setDestinationTransferId(e.target.value)}
                  >
                    <option value="">-- Choose Target Table --</option>
                    {tables
                      .filter(t => (t.tableId || t.id) !== (sourceTransferTable.tableId || sourceTransferTable.id) && t.status === 'AVAILABLE')
                      .map((t) => (
                        <option key={t.tableId || t.id} value={t.tableId || t.id}>
                          Table {t.tableNumber} ({t.section} - {t.capacity} Seats)
                        </option>
                      ))}
                  </select>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowTransferModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-danger fw-bold px-4" disabled={!destinationTransferId}>
                    Execute Transfer
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 4: ADD WAITLIST GUEST FORM                          */}
      {/* ========================================================= */}
      {showWaitlistModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Add Guest to Waitlist</h5>
                <button type="button" className="btn-close" onClick={() => setShowWaitlistModal(false)}></button>
              </div>

              <form onSubmit={handleAddWaitlist}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Guest Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Ananya Sharma"
                      value={waitlistForm.guestName}
                      onChange={(e) => setWaitlistForm({ ...waitlistForm, guestName: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Mobile Phone (for SMS Notification) *</label>
                    <input
                      type="tel"
                      className="form-control"
                      required
                      placeholder="+91 9876543210"
                      value={waitlistForm.guestPhone}
                      onChange={(e) => setWaitlistForm({ ...waitlistForm, guestPhone: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Party Size (Number of Guests) *</label>
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

      {/* ========================================================= */}
      {/* MODAL 5: UPDATE COVERS COUNT                              */}
      {/* ========================================================= */}
      {showCoversModal && selectedTable && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Update Guest Covers (Table {selectedTable.tableNumber})</h5>
                <button type="button" className="btn-close" onClick={() => setShowCoversModal(false)}></button>
              </div>

              <form onSubmit={handleUpdateCovers}>
                <div className="modal-body">
                  <label className="form-label text-muted-custom small fw-semibold">Number of Guest Covers *</label>
                  <input
                    type="number"
                    min="1"
                    className="form-control"
                    required
                    value={coversCount}
                    onChange={(e) => setCoversCount(e.target.value)}
                  />
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowCoversModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Save Covers
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
