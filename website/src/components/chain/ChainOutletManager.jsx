import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  Building2, 
  Plus, 
  Radio, 
  Send, 
  Percent, 
  Eye, 
  ShieldAlert, 
  Award, 
  TrendingUp, 
  DollarSign, 
  Layers, 
  Search, 
  RefreshCw, 
  CheckCircle2, 
  AlertCircle, 
  ShoppingBag, 
  Utensils, 
  Tag, 
  Megaphone, 
  FileText, 
  BarChart3,
  HelpCircle,
  X
} from 'lucide-react';

export default function ChainOutletManager({ showToast }) {
  // Main Data States
  const [outlets, setOutlets] = useState([]);
  const [menuItems, setMenuItems] = useState([]);
  const [consolidatedReport, setConsolidatedReport] = useState(null);
  const [outletComparisons, setOutletComparisons] = useState([]);
  const [loading, setLoading] = useState(false);

  // Tabs
  const [activeTab, setActiveTab] = useState('OUTLETS'); // 'OUTLETS', 'BENCHMARKING', 'OVERRIDES', 'PROMOTIONS'

  // Modals
  const [showBrandModal, setShowBrandModal] = useState(false);
  const [brandForm, setBrandForm] = useState({
    name: '',
    headquartersAddress: '',
    corporateContact: ''
  });

  const [showOutletModal, setShowOutletModal] = useState(false);
  const [outletForm, setOutletForm] = useState({
    name: '',
    city: '',
    address: '',
    isFranchise: false,
    royaltyPercentage: '5.00',
    mysteryAuditActive: false,
    brandId: '',
    configJson: ''
  });

  const [showPushMenuModal, setShowPushMenuModal] = useState(false);
  const [selectedPushItems, setSelectedPushItems] = useState([]);
  const [selectedTargetOutlets, setSelectedTargetOutlets] = useState([]);

  const [showOverrideModal, setShowOverrideModal] = useState(false);
  const [overrideForm, setOverrideForm] = useState({
    outletId: '',
    menuItemId: '',
    overridePrice: '',
    isAvailable: true,
    isSpecial: false,
    specialPrice: ''
  });

  const [showBroadcastModal, setShowBroadcastModal] = useState(false);
  const [broadcastForm, setBroadcastForm] = useState({
    brandId: '',
    title: '',
    message: ''
  });

  const [showUnavailabilityModal, setShowUnavailabilityModal] = useState(false);
  const [unavailForm, setUnavailForm] = useState({
    menuItemName: '',
    isAvailable: false
  });

  const [showPromotionModal, setShowPromotionModal] = useState(false);
  const [promoForm, setPromoForm] = useState({
    promoCode: '',
    discountPercentage: '10.00',
    description: '',
    validFrom: new Date().toISOString().substring(0, 16),
    validTo: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().substring(0, 16),
    isActive: true,
    brandId: ''
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [outletsRes, menuRes, consolidatedRes, comparisonRes] = await Promise.all([
        apiRequest('/api/v1/chain/outlets').catch(() => []),
        apiRequest('/api/v1/menu/items').catch(() => []),
        apiRequest('/api/v1/chain/reports/consolidated').catch(() => null),
        apiRequest('/api/v1/chain/reports/comparison').catch(() => []),
      ]);

      const outs = Array.isArray(outletsRes) ? outletsRes : [];
      const menus = Array.isArray(menuRes) ? menuRes : [];
      const comparisons = Array.isArray(comparisonRes) ? comparisonRes : [];

      setOutlets(outs);
      setMenuItems(menus);
      setConsolidatedReport(consolidatedRes);
      setOutletComparisons(comparisons);
    } catch (err) {
      console.error('Error loading chain manager data:', err);
    } finally {
      setLoading(false);
    }
  };

  // 1. Create Brand
  const handleCreateBrand = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/chain/brands', 'POST', brandForm);
      if (showToast) showToast(`Brand '${brandForm.name}' created!`, 'success');
      setShowBrandModal(false);
      setBrandForm({ name: '', headquartersAddress: '', corporateContact: '' });
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create brand', 'error');
    }
  };

  // 2. Create Outlet
  const handleCreateOutlet = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        name: outletForm.name.trim(),
        city: outletForm.city.trim(),
        address: outletForm.address.trim(),
        isFranchise: Boolean(outletForm.isFranchise),
        royaltyPercentage: parseFloat(outletForm.royaltyPercentage) || 5.00,
        mysteryAuditActive: Boolean(outletForm.mysteryAuditActive),
        configJson: outletForm.configJson || null
      };
      await apiRequest('/api/v1/chain/outlets', 'POST', payload);
      if (showToast) showToast(`Outlet '${outletForm.name}' created successfully!`, 'success');
      setShowOutletModal(false);
      setOutletForm({
        name: '',
        city: '',
        address: '',
        isFranchise: false,
        royaltyPercentage: '5.00',
        mysteryAuditActive: false,
        brandId: '',
        configJson: ''
      });
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create outlet', 'error');
    }
  };

  // 3. Toggle Mystery Audit
  const handleToggleMysteryAudit = async (outletId, currentActive) => {
    try {
      await apiRequest(`/api/v1/chain/outlets/${outletId}/mystery-audit?active=${!currentActive}`, 'PUT');
      if (showToast) showToast(`Mystery audit mode updated for outlet`, 'info');
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to toggle mystery audit', 'error');
    }
  };

  // 4. Centralized Master Menu Push
  const handlePushMasterMenu = async (e) => {
    e.preventDefault();
    if (selectedTargetOutlets.length === 0 || selectedPushItems.length === 0) {
      if (showToast) showToast('Please select at least one menu item and one target outlet!', 'warning');
      return;
    }

    try {
      await apiRequest('/api/v1/chain/menu/push', 'POST', {
        targetOutletIds: selectedTargetOutlets,
        menuItemIds: selectedPushItems
      });
      if (showToast) showToast(`Master menu pushed to ${selectedTargetOutlets.length} target outlets!`, 'success');
      setShowPushMenuModal(false);
      setSelectedPushItems([]);
      setSelectedTargetOutlets([]);
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Menu push failed', 'error');
    }
  };

  // 5. Save Outlet Menu Override
  const handleSaveOverride = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        outletId: overrideForm.outletId,
        menuItemId: overrideForm.menuItemId,
        overridePrice: overrideForm.overridePrice ? parseFloat(overrideForm.overridePrice) : null,
        isAvailable: overrideForm.isAvailable,
        isSpecial: overrideForm.isSpecial,
        specialPrice: overrideForm.specialPrice ? parseFloat(overrideForm.specialPrice) : null
      };
      await apiRequest('/api/v1/chain/menu/override', 'POST', payload);
      if (showToast) showToast('Outlet menu item override saved!', 'success');
      setShowOverrideModal(false);
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Override failed', 'error');
    }
  };

  // 6. Broadcast Item Unavailability (86 across chain)
  const handleBroadcastUnavailability = async (e) => {
    e.preventDefault();
    try {
      await apiRequest(
        `/api/v1/chain/menu/broadcast-unavailability?menuItemName=${encodeURIComponent(unavailForm.menuItemName)}&isAvailable=${unavailForm.isAvailable}`,
        'POST'
      );
      if (showToast) showToast(`Broadcast complete for dish '${unavailForm.menuItemName}'!`, 'success');
      setShowUnavailabilityModal(false);
      setUnavailForm({ menuItemName: '', isAvailable: false });
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Broadcast failed', 'error');
    }
  };

  // 7. Corporate Alert Broadcast
  const handleBroadcastCorporateAlert = async (e) => {
    e.preventDefault();
    try {
      await apiRequest(
        `/api/v1/chain/notifications/broadcast?title=${encodeURIComponent(broadcastForm.title)}&message=${encodeURIComponent(broadcastForm.message)}`,
        'POST'
      );
      if (showToast) showToast(`Corporate alert broadcasted to all outlet managers!`, 'success');
      setShowBroadcastModal(false);
      setBroadcastForm({ brandId: '', title: '', message: '' });
    } catch (err) {
      if (showToast) showToast(err.message || 'Alert broadcast failed', 'error');
    }
  };

  // 8. Create Brand Promotion
  const handleCreateBrandPromotion = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        promoCode: promoForm.promoCode.trim().toUpperCase(),
        discountPercentage: parseFloat(promoForm.discountPercentage) || 10.00,
        description: promoForm.description.trim(),
        validFrom: promoForm.validFrom,
        validTo: promoForm.validTo,
        isActive: Boolean(promoForm.isActive)
      };
      await apiRequest('/api/v1/chain/promotions', 'POST', payload);
      if (showToast) showToast(`Chain-wide promo code '${promoForm.promoCode}' launched!`, 'success');
      setShowPromotionModal(false);
      setPromoForm({
        promoCode: '',
        discountPercentage: '10.00',
        description: '',
        validFrom: new Date().toISOString().substring(0, 16),
        validTo: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().substring(0, 16),
        isActive: true,
        brandId: ''
      });
      fetchData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Promotion creation failed', 'error');
    }
  };

  return (
    <div className="chain-outlet-manager">
      {/* Consolidated Chain Summary Top Cards */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <Building2 size={22} className="text-secondary-custom" />
              Multi-Outlet Chain & Franchise HQ
            </h5>
            <span className="text-muted-custom small">
              Manage franchise outlets, central menu push sync, outlet price overrides, corporate alerts & mystery audits
            </span>
          </div>

          <div className="d-flex flex-wrap gap-2">
            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowBrandModal(true)}>
              <Building2 size={14} className="me-1" /> Create Brand
            </button>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowBroadcastModal(true)}>
              <Radio size={14} className="me-1 text-danger" /> Corporate Alert
            </button>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowUnavailabilityModal(true)}>
              <ShieldAlert size={14} className="me-1 text-warning" /> Broadcast 86ing
            </button>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowPushMenuModal(true)}>
              <Send size={14} className="me-1 text-primary" /> Master Menu Push
            </button>

            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowOutletModal(true)}>
              <Plus size={14} className="me-1" /> Add New Outlet
            </button>
          </div>
        </div>

        {/* Consolidated Financial Metrics Strip */}
        <div className="row g-3 pt-2 border-top border-custom align-items-center">
          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Consolidated Chain GMV:</span>
              <h5 className="fw-extrabold text-main m-0">
                ₹{consolidatedReport ? Number(consolidatedReport.chainTotalGmv || 0).toLocaleString() : '0'}
              </h5>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Chain Total Orders:</span>
              <h5 className="fw-extrabold text-main m-0">
                {consolidatedReport ? consolidatedReport.chainTotalOrders || 0 : 0} Orders
              </h5>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Average Order Value (AOV):</span>
              <h5 className="fw-extrabold text-danger m-0">
                ₹{consolidatedReport ? Number(consolidatedReport.chainAverageOrderValue || 0).toFixed(2) : '0.00'}
              </h5>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Top Selling Items:</span>
              <span className="fw-bold text-main small text-truncate d-block" title={consolidatedReport?.topSellingItems?.join(', ') || 'N/A'}>
                {consolidatedReport && consolidatedReport.topSellingItems?.length > 0
                  ? consolidatedReport.topSellingItems.slice(0, 2).join(', ')
                  : 'No sales data'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs Bar */}
      <div className="d-flex gap-2 mb-4 overflow-auto">
        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'OUTLETS' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('OUTLETS')}
        >
          Outlets & Franchise Directory ({outlets.length})
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'BENCHMARKING' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('BENCHMARKING')}
        >
          Side-by-Side Outlet Benchmarking
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'OVERRIDES' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('OVERRIDES')}
        >
          Outlet Menu Overrides
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'PROMOTIONS' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('PROMOTIONS')}
        >
          Chain-Wide Brand Promotions
        </button>
      </div>

      {/* TAB 1: OUTLETS DIRECTORY */}
      {activeTab === 'OUTLETS' && (
        <div className="card bg-surface border-custom shadow-sm p-3">
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Outlet Name</th>
                  <th>City & Address</th>
                  <th>Type / Ownership</th>
                  <th>Royalty Rate</th>
                  <th>Mystery Audit</th>
                  <th>Action Commands</th>
                </tr>
              </thead>
              <tbody>
                {outlets.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="text-center py-4 text-muted-custom">
                      No outlets registered. Click "+ Add New Outlet" above to set up your first location.
                    </td>
                  </tr>
                ) : (
                  outlets.map((o) => {
                    const oId = o.outletId || o.id;
                    const isMysteryActive = Boolean(o.mysteryAuditActive);

                    return (
                      <tr key={oId}>
                        <td className="fw-bold text-main">
                          <Building2 size={16} className="me-2 text-danger" />
                          {o.name}
                        </td>
                        <td className="text-muted-custom small">
                          {o.city ? `${o.city} — ${o.address || 'Main Street'}` : o.address || 'N/A'}
                        </td>
                        <td>
                          {o.isFranchise ? (
                            <span className="badge bg-warning text-dark">Franchise Outlet</span>
                          ) : (
                            <span className="badge bg-success bg-opacity-20 text-success">Company Owned</span>
                          )}
                        </td>
                        <td>
                          <span className="fw-bold text-main">{o.royaltyPercentage || '5.00'}%</span>
                        </td>
                        <td>
                          <div className="form-check form-switch">
                            <input
                              className="form-check-input"
                              type="checkbox"
                              checked={isMysteryActive}
                              onChange={() => handleToggleMysteryAudit(oId, isMysteryActive)}
                            />
                            <label className="form-check-label small text-muted-custom">
                              {isMysteryActive ? 'Active (Hidden)' : 'Inactive'}
                            </label>
                          </div>
                        </td>
                        <td>
                          <button
                            className="btn btn-sm btn-outline-secondary me-2"
                            onClick={() => {
                              setOverrideForm(prev => ({ ...prev, outletId: oId }));
                              setShowOverrideModal(true);
                            }}
                          >
                            Set Price Override
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

      {/* TAB 2: SIDE-BY-SIDE OUTLET BENCHMARKING */}
      {activeTab === 'BENCHMARKING' && (
        <div className="card bg-surface border-custom shadow-sm p-3">
          <h6 className="fw-bold text-main mb-3">Side-by-Side Multi-Outlet Performance Comparison</h6>
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Outlet Location</th>
                  <th>Type</th>
                  <th>Gross Sales (GMV)</th>
                  <th>Total Orders</th>
                  <th>Guest Covers</th>
                  <th>Average Order Value (AOV)</th>
                  <th>Calculated Franchise Royalty</th>
                  <th>Mystery Audit Status</th>
                </tr>
              </thead>
              <tbody>
                {outletComparisons.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="text-center py-4 text-muted-custom">No comparison data generated yet.</td>
                  </tr>
                ) : (
                  outletComparisons.map((c) => (
                    <tr key={c.outletId}>
                      <td className="fw-bold text-main">{c.outletName} ({c.city || 'HQ'})</td>
                      <td>
                        {c.isFranchise ? (
                          <span className="badge bg-warning text-dark">Franchise</span>
                        ) : (
                          <span className="badge bg-success bg-opacity-20 text-success">Company Owned</span>
                        )}
                      </td>
                      <td className="fw-bold text-success">₹{Number(c.gmv || 0).toLocaleString()}</td>
                      <td>{c.totalOrders || 0}</td>
                      <td>{c.totalCovers || 0}</td>
                      <td className="fw-bold text-danger">₹{Number(c.averageOrderValue || 0).toFixed(2)}</td>
                      <td className="fw-bold text-primary">₹{Number(c.calculatedRoyalty || 0).toFixed(2)}</td>
                      <td>
                        <span className={`badge ${c.mysteryAuditActive ? 'bg-danger text-white' : 'bg-secondary'}`}>
                          {c.mysteryAuditActive ? 'Under Surveillance' : 'Standard'}
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

      {/* TAB 3: OUTLET MENU OVERRIDES */}
      {activeTab === 'OVERRIDES' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h6 className="fw-bold text-main m-0">Outlet Price & Availability Overrides</h6>
            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowOverrideModal(true)}>
              + Add Menu Item Override
            </button>
          </div>
          <p className="text-muted-custom small mb-4">
            Configure outlet-specific prices, special offer rates, or localized dish availability without modifying the corporate master menu.
          </p>

          <div className="alert bg-card-custom border-custom text-main small">
            <AlertCircle size={16} className="me-2 text-info" />
            Select an outlet and dish in the override modal to set custom regional prices or temporary outlet 86ing.
          </div>
        </div>
      )}

      {/* TAB 4: CHAIN-WIDE BRAND PROMOTIONS */}
      {activeTab === 'PROMOTIONS' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h6 className="fw-bold text-main m-0">Chain-Wide Brand Promotional Offers</h6>
            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowPromotionModal(true)}>
              + Launch Brand Promotion
            </button>
          </div>
          <p className="text-muted-custom small mb-4">
            Create brand-wide promo discount codes applicable across all franchise locations.
          </p>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 1: CREATE BRAND FORM                                 */}
      {/* ========================================================= */}
      {showBrandModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Create Chain Brand</h5>
                <button type="button" className="btn-close" onClick={() => setShowBrandModal(false)}></button>
              </div>

              <form onSubmit={handleCreateBrand}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Brand Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Spice Haven Downtown"
                      value={brandForm.name}
                      onChange={(e) => setBrandForm({ ...brandForm, name: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Headquarters Address</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. Corporate Tower, Connaught Place, New Delhi"
                      value={brandForm.headquartersAddress}
                      onChange={(e) => setBrandForm({ ...brandForm, headquartersAddress: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Corporate Contact Email / Phone</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. corporate@spicehaven.com"
                      value={brandForm.corporateContact}
                      onChange={(e) => setBrandForm({ ...brandForm, corporateContact: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowBrandModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Create Brand
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: CREATE OUTLET FORM                                */}
      {/* ========================================================= */}
      {showOutletModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Register New Outlet Location</h5>
                <button type="button" className="btn-close" onClick={() => setShowOutletModal(false)}></button>
              </div>

              <form onSubmit={handleCreateOutlet}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Outlet Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Spice Haven - Cyber Hub Branch"
                      value={outletForm.name}
                      onChange={(e) => setOutletForm({ ...outletForm, name: e.target.value })}
                    />
                  </div>

                  <div className="row g-3 mb-3">
                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">City *</label>
                      <input
                        type="text"
                        className="form-control"
                        required
                        placeholder="e.g. Gurgaon"
                        value={outletForm.city}
                        onChange={(e) => setOutletForm({ ...outletForm, city: e.target.value })}
                      />
                    </div>

                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">Address *</label>
                      <input
                        type="text"
                        className="form-control"
                        required
                        placeholder="e.g. DLF Phase 3"
                        value={outletForm.address}
                        onChange={(e) => setOutletForm({ ...outletForm, address: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="row g-3 mb-3 align-items-center">
                    <div className="col-6">
                      <div className="form-check form-switch mt-4">
                        <input
                          className="form-check-input"
                          type="checkbox"
                          id="franchiseSwitch"
                          checked={outletForm.isFranchise}
                          onChange={(e) => setOutletForm({ ...outletForm, isFranchise: e.target.checked })}
                        />
                        <label className="form-check-label text-main small fw-bold" htmlFor="franchiseSwitch">
                          Is Franchise Outlet?
                        </label>
                      </div>
                    </div>

                    {outletForm.isFranchise && (
                      <div className="col-6">
                        <label className="form-label text-muted-custom small fw-semibold">Royalty Rate (%)</label>
                        <input
                          type="number"
                          step="0.01"
                          className="form-control"
                          value={outletForm.royaltyPercentage}
                          onChange={(e) => setOutletForm({ ...outletForm, royaltyPercentage: e.target.value })}
                        />
                      </div>
                    )}
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowOutletModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Register Outlet
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 3: MASTER MENU PUSH TO OUTLETS                      */}
      {/* ========================================================= */}
      {showPushMenuModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-lg modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <Send size={20} className="text-secondary-custom" />
                  Push Corporate Master Menu to Outlets
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowPushMenuModal(false)}></button>
              </div>

              <form onSubmit={handlePushMasterMenu}>
                <div className="modal-body">
                  <div className="row g-4">
                    {/* Select Dishes */}
                    <div className="col-12 col-md-6">
                      <h6 className="fw-bold text-main mb-2">1. Select Master Menu Items</h6>
                      <div className="p-3 bg-card-custom rounded-3 border border-custom overflow-auto" style={{ maxHeight: '300px' }}>
                        {menuItems.map((item) => {
                          const iId = item.itemId || item.id;
                          const isChecked = selectedPushItems.includes(iId);

                          return (
                            <div key={iId} className="form-check mb-2">
                              <input
                                className="form-check-input"
                                type="checkbox"
                                id={`pushItem_${iId}`}
                                checked={isChecked}
                                onChange={(e) => {
                                  setSelectedPushItems(prev =>
                                    e.target.checked ? [...prev, iId] : prev.filter(x => x !== iId)
                                  );
                                }}
                              />
                              <label className="form-check-label text-main small" htmlFor={`pushItem_${iId}`}>
                                {item.name} — <span className="fw-bold text-danger">₹{item.price}</span>
                              </label>
                            </div>
                          );
                        })}
                      </div>
                    </div>

                    {/* Select Outlets */}
                    <div className="col-12 col-md-6">
                      <h6 className="fw-bold text-main mb-2">2. Select Target Outlets</h6>
                      <div className="p-3 bg-card-custom rounded-3 border border-custom overflow-auto" style={{ maxHeight: '300px' }}>
                        {outlets.map((o) => {
                          const oId = o.outletId || o.id;
                          const isChecked = selectedTargetOutlets.includes(oId);

                          return (
                            <div key={oId} className="form-check mb-2">
                              <input
                                className="form-check-input"
                                type="checkbox"
                                id={`targetOutlet_${oId}`}
                                checked={isChecked}
                                onChange={(e) => {
                                  setSelectedTargetOutlets(prev =>
                                    e.target.checked ? [...prev, oId] : prev.filter(x => x !== oId)
                                  );
                                }}
                              />
                              <label className="form-check-label text-main small" htmlFor={`targetOutlet_${oId}`}>
                                {o.name} ({o.city})
                              </label>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowPushMenuModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Push Menu ({selectedPushItems.length} Items to {selectedTargetOutlets.length} Outlets)
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 4: OUTLET MENU OVERRIDE                              */}
      {/* ========================================================= */}
      {showOverrideModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Configure Outlet Menu Override</h5>
                <button type="button" className="btn-close" onClick={() => setShowOverrideModal(false)}></button>
              </div>

              <form onSubmit={handleSaveOverride}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Target Outlet *</label>
                    <select
                      className="form-select"
                      required
                      value={overrideForm.outletId}
                      onChange={(e) => setOverrideForm({ ...overrideForm, outletId: e.target.value })}
                    >
                      <option value="">Select Outlet...</option>
                      {outlets.map(o => (
                        <option key={o.outletId || o.id} value={o.outletId || o.id}>{o.name}</option>
                      ))}
                    </select>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Menu Dish Item *</label>
                    <select
                      className="form-select"
                      required
                      value={overrideForm.menuItemId}
                      onChange={(e) => setOverrideForm({ ...overrideForm, menuItemId: e.target.value })}
                    >
                      <option value="">Select Dish...</option>
                      {menuItems.map(i => (
                        <option key={i.itemId || i.id} value={i.itemId || i.id}>{i.name} (Standard ₹{i.price})</option>
                      ))}
                    </select>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Override Price (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      className="form-control"
                      placeholder="Leave blank for standard corporate price"
                      value={overrideForm.overridePrice}
                      onChange={(e) => setOverrideForm({ ...overrideForm, overridePrice: e.target.value })}
                    />
                  </div>

                  <div className="form-check form-switch mb-3">
                    <input
                      className="form-check-input"
                      type="checkbox"
                      id="availOverrideSwitch"
                      checked={overrideForm.isAvailable}
                      onChange={(e) => setOverrideForm({ ...overrideForm, isAvailable: e.target.checked })}
                    />
                    <label className="form-check-label text-main small" htmlFor="availOverrideSwitch">
                      Item Available at this Outlet
                    </label>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowOverrideModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Save Override
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 5: BROADCAST 86ING UNAVAILABILITY                    */}
      {/* ========================================================= */}
      {showUnavailabilityModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <ShieldAlert size={20} className="text-warning" />
                  Chain-wide Item Unavailability Broadcast
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowUnavailabilityModal(false)}></button>
              </div>

              <form onSubmit={handleBroadcastUnavailability}>
                <div className="modal-body">
                  <p className="text-muted-custom small mb-3">
                    Mark a specific dish as 86'd (unavailable) or available across all outlet POS menus simultaneously.
                  </p>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Dish Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Paneer Butter Masala"
                      value={unavailForm.menuItemName}
                      onChange={(e) => setUnavailForm({ ...unavailForm, menuItemName: e.target.value })}
                    />
                  </div>

                  <div className="form-check form-switch mb-3">
                    <input
                      className="form-check-input"
                      type="checkbox"
                      id="chainAvailSwitch"
                      checked={unavailForm.isAvailable}
                      onChange={(e) => setUnavailForm({ ...unavailForm, isAvailable: e.target.checked })}
                    />
                    <label className="form-check-label text-main small fw-bold" htmlFor="chainAvailSwitch">
                      Item Status: {unavailForm.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE (86\'d)'}
                    </label>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowUnavailabilityModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-warning text-dark fw-bold px-4">
                    Broadcast Unavailability
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 6: BROADCAST CORPORATE ALERT                         */}
      {/* ========================================================= */}
      {showBroadcastModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <Radio size={20} className="text-danger" />
                  Broadcast Corporate Alert
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowBroadcastModal(false)}></button>
              </div>

              <form onSubmit={handleBroadcastCorporateAlert}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Alert Title *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Audit Notice / Health Protocol"
                      value={broadcastForm.title}
                      onChange={(e) => setBroadcastForm({ ...broadcastForm, title: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Message Body *</label>
                    <textarea
                      className="form-control"
                      rows="3"
                      required
                      placeholder="Corporate instructions to all outlet managers..."
                      value={broadcastForm.message}
                      onChange={(e) => setBroadcastForm({ ...broadcastForm, message: e.target.value })}
                    ></textarea>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowBroadcastModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-danger fw-bold px-4">
                    Send Corporate Alert
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 7: LAUNCH BRAND PROMOTION                            */}
      {/* ========================================================= */}
      {showPromotionModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Launch Chain Brand Promotion</h5>
                <button type="button" className="btn-close" onClick={() => setShowPromotionModal(false)}></button>
              </div>

              <form onSubmit={handleCreateBrandPromotion}>
                <div className="modal-body">
                  <div className="row g-3 mb-3">
                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">Promo Code *</label>
                      <input
                        type="text"
                        className="form-control text-uppercase fw-bold"
                        required
                        placeholder="SUMMER20"
                        value={promoForm.promoCode}
                        onChange={(e) => setPromoForm({ ...promoForm, promoCode: e.target.value })}
                      />
                    </div>

                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">Discount (%) *</label>
                      <input
                        type="number"
                        step="0.01"
                        className="form-control"
                        required
                        value={promoForm.discountPercentage}
                        onChange={(e) => setPromoForm({ ...promoForm, discountPercentage: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Description</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. 10% OFF summer corporate promotion"
                      value={promoForm.description}
                      onChange={(e) => setPromoForm({ ...promoForm, description: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowPromotionModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Launch Promotion
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

