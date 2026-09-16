import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  Package, 
  Plus, 
  AlertTriangle, 
  Truck, 
  FileText, 
  PieChart, 
  ShieldAlert, 
  CheckCircle2, 
  Search, 
  DollarSign, 
  Calendar, 
  Clock, 
  RefreshCw, 
  Filter, 
  Layers, 
  ArrowUpRight, 
  BarChart2,
  X
} from 'lucide-react';

export default function InventoryStockManager({ showToast }) {
  // Data States
  const [inventoryItems, setInventoryItems] = useState([]);
  const [lowStockAlerts, setLowStockAlerts] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [cogsReport, setCogsReport] = useState([]);
  const [perishableBatches, setPerishableBatches] = useState([]);
  const [loading, setLoading] = useState(false);

  // Tabs: 'RAW_STOCK', 'GRN_LOGS', 'SUPPLIERS', 'PURCHASE_ORDERS', 'DAILY_VARIANCE', 'COGS_REPORT', 'EXPIRY_BATCHES'
  const [activeTab, setActiveTab] = useState('RAW_STOCK');
  const [searchQuery, setSearchQuery] = useState('');

  // Modals
  const [showGrnModal, setShowGrnModal] = useState(false);
  const [grnForm, setGrnForm] = useState({
    ingredientId: '',
    quantityReceived: '',
    costPrice: ''
  });

  const [showSupplierModal, setShowSupplierModal] = useState(false);
  const [supplierForm, setSupplierForm] = useState({
    name: '',
    contact: '',
    itemsSupplied: '',
    priceHistory: ''
  });

  const [showPoModal, setShowPoModal] = useState(false);
  const [poForm, setPoForm] = useState({
    supplierId: '',
    expectedDelivery: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
    items: [{ ingredientId: '', quantity: '10', unitPrice: '50' }]
  });

  const [showClosingStockModal, setShowClosingStockModal] = useState(false);
  const [closingForm, setClosingForm] = useState({});

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [invRes, alertsRes, suppRes, cogsRes, batchesRes] = await Promise.all([
        apiRequest('/api/v1/inventory').catch(() => []),
        apiRequest('/api/v1/inventory/alerts').catch(() => []),
        apiRequest('/api/v1/inventory/suppliers').catch(() => []),
        apiRequest('/api/v1/inventory/reports/cogs').catch(() => []),
        apiRequest('/api/v1/inventory/batches').catch(() => []),
      ]);

      const items = Array.isArray(invRes) ? invRes : [];
      const alerts = Array.isArray(alertsRes) ? alertsRes : [];
      const supps = Array.isArray(suppRes) ? suppRes : [];
      const cogs = Array.isArray(cogsRes) ? cogsRes : [];
      const batches = Array.isArray(batchesRes) ? batchesRes : [];

      setInventoryItems(items);
      setLowStockAlerts(alerts);
      setSuppliers(supps);
      setCogsReport(cogs);
      setPerishableBatches(batches);

      if (items.length > 0 && !grnForm.ingredientId) {
        setGrnForm(prev => ({ ...prev, ingredientId: items[0].ingredientId || items[0].id }));
      }
      if (supps.length > 0 && !poForm.supplierId) {
        setPoForm(prev => ({ ...prev, supplierId: supps[0].supplierId || supps[0].id }));
      }
    } catch (err) {
      console.error('Error loading inventory data:', err);
    } finally {
      setLoading(false);
    }
  };

  // 1. Record GRN Stock Received
  const handleRecordGrn = async (e) => {
    e.preventDefault();
    if (!grnForm.ingredientId || !grnForm.quantityReceived) return;

    try {
      const ingredientId = grnForm.ingredientId;
      const quantityReceived = parseFloat(grnForm.quantityReceived) || 0;
      const costPrice = grnForm.costPrice ? parseFloat(grnForm.costPrice) : null;

      let url = `/api/v1/inventory/grn?ingredientId=${ingredientId}&quantityReceived=${quantityReceived}`;
      if (costPrice !== null) {
        url += `&costPrice=${costPrice}`;
      }

      await apiRequest(url, 'POST');
      if (showToast) showToast('GRN Stock received and inventory updated!', 'success');
      setShowGrnModal(false);
      setGrnForm({ ingredientId: inventoryItems[0]?.ingredientId || '', quantityReceived: '', costPrice: '' });
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'GRN recording failed', 'error');
    }
  };

  // 2. Create Supplier
  const handleCreateSupplier = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/inventory/suppliers', 'POST', {
        name: supplierForm.name.trim(),
        contact: supplierForm.contact.trim(),
        itemsSupplied: supplierForm.itemsSupplied.trim(),
        priceHistory: supplierForm.priceHistory.trim()
      });
      if (showToast) showToast(`Supplier '${supplierForm.name}' created!`, 'success');
      setShowSupplierModal(false);
      setSupplierForm({ name: '', contact: '', itemsSupplied: '', priceHistory: '' });
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create supplier', 'error');
    }
  };

  // 3. Raise Purchase Order
  const handleRaisePo = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        supplierId: poForm.supplierId,
        expectedDelivery: poForm.expectedDelivery,
        items: poForm.items.map(i => ({
          ingredientId: i.ingredientId,
          quantity: parseFloat(i.quantity) || 1,
          unitPrice: parseFloat(i.unitPrice) || 0
        }))
      };
      await apiRequest('/api/v1/inventory/purchase-orders', 'POST', payload);
      if (showToast) showToast('Purchase Order raised to supplier!', 'success');
      setShowPoModal(false);
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'PO creation failed', 'error');
    }
  };

  // Helper to add item row in PO form
  const addPoItemRow = () => {
    setPoForm(prev => ({
      ...prev,
      items: [...prev.items, { ingredientId: inventoryItems[0]?.ingredientId || '', quantity: '10', unitPrice: '50' }]
    }));
  };

  // 4. Daily Opening Stock Setup
  const handleSetupOpeningStock = async () => {
    try {
      const requests = inventoryItems.map(item => ({
        ingredientId: item.ingredientId || item.id,
        openingStock: parseFloat(item.currentStock) || 0
      }));
      await apiRequest('/api/v1/inventory/daily-stock/opening', 'POST', requests);
      if (showToast) showToast('Today\'s opening stock sheets setup!', 'success');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Opening stock setup failed', 'error');
    }
  };

  // 5. Daily Closing Stock Audit
  const handleRegisterClosingStock = async (e) => {
    e.preventDefault();
    try {
      const requests = Object.keys(closingForm).map(ingId => ({
        ingredientId: ingId,
        actualClosing: parseFloat(closingForm[ingId]) || 0
      }));
      await apiRequest('/api/v1/inventory/daily-stock/closing', 'POST', requests);
      if (showToast) showToast('Actual closing stock and variance calculated!', 'success');
      setShowClosingStockModal(false);
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Closing stock audit failed', 'error');
    }
  };

  // Filtered Inventory List
  const filteredInventory = inventoryItems.filter(item =>
    !searchQuery || item.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="inventory-stock-manager">
      {/* Top Summary & Alert Header */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <Package size={22} className="text-secondary-custom" />
              Inventory, GRN Stock & Supplier Control
            </h5>
            <span className="text-muted-custom small">
              Goods Received Notes (GRN), reorder thresholds, Purchase Orders, daily stock variance & recipe COGS costing
            </span>
          </div>

          <div className="d-flex flex-wrap gap-2">
            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={handleSetupOpeningStock}>
              <Clock size={14} className="me-1" /> Set Opening Stock
            </button>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowSupplierModal(true)}>
              <Truck size={14} className="me-1" /> Add Supplier
            </button>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowPoModal(true)}>
              <FileText size={14} className="me-1 text-primary" /> Raise PO
            </button>

            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowGrnModal(true)}>
              <Plus size={14} className="me-1" /> Record GRN Stock
            </button>
          </div>
        </div>

        {/* Low Stock Warning Alert Banner */}
        {lowStockAlerts.length > 0 && (
          <div className="alert alert-danger d-flex align-items-center justify-content-between gap-2 mb-0 mt-2 p-2">
            <div className="d-flex align-items-center gap-2">
              <AlertTriangle size={18} />
              <span>
                <strong>Stock Shortage Alert:</strong> {lowStockAlerts.length} ingredient(s) have fallen below critical reorder levels!
              </span>
            </div>
            <button className="btn btn-sm btn-danger fw-bold" onClick={() => setShowPoModal(true)}>
              Order Restock PO
            </button>
          </div>
        )}
      </div>

      {/* Tabs Bar */}
      <div className="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
        <div className="d-flex gap-2 overflow-auto">
          <button
            className={`btn btn-sm rounded-pill px-3 ${activeTab === 'RAW_STOCK' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setActiveTab('RAW_STOCK')}
          >
            Raw Ingredients ({inventoryItems.length})
          </button>

          <button
            className={`btn btn-sm rounded-pill px-3 ${activeTab === 'SUPPLIERS' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setActiveTab('SUPPLIERS')}
          >
            Suppliers & Vendors ({suppliers.length})
          </button>

          <button
            className={`btn btn-sm rounded-pill px-3 ${activeTab === 'COGS_REPORT' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setActiveTab('COGS_REPORT')}
          >
            Recipe Costing & COGS ({cogsReport.length})
          </button>

          <button
            className={`btn btn-sm rounded-pill px-3 ${activeTab === 'EXPIRY_BATCHES' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setActiveTab('EXPIRY_BATCHES')}
          >
            Perishable Batches ({perishableBatches.length})
          </button>
        </div>

        {activeTab === 'RAW_STOCK' && (
          <div className="input-group input-group-sm" style={{ width: '220px' }}>
            <span className="input-group-text bg-card-custom border-custom text-muted-custom"><Search size={14} /></span>
            <input
              type="text"
              className="form-control bg-card-custom border-custom text-main"
              placeholder="Search ingredient..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        )}
      </div>

      {/* TAB 1: RAW INGREDIENTS STOCK */}
      {activeTab === 'RAW_STOCK' && (
        <div className="card bg-surface border-custom shadow-sm p-3">
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Ingredient Name</th>
                  <th>Current Stock</th>
                  <th>Reorder Level</th>
                  <th>Unit Cost Price</th>
                  <th>Total Asset Value</th>
                  <th>Stock Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredInventory.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="text-center py-4 text-muted-custom">
                      No inventory raw ingredients recorded.
                    </td>
                  </tr>
                ) : (
                  filteredInventory.map((item) => {
                    const iId = item.ingredientId || item.id;
                    const stockNum = Number(item.currentStock || 0);
                    const reorderNum = Number(item.reorderLevel || 0);
                    const isLow = stockNum <= reorderNum;
                    const assetVal = stockNum * Number(item.costPrice || 0);

                    return (
                      <tr key={iId}>
                        <td className="fw-bold text-main">{item.name}</td>
                        <td className="fw-bold">{stockNum.toFixed(2)} {item.unit}</td>
                        <td className="text-muted-custom">{reorderNum.toFixed(2)} {item.unit}</td>
                        <td className="fw-bold text-danger">₹{Number(item.costPrice || 0).toFixed(2)} / {item.unit}</td>
                        <td className="fw-bold text-main">₹{assetVal.toFixed(2)}</td>
                        <td>
                          <span className={`badge ${isLow ? 'bg-danger text-white' : 'bg-success bg-opacity-20 text-success'}`}>
                            {isLow ? 'CRITICAL LOW' : 'STOCKED'}
                          </span>
                        </td>
                        <td>
                          <button
                            className="btn btn-xs btn-outline-secondary"
                            onClick={() => {
                              setGrnForm({ ingredientId: iId, quantityReceived: '10', costPrice: String(item.costPrice || '') });
                              setShowGrnModal(true);
                            }}
                          >
                            + Record GRN
                          </button>
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

      {/* TAB 2: SUPPLIERS DIRECTORY */}
      {activeTab === 'SUPPLIERS' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h6 className="fw-bold text-main m-0">Vendor & Supplier Directory ({suppliers.length})</h6>
            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowSupplierModal(true)}>
              + Add New Supplier
            </button>
          </div>

          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Supplier Name</th>
                  <th>Contact Info</th>
                  <th>Items Supplied</th>
                  <th>Price History Log</th>
                </tr>
              </thead>
              <tbody>
                {suppliers.length === 0 ? (
                  <tr>
                    <td colSpan="4" className="text-center py-4 text-muted-custom">No suppliers registered. Click "+ Add New Supplier" to create one.</td>
                  </tr>
                ) : (
                  suppliers.map((s) => (
                    <tr key={s.supplierId || s.id}>
                      <td className="fw-bold text-main">
                        <Truck size={15} className="me-2 text-danger" />
                        {s.name}
                      </td>
                      <td className="text-muted-custom small">{s.contact || 'N/A'}</td>
                      <td><span className="badge bg-secondary text-white">{s.itemsSupplied || 'General Wholesale'}</span></td>
                      <td className="text-muted-custom text-xs">{s.priceHistory || 'Standard Contract Pricing'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 3: COGS & RECIPE COSTING */}
      {activeTab === 'COGS_REPORT' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <h6 className="fw-bold text-main mb-3">Cost of Goods Sold (COGS) & Recipe Food Cost Report</h6>
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Menu Dish Name</th>
                  <th>Menu Selling Price</th>
                  <th>Calculated Ingredient Cost (COGS)</th>
                  <th>Gross Profit Margin (%)</th>
                  <th>Margin Indicator</th>
                </tr>
              </thead>
              <tbody>
                {cogsReport.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="text-center py-4 text-muted-custom">No COGS data calculated. Ensure recipes are configured for menu items.</td>
                  </tr>
                ) : (
                  cogsReport.map((r) => {
                    const marginNum = Number(r.grossMarginPercentage || 0);
                    const isHealthy = marginNum >= 65;

                    return (
                      <tr key={r.menuItemId}>
                        <td className="fw-bold text-main">{r.menuItemName}</td>
                        <td className="fw-bold text-danger">₹{Number(r.menuItemPrice || 0).toFixed(2)}</td>
                        <td className="fw-bold text-main">₹{Number(r.ingredientCost || 0).toFixed(2)}</td>
                        <td className={`fw-extrabold ${isHealthy ? 'text-success' : 'text-warning'}`}>
                          {marginNum.toFixed(1)}%
                        </td>
                        <td>
                          <span className={`badge ${isHealthy ? 'bg-success bg-opacity-20 text-success' : 'bg-warning text-dark'}`}>
                            {isHealthy ? 'HIGH MARGIN' : 'REVIEW COSTING'}
                          </span>
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

      {/* TAB 4: PERISHABLE BATCHES */}
      {activeTab === 'EXPIRY_BATCHES' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <h6 className="fw-bold text-main mb-3">Perishable Ingredient Batches (FIFO Expiry Tracking)</h6>
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Batch ID</th>
                  <th>Ingredient</th>
                  <th>Batch Quantity</th>
                  <th>Purchase Date</th>
                  <th>Expiry Date</th>
                </tr>
              </thead>
              <tbody>
                {perishableBatches.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="text-center py-4 text-muted-custom">No active perishable batches recorded.</td>
                  </tr>
                ) : (
                  perishableBatches.map((b) => {
                    const ing = inventoryItems.find(i => (i.ingredientId || i.id) === b.ingredientId);
                    return (
                      <tr key={b.batchId || b.id}>
                        <td><code>{String(b.batchId || b.id).substring(0, 8)}</code></td>
                        <td className="fw-bold text-main">{ing ? ing.name : 'Ingredient Batch'}</td>
                        <td className="fw-bold">{b.quantity} {ing ? ing.unit : 'units'}</td>
                        <td className="text-muted-custom small">{b.purchaseDate}</td>
                        <td><span className="badge bg-warning text-dark">{b.expiryDate}</span></td>
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
      {/* MODAL 1: RECORD GRN STOCK FORM                             */}
      {/* ========================================================= */}
      {showGrnModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Record GRN Stock Received</h5>
                <button type="button" className="btn-close" onClick={() => setShowGrnModal(false)}></button>
              </div>

              <form onSubmit={handleRecordGrn}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Select Ingredient *</label>
                    <select
                      className="form-select"
                      required
                      value={grnForm.ingredientId}
                      onChange={(e) => setGrnForm({ ...grnForm, ingredientId: e.target.value })}
                    >
                      <option value="">-- Choose Ingredient --</option>
                      {inventoryItems.map((inv) => (
                        <option key={inv.ingredientId || inv.id} value={inv.ingredientId || inv.id}>
                          {inv.name} (Current: {inv.currentStock} {inv.unit})
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Quantity Received *</label>
                    <input
                      type="number"
                      step="0.001"
                      className="form-control"
                      required
                      placeholder="e.g. 25.5"
                      value={grnForm.quantityReceived}
                      onChange={(e) => setGrnForm({ ...grnForm, quantityReceived: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Unit Cost Price (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      className="form-control"
                      placeholder="Cost price per unit"
                      value={grnForm.costPrice}
                      onChange={(e) => setGrnForm({ ...grnForm, costPrice: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowGrnModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Record Stock Received
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: ADD SUPPLIER FORM                                 */}
      {/* ========================================================= */}
      {showSupplierModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Add New Vendor Supplier</h5>
                <button type="button" className="btn-close" onClick={() => setShowSupplierModal(false)}></button>
              </div>

              <form onSubmit={handleCreateSupplier}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Supplier / Vendor Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Metro Cash & Carry, FarmFresh Dairy"
                      value={supplierForm.name}
                      onChange={(e) => setSupplierForm({ ...supplierForm, name: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Contact Email / Phone</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. sales@farmfresh.com, +91 9876543210"
                      value={supplierForm.contact}
                      onChange={(e) => setSupplierForm({ ...supplierForm, contact: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Items Supplied</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. Milk, Paneer, Cheese, Cream"
                      value={supplierForm.itemsSupplied}
                      onChange={(e) => setSupplierForm({ ...supplierForm, itemsSupplied: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowSupplierModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Register Supplier
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 3: RAISE PURCHASE ORDER                              */}
      {/* ========================================================= */}
      {showPoModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-lg modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Raise Purchase Order (PO) to Supplier</h5>
                <button type="button" className="btn-close" onClick={() => setShowPoModal(false)}></button>
              </div>

              <form onSubmit={handleRaisePo}>
                <div className="modal-body">
                  <div className="row g-3 mb-3">
                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Select Vendor / Supplier *</label>
                      <select
                        className="form-select"
                        required
                        value={poForm.supplierId}
                        onChange={(e) => setPoForm({ ...poForm, supplierId: e.target.value })}
                      >
                        <option value="">Choose Supplier...</option>
                        {suppliers.map(s => (
                          <option key={s.supplierId || s.id} value={s.supplierId || s.id}>{s.name}</option>
                        ))}
                      </select>
                    </div>

                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Expected Delivery Date *</label>
                      <input
                        type="date"
                        className="form-control"
                        required
                        value={poForm.expectedDelivery}
                        onChange={(e) => setPoForm({ ...poForm, expectedDelivery: e.target.value })}
                      />
                    </div>
                  </div>

                  <h6 className="fw-bold text-main mb-2">PO Line Items</h6>
                  {poForm.items.map((row, idx) => (
                    <div key={idx} className="row g-2 mb-2 align-items-center">
                      <div className="col-6">
                        <select
                          className="form-select form-select-sm"
                          required
                          value={row.ingredientId}
                          onChange={(e) => {
                            const newItems = [...poForm.items];
                            newItems[idx].ingredientId = e.target.value;
                            setPoForm({ ...poForm, items: newItems });
                          }}
                        >
                          <option value="">Select Ingredient...</option>
                          {inventoryItems.map(i => (
                            <option key={i.ingredientId || i.id} value={i.ingredientId || i.id}>{i.name} ({i.unit})</option>
                          ))}
                        </select>
                      </div>

                      <div className="col-3">
                        <input
                          type="number"
                          step="0.01"
                          className="form-control form-control-sm"
                          placeholder="Qty"
                          required
                          value={row.quantity}
                          onChange={(e) => {
                            const newItems = [...poForm.items];
                            newItems[idx].quantity = e.target.value;
                            setPoForm({ ...poForm, items: newItems });
                          }}
                        />
                      </div>

                      <div className="col-3">
                        <input
                          type="number"
                          step="0.01"
                          className="form-control form-control-sm"
                          placeholder="Price ₹"
                          required
                          value={row.unitPrice}
                          onChange={(e) => {
                            const newItems = [...poForm.items];
                            newItems[idx].unitPrice = e.target.value;
                            setPoForm({ ...poForm, items: newItems });
                          }}
                        />
                      </div>
                    </div>
                  ))}

                  <button type="button" className="btn btn-sm btn-outline-secondary mt-2" onClick={addPoItemRow}>
                    + Add Row Item
                  </button>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowPoModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Issue Purchase Order
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
