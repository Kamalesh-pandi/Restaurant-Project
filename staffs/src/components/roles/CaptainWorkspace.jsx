import React, { useState, useEffect, useCallback } from 'react';
import { apiRequest } from '../../services/apiClient';
import { useAuth } from '../../context/AuthContext';
import { wsService } from '../../services/websocketService';
import { playOrderChime } from '../../services/audioService';
import {
  Grid, Utensils, Plus, Search, RefreshCw, X, ChevronDown,
  CheckCircle2, ShoppingBag, Users,
} from 'lucide-react';

export default function CaptainWorkspace() {
  const { showToast } = useAuth();

  const [tables, setTables]         = useState([]);
  const [selectedTable, setSelectedTable] = useState(null);
  const [tableOrder, setTableOrder] = useState(null);
  const [categories, setCategories] = useState([]);
  const [menuItems, setMenuItems]   = useState([]);
  const [loading, setLoading]       = useState(false);

  // Order builder
  const [showOrderModal, setShowOrderModal] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('ALL');
  const [menuSearch, setMenuSearch] = useState('');
  const [orderItems, setOrderItems] = useState([]);
  const [guestCount, setGuestCount] = useState(1);
  const [orderNote, setOrderNote]   = useState('');

  // Table creation
  const [showAddTableModal, setShowAddTableModal] = useState(false);
  const [newTable, setNewTable] = useState({ tableNumber: '', capacity: 4, section: 'Main Hall', seatingType: 'Standard' });

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [tbls, cats, items] = await Promise.all([
        apiRequest('/api/v1/tables').catch(() => []),
        apiRequest('/api/v1/menu/categories').catch(() => []),
        apiRequest('/api/v1/menu/items').catch(() => []),
      ]);
      setTables(Array.isArray(tbls)  ? tbls  : []);
      setCategories(Array.isArray(cats)  ? cats  : []);
      setMenuItems(Array.isArray(items) ? items : []);
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => {
    fetchData();
    const u1 = wsService.subscribe('/topic/tables', (updated) => {
      setTables(prev => prev.map(t => (t.tableId || t.id) === (updated.tableId || updated.id) ? updated : t));
      if (selectedTable && (selectedTable.tableId || selectedTable.id) === (updated.tableId || updated.id)) setSelectedTable(updated);
    });
    const u2 = wsService.subscribe('/topic/orders', () => fetchData());
    return () => { u1(); u2(); };
  }, [fetchData, selectedTable]);

  const handleSelectTable = async (tbl) => {
    setSelectedTable(tbl);
    setTableOrder(null);
    const tId = tbl.tableId || tbl.id;
    try {
      const ords = await apiRequest('/api/v1/orders').catch(() => []);
      const found = Array.isArray(ords)
        ? ords.find(o => (o.tableId === tId || (tbl.currentOrderId && (o.orderId === tbl.currentOrderId || o.id === tbl.currentOrderId))) && ['NEW','PREPARING','READY','SERVED'].includes(o.status))
        : null;

      if (found) {
        const orderId = found.orderId || found.id;
        const rawItems = await apiRequest(`/api/v1/orders/${orderId}/items`).catch(() => []);
        const menuMap = {};
        menuItems.forEach(m => { menuMap[m.itemId || m.id] = m; });
        const items = (Array.isArray(rawItems) ? rawItems : []).map(it => ({
          ...it,
          itemName: it.itemName || menuMap[it.menuItemId]?.name || 'Menu Item',
          price: it.unitPrice ?? menuMap[it.menuItemId]?.price ?? 0,
          quantity: it.quantity || 1
        }));
        const total = items.reduce((acc, i) => acc + (i.price * i.quantity), 0);
        setTableOrder({
          ...found,
          items,
          total: (found.totalAmount != null && found.totalAmount > 0) ? Number(found.totalAmount) : total
        });
      } else {
        setTableOrder(null);
      }
    } catch (err) { console.error(err); }
  };

  const handleOpenOrderModal = () => {
    setOrderItems([]);
    setGuestCount(1);
    setOrderNote('');
    setSelectedCategory('ALL');
    setMenuSearch('');
    setShowOrderModal(true);
  };

  const handleAddItem = (item) => {
    const id = item.itemId || item.id;
    setOrderItems(prev => {
      const exists = prev.find(i => i.itemId === id);
      if (exists) return prev.map(i => i.itemId === id ? { ...i, quantity: i.quantity + 1 } : i);
      return [...prev, { itemId: id, name: item.name, price: item.price, quantity: 1 }];
    });
  };

  const handleRemoveItem = (itemId) => {
    setOrderItems(prev => prev.filter(i => i.itemId !== itemId));
  };

  const handleAdjustQty = (itemId, delta) => {
    setOrderItems(prev => prev
      .map(i => i.itemId === itemId ? { ...i, quantity: Math.max(1, i.quantity + delta) } : i)
    );
  };

  const handleSubmitOrder = async () => {
    if (!selectedTable) return showToast('Select a table first', 'warning');
    if (orderItems.length === 0) return showToast('Add at least one item', 'warning');
    const tId = selectedTable.tableId || selectedTable.id;
    try {
      await apiRequest('/api/v1/orders', 'POST', {
        order: {
          tableId: tId,
          orderType: 'DINE_IN',
          covers: guestCount || 1,
          deliveryNotes: orderNote || '',
          status: 'PREPARING',
          isTraining: false,
        },
        items: orderItems.map(i => ({
          menuItemId: i.itemId,
          quantity: i.quantity,
          unitPrice: i.price,
          status: 'PREPARING',
          isComplimentary: false,
        })),
      });
      playOrderChime();
      showToast(`Order sent to kitchen for ${selectedTable.tableNumber}! 🔥`, 'success');
      setShowOrderModal(false);
      fetchData();
      handleSelectTable(selectedTable);
    } catch (err) { showToast(err.message || 'Failed to place order', 'error'); }
  };

  const handleAddTable = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/tables', 'POST', {
        tableNumber: newTable.tableNumber,
        capacity: parseInt(newTable.capacity) || 4,
        section: newTable.section,
        seatingType: newTable.seatingType,
        status: 'AVAILABLE',
      });
      showToast(`Table ${newTable.tableNumber} added!`, 'success');
      setShowAddTableModal(false);
      setNewTable({ tableNumber: '', capacity: 4, section: 'Main Hall', seatingType: 'Standard' });
      fetchData();
    } catch (err) { showToast(err.message || 'Failed to add table', 'error'); }
  };

  const filteredItems = menuItems.filter(i => {
    const catMatch  = selectedCategory === 'ALL' || i.categoryId === selectedCategory || i.categoryName === selectedCategory;
    const nameMatch = (i.name || '').toLowerCase().includes(menuSearch.toLowerCase());
    const available = i.isAvailable !== false;
    return catMatch && nameMatch && available;
  });

  const orderTotal = orderItems.reduce((acc, i) => acc + i.price * i.quantity, 0);

  const statusColor = { AVAILABLE: '#10b981', OCCUPIED: '#ef4444', BILLING: '#f59e0b', RESERVED: '#8b5cf6' };
  const statusDot   = { AVAILABLE: 'dot-available', OCCUPIED: 'dot-occupied', BILLING: 'dot-billing', RESERVED: 'dot-reserved' };

  return (
    <div className="d-flex gap-3 fade-in" style={{ minHeight: 'calc(100vh - 140px)' }}>
      {/* LEFT: Floor Map */}
      <div style={{ width: '340px', flexShrink: 0 }}>
        <div className="card p-3 h-100">
          <div className="d-flex align-items-center justify-content-between mb-3">
            <div className="d-flex align-items-center gap-2">
              <Grid size={17} className="text-blue" />
              <span className="fw-bold text-main">Floor Plan</span>
            </div>
            <div className="d-flex gap-1">
              <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setShowAddTableModal(true)}>
                <Plus size={13} />
              </button>
              <button className="btn btn-sm btn-outline-secondary border-custom" onClick={fetchData} disabled={loading}>
                <RefreshCw size={13} className={loading ? 'spin' : ''} />
              </button>
            </div>
          </div>

          {/* Status Legend */}
          <div className="d-flex flex-wrap gap-2 mb-3">
            {Object.entries(statusColor).map(([s, c]) => (
              <div key={s} className="d-flex align-items-center gap-1">
                <span style={{ width: 8, height: 8, borderRadius: '50%', background: c, display: 'inline-block' }} />
                <span className="text-muted-custom" style={{ fontSize: '0.65rem' }}>{s}</span>
              </div>
            ))}
          </div>

          <div className="overflow-auto" style={{ maxHeight: 'calc(100vh - 280px)' }}>
            <div className="row g-2">
              {tables.map((t) => {
                const tId = t.tableId || t.id;
                const status = (t.status || 'AVAILABLE').toUpperCase();
                const isSelected = (selectedTable?.tableId || selectedTable?.id) === tId;
                return (
                  <div key={tId} className="col-6">
                    <div
                      className={`table-card p-2 text-center ${status.toLowerCase()} ${isSelected ? 'selected' : ''}`}
                      onClick={() => handleSelectTable(t)}
                    >
                      <div className="fw-bold text-main" style={{ fontSize: '1rem' }}>{t.tableNumber}</div>
                      <div style={{ margin: '3px 0' }}>
                        <span className={`table-status-dot ${statusDot[status] || 'dot-available'}`} />
                      </div>
                      <div className="text-muted-custom" style={{ fontSize: '0.65rem' }}>{status}</div>
                      <div className="text-muted-custom" style={{ fontSize: '0.6rem' }}>
                        <Users size={9} className="me-1" />{t.capacity}
                      </div>
                    </div>
                  </div>
                );
              })}
              {tables.length === 0 && <div className="col-12 text-center text-muted-custom py-3">No tables</div>}
            </div>
          </div>
        </div>
      </div>

      {/* RIGHT: Table Detail / Order Panel */}
      <div className="flex-grow-1">
        {!selectedTable ? (
          <div className="card p-5 text-center h-100 d-flex align-items-center justify-content-center">
            <Grid size={48} className="text-muted-custom mb-3" style={{ opacity: 0.3 }} />
            <h6 className="text-muted-custom fw-semibold">Select a table to take orders</h6>
          </div>
        ) : (
          <div className="card p-4">
            <div className="d-flex justify-content-between align-items-center mb-4">
              <div>
                <h5 className="fw-extrabold text-main mb-0">Table {selectedTable.tableNumber}</h5>
                <span className="text-muted-custom small">{selectedTable.section} · {selectedTable.status}</span>
              </div>
              {(selectedTable.status === 'AVAILABLE' || selectedTable.status === 'OCCUPIED') && (
                <button id="take-order-btn" className="btn btn-blue touch-btn" onClick={handleOpenOrderModal}>
                  <Plus size={15} className="me-1" /> Take Order
                </button>
              )}
            </div>

            {tableOrder ? (
              <div>
                <div className="d-flex justify-content-between align-items-center mb-3">
                  <h6 className="fw-bold text-main mb-0">Active Order</h6>
                  <span className={`badge ${tableOrder.status === 'READY' ? 'bg-success' : tableOrder.status === 'PREPARING' ? 'bg-warning text-dark' : 'bg-secondary'}`}>
                    {tableOrder.status}
                  </span>
                </div>
                <div className="card p-0 overflow-hidden">
                  {(tableOrder.items || []).map((item, i) => (
                    <div key={i} className="billing-item-row">
                      <div>
                        <span className="text-main fw-semibold small">{item.itemName || item.name}</span>
                        <span className="badge bg-secondary ms-2" style={{ fontSize: '0.65rem' }}>{item.status || 'PENDING'}</span>
                      </div>
                      <div className="d-flex align-items-center gap-2">
                        <span className="text-muted-custom small">× {item.quantity || 1}</span>
                        <span className="text-main small fw-semibold">₹{((item.price || 0) * (item.quantity || 1)).toFixed(0)}</span>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="text-end mt-2 fw-bold text-blue">Total: ₹{(tableOrder.total || 0).toFixed(0)}</div>
              </div>
            ) : (
              <div className="text-center py-5 text-muted-custom">
                <ShoppingBag size={36} style={{ opacity: 0.3 }} className="mb-2" />
                <div>No active order. Tap "Take Order" to start.</div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* ── ORDER MODAL ── */}
      {showOrderModal && (
        <div className="modal-backdrop-custom" onClick={() => setShowOrderModal(false)}>
          <div className="modal-box wide" style={{ maxWidth: 760 }} onClick={e => e.stopPropagation()}>
            <div className="p-4 border-bottom border-custom d-flex justify-content-between align-items-center">
              <h6 className="fw-bold text-main m-0">Take Order — Table {selectedTable?.tableNumber}</h6>
              <button className="btn-close" onClick={() => setShowOrderModal(false)} />
            </div>
            <div className="p-4">
              <div className="row g-3">
                {/* Left: Menu */}
                <div className="col-12 col-md-7">
                  <div className="mb-2">
                    <label className="form-label text-muted-custom small fw-semibold">Guest Count</label>
                    <input type="number" min={1} className="form-control form-control-sm" style={{ maxWidth: 100 }} value={guestCount} onChange={e => setGuestCount(Number(e.target.value))} />
                  </div>

                  {/* Category filter */}
                  <div className="d-flex gap-2 mb-2 flex-wrap">
                    <button className={`btn btn-sm touch-btn ${selectedCategory === 'ALL' ? 'btn-blue' : 'btn-outline-secondary border-custom text-main'}`} onClick={() => setSelectedCategory('ALL')}>All</button>
                    {categories.map(c => (
                      <button key={c.id} className={`btn btn-sm touch-btn ${selectedCategory === c.id ? 'btn-blue' : 'btn-outline-secondary border-custom text-main'}`} onClick={() => setSelectedCategory(c.id)}>
                        {c.name}
                      </button>
                    ))}
                  </div>

                  {/* Search */}
                  <div className="position-relative mb-2">
                    <Search size={13} className="position-absolute text-muted-custom" style={{ left: 10, top: 9 }} />
                    <input className="form-control form-control-sm ps-5" placeholder="Search menu..." value={menuSearch} onChange={e => setMenuSearch(e.target.value)} />
                  </div>

                  {/* Items */}
                  <div className="overflow-auto" style={{ maxHeight: 300 }}>
                    <div className="row g-2">
                      {filteredItems.map(item => (
                        <div key={item.id} className="col-6">
                          <div
                            className="card p-2 cursor-pointer"
                            style={{ cursor: 'pointer' }}
                            onClick={() => handleAddItem(item)}
                          >
                            <div className="fw-semibold text-main small">{item.name}</div>
                            <div className="text-blue fw-bold small">₹{item.price}</div>
                            {item.isSpicy && <span className="badge bg-danger" style={{ fontSize: '0.6rem' }}>🌶 Spicy</span>}
                          </div>
                        </div>
                      ))}
                      {filteredItems.length === 0 && <div className="col-12 text-center text-muted-custom py-3">No items found</div>}
                    </div>
                  </div>
                </div>

                {/* Right: Cart */}
                <div className="col-12 col-md-5">
                  <h6 className="fw-bold text-main mb-2">Order Summary</h6>
                  <div className="overflow-auto" style={{ maxHeight: 220 }}>
                    {orderItems.length === 0 ? (
                      <div className="text-center text-muted-custom py-4">No items added yet</div>
                    ) : (
                      orderItems.map(i => (
                        <div key={i.itemId} className="d-flex align-items-center justify-content-between mb-2 bg-card-custom rounded-3 p-2">
                          <div className="text-main small fw-semibold" style={{ flex: 1 }}>{i.name}</div>
                          <div className="d-flex align-items-center gap-2">
                            <button className="btn btn-sm btn-outline-secondary border-custom p-0" style={{ width: 22, height: 22 }} onClick={() => handleAdjustQty(i.itemId, -1)}>−</button>
                            <span className="text-main small fw-bold">{i.quantity}</span>
                            <button className="btn btn-sm btn-outline-secondary border-custom p-0" style={{ width: 22, height: 22 }} onClick={() => handleAdjustQty(i.itemId, 1)}>+</button>
                            <button className="btn btn-sm btn-outline-danger p-0" style={{ width: 22, height: 22 }} onClick={() => handleRemoveItem(i.itemId)}><X size={11} /></button>
                          </div>
                        </div>
                      ))
                    )}
                  </div>

                  <div className="mb-2 mt-2">
                    <label className="form-label text-muted-custom small fw-semibold">Special Note</label>
                    <textarea className="form-control form-control-sm" rows={2} placeholder="Allergies, special requests..." value={orderNote} onChange={e => setOrderNote(e.target.value)} />
                  </div>

                  <div className="bg-card-custom rounded-3 p-3 mb-3 text-end">
                    <span className="text-muted-custom small">Order Total</span>
                    <div className="fw-extrabold text-blue" style={{ fontSize: '1.4rem' }}>₹{orderTotal.toFixed(0)}</div>
                  </div>

                  <button id="submit-order-btn" className="btn btn-blue w-100 touch-btn py-3 fw-bold" onClick={handleSubmitOrder} disabled={orderItems.length === 0}>
                    <Utensils size={15} className="me-2" /> SEND TO KITCHEN
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── ADD TABLE MODAL ── */}
      {showAddTableModal && (
        <div className="modal-backdrop-custom" onClick={() => setShowAddTableModal(false)}>
          <div className="modal-box" onClick={e => e.stopPropagation()}>
            <div className="p-4 border-bottom border-custom d-flex justify-content-between align-items-center">
              <h6 className="fw-bold text-main m-0">Add New Table</h6>
              <button className="btn-close" onClick={() => setShowAddTableModal(false)} />
            </div>
            <form onSubmit={handleAddTable} className="p-4">
              <div className="mb-3">
                <label className="form-label text-muted-custom small fw-semibold">Table Number *</label>
                <input className="form-control" required value={newTable.tableNumber} onChange={e => setNewTable(p => ({...p, tableNumber: e.target.value}))} placeholder="T-10" />
              </div>
              <div className="row g-3 mb-3">
                <div className="col-6">
                  <label className="form-label text-muted-custom small fw-semibold">Capacity</label>
                  <input type="number" min={1} className="form-control" value={newTable.capacity} onChange={e => setNewTable(p => ({...p, capacity: e.target.value}))} />
                </div>
                <div className="col-6">
                  <label className="form-label text-muted-custom small fw-semibold">Section</label>
                  <input className="form-control" value={newTable.section} onChange={e => setNewTable(p => ({...p, section: e.target.value}))} />
                </div>
              </div>
              <div className="mb-3">
                <label className="form-label text-muted-custom small fw-semibold">Seating Type</label>
                <select className="form-select" value={newTable.seatingType} onChange={e => setNewTable(p => ({...p, seatingType: e.target.value}))}>
                  <option>Standard</option>
                  <option>Booth</option>
                  <option>Bar</option>
                  <option>Outdoor</option>
                  <option>Private</option>
                </select>
              </div>
              <div className="d-flex gap-2 justify-content-end">
                <button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddTableModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-blue touch-btn">Add Table</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
