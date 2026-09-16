import React, { useState, useEffect, useMemo } from 'react';
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
  Smartphone,
  Banknote,
  ChevronDown,
  ChevronUp,
  Wallet
} from 'lucide-react';

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
  const [expandedChannel, setExpandedChannel] = useState(null);

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

  // Format and consolidate payment method mix into user-understandable channels
  const formattedPaymentMix = useMemo(() => {
    if (!dailySales?.paymentMethodMix) return [];
    const rawMix = dailySales.paymentMethodMix;
    const totalGmv = Number(dailySales.gmv || 0);

    const channels = {
      RAZORPAY: {
        id: 'RAZORPAY',
        name: 'Razorpay Online & UPI',
        subtitle: 'Digital Gateway (Cards, UPI, Netbanking)',
        type: 'razorpay',
        color: '#2563eb',
        bgLight: '#eff6ff',
        total: 0,
        count: 0,
        transactions: [],
      },
      CASH: {
        id: 'CASH',
        name: 'Cash Payment',
        subtitle: 'Counter Cash & Cash on Delivery',
        type: 'cash',
        color: '#10b981',
        bgLight: '#f0fdf4',
        total: 0,
        count: 0,
        transactions: [],
      },
      CARD: {
        id: 'CARD',
        name: 'Credit & Debit Card',
        subtitle: 'POS Terminal Card Swipes',
        type: 'card',
        color: '#f59e0b',
        bgLight: '#fffbeb',
        total: 0,
        count: 0,
        transactions: [],
      },
      UPI: {
        id: 'UPI',
        name: 'Direct UPI / QR Code',
        subtitle: 'Instant Dynamic & Counter QR Scan',
        type: 'upi',
        color: '#8b5cf6',
        bgLight: '#f5f3ff',
        total: 0,
        count: 0,
        transactions: [],
      },
      WALLET: {
        id: 'WALLET',
        name: 'Digital Wallet',
        subtitle: 'Prepaid & Mobile Wallets',
        type: 'wallet',
        color: '#ec4899',
        bgLight: '#fdf2f8',
        total: 0,
        count: 0,
        transactions: [],
      },
      OTHER: {
        id: 'OTHER',
        name: 'Other Payment Method',
        subtitle: 'Miscellaneous Tender',
        type: 'other',
        color: '#6b7280',
        bgLight: '#f3f4f6',
        total: 0,
        count: 0,
        transactions: [],
      },
    };

    Object.entries(rawMix).forEach(([rawKey, amtVal]) => {
      const amount = Number(amtVal) || 0;
      let targetChannel = 'OTHER';
      let txnId = '';
      let status = 'PAID';

      const trimmed = String(rawKey).trim();
      const upperKey = trimmed.toUpperCase();

      if (trimmed.startsWith('{')) {
        try {
          const parsed = JSON.parse(trimmed);
          if (parsed.razorpayPaymentId || parsed.paymentId) {
            targetChannel = 'RAZORPAY';
            txnId = parsed.razorpayPaymentId || parsed.paymentId;
          }
          if (parsed.status) status = parsed.status;
        } catch {
          if (upperKey.includes('RAZORPAY') || upperKey.includes('PAY_')) {
            targetChannel = 'RAZORPAY';
          }
        }
      } else if (upperKey.includes('RAZORPAY') || upperKey.includes('PAY_')) {
        targetChannel = 'RAZORPAY';
        const match = trimmed.match(/Txn:\s*([a-zA-Z0-9_]+)/);
        if (match) txnId = match[1];
      } else if (upperKey.includes('CASH')) {
        targetChannel = 'CASH';
      } else if (upperKey.includes('CARD')) {
        targetChannel = 'CARD';
      } else if (upperKey.includes('UPI')) {
        targetChannel = 'UPI';
      } else if (upperKey.includes('WALLET')) {
        targetChannel = 'WALLET';
      }

      if (!txnId && trimmed.length > 20) {
        const payMatch = trimmed.match(/(pay_[a-zA-Z0-9]+)/);
        if (payMatch) txnId = payMatch[1];
      }

      channels[targetChannel].total += amount;
      channels[targetChannel].count += 1;

      channels[targetChannel].transactions.push({
        txnId: txnId || `Txn #${channels[targetChannel].count}`,
        amount,
        status,
        raw: trimmed,
      });
    });

    const computedGmv = totalGmv || Object.values(channels).reduce((acc, c) => acc + c.total, 0) || 1;

    return Object.values(channels)
      .filter((c) => c.total > 0 || c.count > 0)
      .map((c) => ({
        ...c,
        pct: Math.round((c.total / computedGmv) * 100),
      }))
      .sort((a, b) => b.total - a.total);
  }, [dailySales]);

  const renderChannelIcon = (type) => {
    switch (type) {
      case 'razorpay': return <Zap size={18} className="text-primary" />;
      case 'cash': return <Banknote size={18} className="text-success" />;
      case 'card': return <CreditCard size={18} className="text-warning" />;
      case 'upi': return <Smartphone size={18} style={{ color: '#8b5cf6' }} />;
      case 'wallet': return <Wallet size={18} style={{ color: '#ec4899' }} />;
      default: return <Layers size={18} className="text-secondary" />;
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

            <select
              className="form-select form-select-sm bg-card-custom border-custom text-main"
              style={{ width: '160px' }}
              value={selectedOutletId}
              onChange={(e) => setSelectedOutletId(e.target.value)}
            >
              <option value="">All Outlets</option>
              {outlets.map(o => (
                <option key={o.outletId || o.id} value={o.outletId || o.id}>{o.name}</option>
              ))}
            </select>

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
              <div className="d-flex justify-content-between align-items-center mb-1">
                <div className="d-flex align-items-center gap-2">
                  <PieChart size={18} className="text-secondary-custom" />
                  <h6 className="fw-bold text-main m-0">Settled Payment Method Mix</h6>
                </div>
                <span className="badge bg-card-custom border border-custom text-muted-custom small">
                  {formattedPaymentMix.length} {formattedPaymentMix.length === 1 ? 'Channel' : 'Channels'}
                </span>
              </div>
              <span className="text-muted-custom small d-block mb-3">
                Consolidated revenue breakdown by customer payment channel
              </span>

              {/* Total Settled GMV Mini Summary */}
              {formattedPaymentMix.length > 0 && (
                <div className="d-flex align-items-center justify-content-between p-2 mb-3 bg-card-custom rounded-2 border border-custom small">
                  <span className="text-muted-custom">Total Settled Revenue:</span>
                  <span className="fw-extrabold text-main fs-6">₹{Number(dailySales?.gmv || 0).toLocaleString()}</span>
                </div>
              )}

              {formattedPaymentMix.length > 0 ? (
                <div className="d-flex flex-column gap-3">
                  {formattedPaymentMix.map((channel) => {
                    const isExpanded = expandedChannel === channel.id;

                    return (
                      <div 
                        key={channel.id} 
                        className="bg-card-custom rounded-3 border border-custom p-3"
                      >
                        {/* Channel Header */}
                        <div className="d-flex justify-content-between align-items-center mb-2">
                          <div className="d-flex align-items-center gap-2">
                            <div 
                              className="p-2 rounded-2 d-flex align-items-center justify-content-center"
                              style={{ backgroundColor: channel.bgLight }}
                            >
                              {renderChannelIcon(channel.type)}
                            </div>
                            <div>
                              <span className="fw-bold text-main d-block lh-sm">{channel.name}</span>
                              <span className="text-muted-custom style-micro">
                                {channel.subtitle} • {channel.count} {channel.count === 1 ? 'payment' : 'payments'}
                              </span>
                            </div>
                          </div>

                          <div className="text-end">
                            <span className="fw-extrabold text-main d-block">
                              ₹{channel.total.toLocaleString()}
                            </span>
                            <span 
                              className="badge rounded-pill small px-2 py-0"
                              style={{ backgroundColor: channel.bgLight, color: channel.color, border: `1px solid ${channel.color}30` }}
                            >
                              {channel.pct}% of total
                            </span>
                          </div>
                        </div>

                        {/* Progress Bar */}
                        <div className="progress rounded-pill bg-surface border border-custom" style={{ height: '7px' }}>
                          <div 
                            className="progress-bar rounded-pill" 
                            style={{ 
                              width: `${Math.max(channel.pct, 4)}%`, 
                              backgroundColor: channel.color,
                              transition: 'width 0.4s ease'
                            }}
                          ></div>
                        </div>

                        {/* Transaction Audit Breakdown Accordion */}
                        {channel.transactions.length > 0 && (
                          <div className="mt-2 pt-2 border-top border-custom">
                            <button
                              type="button"
                              className="btn btn-sm btn-link text-decoration-none p-0 text-muted-custom style-micro fw-semibold d-flex align-items-center gap-1"
                              onClick={() => setExpandedChannel(isExpanded ? null : channel.id)}
                            >
                              {isExpanded ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
                              {isExpanded ? 'Hide' : 'View'} transaction audit ({channel.transactions.length} records)
                            </button>

                            {isExpanded && (
                              <div className="mt-2 d-flex flex-column gap-1 bg-surface p-2 rounded-2 border border-custom overflow-auto" style={{ maxHeight: '180px' }}>
                                {channel.transactions.map((txn, idx) => (
                                  <div 
                                    key={idx} 
                                    className="d-flex justify-content-between align-items-center p-1 rounded hover-bg small font-monospace"
                                    style={{ fontSize: '0.78rem' }}
                                  >
                                    <span className="text-main text-truncate me-2" title={txn.txnId}>
                                      {txn.txnId}
                                    </span>
                                    <div className="d-flex align-items-center gap-2 flex-shrink-0">
                                      <span className="badge bg-success bg-opacity-10 text-success border border-success py-0 px-1 style-micro">
                                        {txn.status || 'PAID'}
                                      </span>
                                      <span className="fw-bold text-main">
                                        ₹{txn.amount.toLocaleString()}
                                      </span>
                                    </div>
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="text-muted-custom small py-4 text-center">No settled bills data for this date range.</p>
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
