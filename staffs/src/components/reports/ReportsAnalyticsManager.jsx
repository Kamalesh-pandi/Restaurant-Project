import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  BarChart3, 
  TrendingUp, 
  DollarSign, 
  Calendar, 
  Clock, 
  Award, 
  Users, 
  ShoppingBag, 
  Utensils, 
  PieChart, 
  ShieldAlert, 
  FileText, 
  CheckCircle2, 
  RefreshCw, 
  Filter, 
  ArrowUpRight, 
  Printer, 
  Star,
  Zap,
  Truck,
  Layers,
  X,
  CreditCard,
  Banknote,
  Smartphone,
  Wallet
} from 'lucide-react';

// Helper to parse and aggregate raw payment methods into clean user-readable mix
const formatPaymentMix = (rawMix = {}, totalGmv = 1) => {
  const aggregated = {};

  Object.entries(rawMix).forEach(([rawKey, amountVal]) => {
    const amount = Number(amountVal || 0);
    if (amount <= 0 && Object.keys(rawMix).length > 1) return;

    let cleanName = 'Other Payment';
    let icon = CreditCard;
    let color = '#ea580c';
    let badgeText = 'Online';
    let txnId = null;

    const lower = String(rawKey || '').toLowerCase();

    if (lower.includes('razorpay') || lower.includes('rzp') || lower.includes('pay_')) {
      cleanName = 'Razorpay (Online)';
      icon = CreditCard;
      color = '#2563eb';
      badgeText = 'Instant Gateway';

      if (rawKey.startsWith('{')) {
        try {
          const parsed = JSON.parse(rawKey);
          if (parsed.razorpayPaymentId) txnId = parsed.razorpayPaymentId;
        } catch (_) {}
      } else {
        const match = rawKey.match(/pay_[a-zA-Z0-9]+/);
        if (match) txnId = match[0];
      }
    } else if (lower.includes('cash')) {
      cleanName = 'Cash';
      icon = Banknote;
      color = '#10b981';
      badgeText = 'Counter Cash';
    } else if (lower.includes('card') || lower.includes('pos')) {
      cleanName = 'Card (POS)';
      icon = CreditCard;
      color = '#8b5cf6';
      badgeText = 'Terminal POS';
    } else if (lower.includes('upi') || lower.includes('qr') || lower.includes('gpay') || lower.includes('phonepe') || lower.includes('paytm')) {
      cleanName = 'UPI / QR Code';
      icon = Smartphone;
      color = '#06b6d4';
      badgeText = 'Instant UPI';
    } else {
      cleanName = rawKey.length > 25 ? 'Direct Online' : rawKey.toUpperCase();
      icon = Wallet;
      color = '#f59e0b';
      badgeText = 'Digital';
    }

    if (!aggregated[cleanName]) {
      aggregated[cleanName] = {
        name: cleanName,
        icon,
        color,
        badgeText,
        amount: 0,
        count: 0,
        txns: []
      };
    }

    aggregated[cleanName].amount += amount;
    aggregated[cleanName].count += 1;
    if (txnId && !aggregated[cleanName].txns.includes(txnId)) {
      aggregated[cleanName].txns.push(txnId);
    }
  });

  return Object.values(aggregated).map(item => {
    const safeGmv = totalGmv > 0 ? totalGmv : (item.amount || 1);
    const pct = Math.min(100, Math.round((item.amount / safeGmv) * 100));
    return {
      ...item,
      percentage: pct
    };
  });
};

export default function ReportsAnalyticsManager({ showToast }) {
  // Main Data States
  const [dailySales, setDailySales] = useState(null);
  const [xReport, setXReport] = useState(null);
  const [zReportHistory, setZReportHistory] = useState(null);
  const [itemPerformance, setItemPerformance] = useState(null);
  const [foodCost, setFoodCost] = useState(null);
  const [tableAnalytics, setTableAnalytics] = useState(null);
  const [deliveryAnalytics, setDeliveryAnalytics] = useState(null);
  const [customerAnalytics, setCustomerAnalytics] = useState(null);
  const [staffProductivity, setStaffProductivity] = useState([]);
  const [outlets, setOutlets] = useState([]);
  const [loading, setLoading] = useState(false);

  // Filters & Tabs
  const [activeTab, setActiveTab] = useState('DAILY_SALES'); 
  // 'DAILY_SALES', 'SHIFT_REPORTS', 'ITEM_PERFORMANCE', 'FOOD_COST', 'TABLE_DELIVERY', 'STAFF_CUSTOMER'

  const [startDate, setStartDate] = useState(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10));
  const [endDate, setEndDate] = useState(new Date().toISOString().substring(0, 10));
  const [selectedOutletId, setSelectedOutletId] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');

  // Modals
  const [showZReportModal, setShowZReportModal] = useState(false);
  const [zReportDate, setZReportDate] = useState(new Date().toISOString().substring(0, 10));

  useEffect(() => {
    fetchOutlets();
    fetchReports();
  }, [startDate, endDate, selectedOutletId, categoryFilter]);

  const fetchOutlets = async () => {
    try {
      const res = await apiRequest('/api/v1/chain/outlets');
      const outs = Array.isArray(res) ? res : [];
      setOutlets(outs);
    } catch (err) {
      console.error('Error loading outlets:', err);
    }
  };

  const fetchReports = async () => {
    setLoading(true);
    try {
      let outletParam = selectedOutletId ? `&outletId=${selectedOutletId}` : '';
      let dateParams = `startDate=${startDate}&endDate=${endDate}${outletParam}`;

      const [
        dailySalesRes,
        xReportRes,
        itemPerfRes,
        foodCostRes,
        tableRes,
        deliveryRes,
        custRes,
        staffRes
      ] = await Promise.all([
        apiRequest(`/api/v1/analytics/daily-sales?${dateParams}`).catch(() => null),
        apiRequest(`/api/v1/analytics/x-report?${selectedOutletId ? `outletId=${selectedOutletId}` : ''}`).catch(() => null),
        apiRequest(`/api/v1/analytics/item-performance?${dateParams}${categoryFilter ? `&category=${categoryFilter}` : ''}`).catch(() => null),
        apiRequest(`/api/v1/analytics/food-cost?${selectedOutletId ? `outletId=${selectedOutletId}` : ''}`).catch(() => null),
        apiRequest(`/api/v1/analytics/table-analytics?${selectedOutletId ? `outletId=${selectedOutletId}` : ''}`).catch(() => null),
        apiRequest(`/api/v1/analytics/delivery-report?${selectedOutletId ? `outletId=${selectedOutletId}` : ''}`).catch(() => null),
        apiRequest('/api/v1/analytics/customer-analytics').catch(() => null),
        apiRequest(`/api/v1/analytics/staff-productivity?${selectedOutletId ? `outletId=${selectedOutletId}` : ''}`).catch(() => []),
      ]);

      setDailySales(dailySalesRes);
      setXReport(xReportRes);
      setItemPerformance(itemPerfRes);
      setFoodCost(foodCostRes);
      setTableAnalytics(tableRes);
      setDeliveryAnalytics(deliveryRes);
      setCustomerAnalytics(custRes);
      setStaffProductivity(Array.isArray(staffRes) ? staffRes : []);
    } catch (err) {
      console.error('Error fetching analytics reports:', err);
    } finally {
      setLoading(false);
    }
  };

  // Generate Z-Report (End-of-Day EOD Settlement)
  const handleGenerateZReport = async (e) => {
    e.preventDefault();
    try {
      let url = `/api/v1/analytics/z-report?date=${zReportDate}`;
      if (selectedOutletId) url += `&outletId=${selectedOutletId}`;

      const res = await apiRequest(url, 'POST');
      setZReportHistory(res);
      if (showToast) showToast(`Z-Report generated and EOD shift closed for ${zReportDate}!`, 'success');
      setShowZReportModal(false);
    } catch (err) {
      if (showToast) showToast(err.message || 'Z-Report generation failed', 'error');
    }
  };

  return (
    <div className="reports-analytics-manager">
      {/* Top Filter Bar & Summary Header */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <BarChart3 size={22} className="text-secondary-custom" />
              Executive Financial & Sales Analytics
            </h5>
            <span className="text-muted-custom small">
              Real-time daily sales, X/Z audit shift reports, item sell-through, recipe food costs & staff productivity
            </span>
          </div>

          <div className="d-flex flex-wrap gap-2 align-items-center">
            <div className="d-flex align-items-center gap-1 bg-card-custom p-1 rounded-2 border border-custom">
              <Calendar size={14} className="ms-1 text-muted-custom" />
              <input
                type="date"
                className="form-control form-control-sm border-0 bg-transparent text-main"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
              <span className="text-muted-custom small">to</span>
              <input
                type="date"
                className="form-control form-control-sm border-0 bg-transparent text-main"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
              />
            </div>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowZReportModal(true)}>
              <Printer size={14} className="me-1 text-danger" /> Generate Z-Report
            </button>
          </div>
        </div>

        {/* Global Executive KPIs Strip */}
        <div className="row g-3 pt-2 border-top border-custom align-items-center">
          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Gross Sales (GMV):</span>
              <h5 className="fw-extrabold text-main m-0">
                ₹{dailySales ? Number(dailySales.gmv || 0).toLocaleString() : '0'}
              </h5>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Total Guest Covers:</span>
              <h5 className="fw-extrabold text-main m-0">
                {dailySales ? dailySales.totalCovers || 0 : 0} Covers
              </h5>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Average Order Value (AOV):</span>
              <h5 className="fw-extrabold text-danger m-0">
                ₹{dailySales ? Number(dailySales.aov || 0).toFixed(2) : '0.00'}
              </h5>
            </div>
          </div>

          <div className="col-6 col-md-3">
            <div className="p-2 bg-card-custom rounded-2 border border-custom">
              <span className="small text-muted-custom d-block">Food Cost Percentage:</span>
              <h5 className="fw-extrabold text-success m-0">
                {foodCost ? Number(foodCost.foodCostPercentage || 0).toFixed(1) : 0}%
              </h5>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs Navigation */}
      <div className="d-flex gap-2 mb-4 overflow-auto">
        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'DAILY_SALES' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('DAILY_SALES')}
        >
          Daily Sales & Payment Mix
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'SHIFT_REPORTS' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('SHIFT_REPORTS')}
        >
          Shift X-Report & EOD Z-Audit
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'ITEM_PERFORMANCE' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('ITEM_PERFORMANCE')}
        >
          Item Sell-Through & Best Sellers
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'FOOD_COST' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('FOOD_COST')}
        >
          Food Cost & Recipe Margin Analysis
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'TABLE_DELIVERY' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('TABLE_DELIVERY')}
        >
          Table Occupancy & Delivery Analytics
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'STAFF_CUSTOMER' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('STAFF_CUSTOMER')}
        >
          Staff Productivity & Guest Feedback
        </button>
      </div>

      {/* TAB 1: DAILY SALES & PAYMENT MIX */}
      {activeTab === 'DAILY_SALES' && (
        <div className="row g-4">
          {/* Payment Method Breakdown */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4 h-100">
              <div className="d-flex justify-content-between align-items-center mb-3">
                <h6 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
                  <PieChart size={18} className="text-secondary-custom" />
                  Settled Payment Method Mix
                </h6>
                {dailySales?.paymentMethodMix && (
                  <span className="badge bg-card-custom border border-custom text-muted-custom small fw-normal">
                    {formatPaymentMix(dailySales.paymentMethodMix, Number(dailySales.gmv || 0)).reduce((sum, i) => sum + i.count, 0)} Total
                  </span>
                )}
              </div>

              {dailySales?.paymentMethodMix && Object.keys(dailySales.paymentMethodMix).length > 0 ? (
                <div className="d-flex flex-column gap-3">
                  {formatPaymentMix(dailySales.paymentMethodMix, Number(dailySales.gmv || 0)).map((item) => {
                    const MethodIcon = item.icon;

                    return (
                      <div key={item.name} className="p-3 bg-card-custom rounded-3 border border-custom shadow-xs">
                        <div className="d-flex justify-content-between align-items-start mb-2">
                          <div className="d-flex align-items-center gap-2">
                            <div
                              className="d-flex align-items-center justify-content-center rounded-3 p-2"
                              style={{ background: `${item.color}18`, color: item.color, width: 36, height: 36 }}
                            >
                              <MethodIcon size={18} />
                            </div>
                            <div>
                              <span className="fw-bold text-main d-block" style={{ fontSize: '0.95rem' }}>{item.name}</span>
                              <span className="text-muted-custom" style={{ fontSize: '0.72rem' }}>
                                {item.count} {item.count === 1 ? 'order' : 'orders'} · {item.badgeText}
                              </span>
                            </div>
                          </div>
                          <div className="text-end">
                            <span className="fw-extrabold text-main d-block" style={{ fontSize: '1.05rem' }}>
                              ₹{item.amount.toLocaleString()}
                            </span>
                            <span className="badge rounded-pill fw-semibold" style={{ background: `${item.color}22`, color: item.color, fontSize: '0.72rem' }}>
                              {item.percentage}%
                            </span>
                          </div>
                        </div>

                        {/* Progress Bar */}
                        <div className="progress" style={{ height: '7px', backgroundColor: 'rgba(0,0,0,0.06)', borderRadius: '999px' }}>
                          <div
                            className="progress-bar rounded-pill"
                            role="progressbar"
                            style={{ width: `${item.percentage}%`, backgroundColor: item.color }}
                            aria-valuenow={item.percentage}
                            aria-valuemin="0"
                            aria-valuemax="100"
                          />
                        </div>

                        {/* Clean Reference IDs */}
                        {item.txns && item.txns.length > 0 && (
                          <div className="mt-2 pt-2 border-top border-custom d-flex flex-wrap align-items-center gap-1">
                            <span className="text-muted-custom" style={{ fontSize: '0.68rem' }}>Ref:</span>
                            {item.txns.slice(0, 3).map((ref) => (
                              <code
                                key={ref}
                                className="px-2 py-0 rounded text-muted-custom border border-custom bg-surface"
                                style={{ fontSize: '0.65rem' }}
                                title={ref}
                              >
                                {ref.length > 18 ? `${ref.substring(0, 16)}…` : ref}
                              </code>
                            ))}
                            {item.txns.length > 3 && (
                              <span className="text-muted-custom small" style={{ fontSize: '0.65rem' }}>
                                +{item.txns.length - 3} more
                              </span>
                            )}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="text-muted-custom small">No settled bills data for this range.</p>
              )}
            </div>
          </div>

          {/* Hourly Revenue Trend */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4 h-100">
              <h6 className="fw-bold text-main mb-3 d-flex align-items-center gap-2">
                <Clock size={18} className="text-primary" />
                Hourly Peak Revenue Distribution
              </h6>
              {dailySales?.hourlyRevenueTrend ? (
                <div className="d-flex flex-column gap-2 overflow-auto" style={{ maxHeight: '350px' }}>
                  {Object.keys(dailySales.hourlyRevenueTrend).map((hour) => {
                    const rev = Number(dailySales.hourlyRevenueTrend[hour] || 0);
                    return (
                      <div key={hour} className="d-flex justify-content-between align-items-center p-2 bg-card-custom rounded border border-custom text-main small">
                        <span>{hour}:00 — {Number(hour) + 1}:00</span>
                        <span className="fw-bold text-success">₹{rev.toLocaleString()}</span>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="text-muted-custom small">No hourly sales trend recorded.</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: SHIFT X-REPORT & Z-AUDIT */}
      {activeTab === 'SHIFT_REPORTS' && (
        <div className="row g-4">
          {/* X-Report Card */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4 h-100">
              <h6 className="fw-bold text-main mb-2 d-flex align-items-center gap-2">
                <Zap size={18} className="text-warning" />
                Live Shift X-Report Snapshot
              </h6>
              <p className="text-muted-custom small mb-3">
                Current running totals for active shift starting at {xReport?.shiftStartTime ? new Date(xReport.shiftStartTime).toLocaleTimeString() : '08:00 AM'}.
              </p>

              {xReport && (
                <div className="d-flex flex-column gap-2">
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between align-items-center">
                    <span className="text-muted-custom">Live Sales Settled:</span>
                    <span className="fw-bold text-success fs-5">₹{Number(xReport.liveSales || 0).toLocaleString()}</span>
                  </div>

                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between align-items-center">
                    <span className="text-muted-custom">Live Seated Covers:</span>
                    <span className="fw-bold text-main">{xReport.liveCovers || 0} Guests</span>
                  </div>

                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between align-items-center">
                    <span className="text-muted-custom">Open Orders Count:</span>
                    <span className="fw-bold text-danger">{xReport.openOrdersCount || 0} Orders</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Z-Report Action Card */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4 h-100">
              <h6 className="fw-bold text-main mb-2 d-flex align-items-center gap-2">
                <Printer size={18} className="text-danger" />
                End-of-Day Z-Report Settlement Audit
              </h6>
              <p className="text-muted-custom small mb-3">
                Official EOD cash register close & tax audit generation.
              </p>

              {zReportHistory ? (
                <div className="p-3 bg-card-custom rounded-3 border border-custom text-main small">
                  <h6 className="fw-bold text-success mb-2">Z-Report #{zReportHistory.reportId ? String(zReportHistory.reportId).substring(0, 6) : 'EOD'}</h6>
                  <div className="d-flex justify-content-between mb-1">
                    <span>Total Net Sales:</span>
                    <span className="fw-bold">₹{Number(zReportHistory.totalSales || 0).toFixed(2)}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1">
                    <span>Cash Collected:</span>
                    <span className="fw-bold">₹{Number(zReportHistory.cashCollected || 0).toFixed(2)}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1">
                    <span>Card Collected:</span>
                    <span className="fw-bold">₹{Number(zReportHistory.cardCollected || 0).toFixed(2)}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1">
                    <span>UPI Collected:</span>
                    <span className="fw-bold">₹{Number(zReportHistory.upiCollected || 0).toFixed(2)}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1">
                    <span>Total Tips:</span>
                    <span className="fw-bold text-primary">₹{Number(zReportHistory.totalTips || 0).toFixed(2)}</span>
                  </div>
                </div>
              ) : (
                <button className="btn btn-secondary touch-btn fw-bold w-100 py-3" onClick={() => setShowZReportModal(true)}>
                  Generate & Close Today's Z-Report
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: ITEM PERFORMANCE & BEST SELLERS */}
      {activeTab === 'ITEM_PERFORMANCE' && (
        <div className="row g-4">
          {/* Top 10 Best Sellers by Revenue */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4">
              <h6 className="fw-bold text-main mb-3 d-flex align-items-center gap-2">
                <Award size={18} className="text-warning" />
                Top 10 Dishes by Total Revenue
              </h6>
              <div className="table-responsive">
                <table className="table table-hover align-middle mb-0 text-main small">
                  <thead>
                    <tr>
                      <th>Dish Name</th>
                      <th>Units Sold</th>
                      <th>Revenue</th>
                    </tr>
                  </thead>
                  <tbody>
                    {itemPerformance?.top10ByRevenue?.map((i, idx) => (
                      <tr key={idx}>
                        <td className="fw-bold">{i.itemName}</td>
                        <td>{i.unitsSold} Qty</td>
                        <td className="fw-bold text-danger">₹{Number(i.totalRevenue || 0).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Bottom 10 Slowest Selling Dishes */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4">
              <h6 className="fw-bold text-main mb-3 d-flex align-items-center gap-2">
                <ShieldAlert size={18} className="text-danger" />
                Slow Movers (Bottom 10 by Units Sold)
              </h6>
              <div className="table-responsive">
                <table className="table table-hover align-middle mb-0 text-main small">
                  <thead>
                    <tr>
                      <th>Dish Name</th>
                      <th>Units Sold</th>
                      <th>Total Revenue</th>
                    </tr>
                  </thead>
                  <tbody>
                    {itemPerformance?.bottom10ByUnits?.map((i, idx) => (
                      <tr key={idx}>
                        <td className="fw-bold">{i.itemName}</td>
                        <td className="text-warning fw-bold">{i.unitsSold} Qty</td>
                        <td>₹{Number(i.totalRevenue || 0).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 4: FOOD COST & RECIPE MARGIN ANALYSIS */}
      {activeTab === 'FOOD_COST' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <h6 className="fw-bold text-main mb-3">Theoretical Ingredient Food Cost vs Revenue</h6>
          {foodCost && (
            <div className="row g-4">
              <div className="col-12 col-md-4">
                <div className="p-3 bg-card-custom rounded-3 border border-custom">
                  <span className="text-muted-custom small d-block mb-1">Total Food Sales Value:</span>
                  <h4 className="fw-bold text-main m-0">₹{Number(foodCost.totalSalesValue || 0).toLocaleString()}</h4>
                </div>
              </div>

              <div className="col-12 col-md-4">
                <div className="p-3 bg-card-custom rounded-3 border border-custom">
                  <span className="text-muted-custom small d-block mb-1">Theoretical Ingredient Cost:</span>
                  <h4 className="fw-bold text-danger m-0">₹{Number(foodCost.theoreticalIngredientCost || 0).toLocaleString()}</h4>
                </div>
              </div>

              <div className="col-12 col-md-4">
                <div className="p-3 bg-card-custom rounded-3 border border-custom">
                  <span className="text-muted-custom small d-block mb-1">Overall Food Cost Percentage:</span>
                  <h4 className="fw-extrabold text-success m-0">{Number(foodCost.foodCostPercentage || 0).toFixed(1)}%</h4>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* TAB 5: TABLE OCCUPANCY & DELIVERY ANALYTICS */}
      {activeTab === 'TABLE_DELIVERY' && (
        <div className="row g-4">
          {/* Table Analytics */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4 h-100">
              <h6 className="fw-bold text-main mb-3">Table Occupancy & Turn Time</h6>
              {tableAnalytics && (
                <div className="d-flex flex-column gap-2 text-main small">
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>Avg Table Turn Time:</span>
                    <span className="fw-bold text-secondary-custom">{Number(tableAnalytics.averageTableTurnTimeMinutes || 0).toFixed(1)} Mins</span>
                  </div>
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>Covers Per Table / Day:</span>
                    <span className="fw-bold text-main">{Number(tableAnalytics.coversPerTablePerDay || 0).toFixed(1)} Guests</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Delivery & Takeaway Analytics */}
          <div className="col-12 col-md-6">
            <div className="card bg-surface border-custom shadow-sm p-4 h-100">
              <h6 className="fw-bold text-main mb-3 d-flex align-items-center gap-2">
                <Truck size={18} className="text-primary" />
                Delivery & Takeaway Performance
              </h6>
              {deliveryAnalytics && (
                <div className="d-flex flex-column gap-2 text-main small">
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>Delivery Orders:</span>
                    <span className="fw-bold text-success">{deliveryAnalytics.totalDeliveryOrders || 0} Orders (₹{Number(deliveryAnalytics.totalDeliveryRevenue || 0).toLocaleString()})</span>
                  </div>
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>Takeaway Orders:</span>
                    <span className="fw-bold text-warning">{deliveryAnalytics.totalTakeawayOrders || 0} Orders (₹{Number(deliveryAnalytics.totalTakeawayRevenue || 0).toLocaleString()})</span>
                  </div>
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>Avg Delivery Fulfillment Speed:</span>
                    <span className="fw-bold text-danger">{deliveryAnalytics.averageDeliveryTimeMinutes || 28.5} Mins</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 6: STAFF PRODUCTIVITY & CUSTOMER FEEDBACK */}
      {activeTab === 'STAFF_CUSTOMER' && (
        <div className="row g-4">
          {/* Staff Productivity Table */}
          <div className="col-12 col-md-8">
            <div className="card bg-surface border-custom shadow-sm p-4">
              <h6 className="fw-bold text-main mb-3">Waitstaff & Captain Sales Productivity</h6>
              <div className="table-responsive">
                <table className="table table-hover align-middle mb-0 text-main small">
                  <thead>
                    <tr>
                      <th>Staff Name</th>
                      <th>Role</th>
                      <th>Orders Served</th>
                      <th>Total Sales Generated</th>
                    </tr>
                  </thead>
                  <tbody>
                    {staffProductivity.length === 0 ? (
                      <tr>
                        <td colSpan="4" className="text-center py-4 text-muted-custom">No staff productivity metrics generated.</td>
                      </tr>
                    ) : (
                      staffProductivity.map((s, idx) => (
                        <tr key={idx}>
                          <td className="fw-bold">{s.staffName}</td>
                          <td><span className="badge bg-secondary text-white">{s.role || 'CAPTAIN'}</span></td>
                          <td>{s.totalOrders || 0} Orders</td>
                          <td className="fw-bold text-success">₹{Number(s.totalSalesGenerated || 0).toLocaleString()}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Customer Retention Card */}
          <div className="col-12 col-md-4">
            <div className="card bg-surface border-custom shadow-sm p-4 h-100">
              <h6 className="fw-bold text-main mb-3 d-flex align-items-center gap-2">
                <Star size={18} className="text-warning" fill="currentColor" />
                Customer Retention & Feedback Score
              </h6>
              {customerAnalytics && (
                <div className="d-flex flex-column gap-2 text-main small">
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>New Guest Visits:</span>
                    <span className="fw-bold text-primary">{customerAnalytics.newVisits || 0} Guests</span>
                  </div>
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>Repeat Returning Guests:</span>
                    <span className="fw-bold text-success">{customerAnalytics.returningVisits || 0} Guests</span>
                  </div>
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between">
                    <span>Loyalty Redemption Rate:</span>
                    <span className="fw-bold text-secondary-custom">{customerAnalytics.loyaltyRedemptionRate || 15}%</span>
                  </div>
                  <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex justify-content-between align-items-center">
                    <span>Avg Star Rating:</span>
                    <span className="badge bg-warning text-dark fw-bold fs-6">
                      ★ {Number(customerAnalytics.averageFeedbackScore || 5.0).toFixed(1)} / 5.0
                    </span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL: GENERATE Z-REPORT                                   */}
      {/* ========================================================= */}
      {showZReportModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <Printer size={20} className="text-danger" />
                  Generate End-of-Day Z-Report
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowZReportModal(false)}></button>
              </div>

              <form onSubmit={handleGenerateZReport}>
                <div className="modal-body">
                  <p className="text-muted-custom small mb-3">
                    Closing the shift and generating official Z-Report will lock today's cash register totals and compute tax audit figures.
                  </p>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Settlement Audit Date *</label>
                    <input
                      type="date"
                      className="form-control"
                      required
                      value={zReportDate}
                      onChange={(e) => setZReportDate(e.target.value)}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowZReportModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-danger fw-bold px-4">
                    Confirm & Print Z-Report
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
