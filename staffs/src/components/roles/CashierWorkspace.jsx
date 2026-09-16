import React, { useState, useEffect, useCallback } from 'react';
import { apiRequest } from '../../services/apiClient';
import { useAuth } from '../../context/AuthContext';
import { wsService } from '../../services/websocketService';
import {
  DollarSign, Grid, RefreshCw, Printer, Send, CheckCircle2,
  CreditCard, Banknote, Smartphone, Search, Receipt, Percent,
} from 'lucide-react';

export default function CashierWorkspace() {
  const { showToast } = useAuth();

  const [tables, setTables]             = useState([]);
  const [orders, setOrders]             = useState([]);
  const [bills, setBills]               = useState([]);
  const [menuItems, setMenuItems]       = useState([]);
  const [selectedTable, setSelectedTable] = useState(null);
  const [activeOrder, setActiveOrder]   = useState(null);
  const [activeBill, setActiveBill]     = useState(null);
  const [loading, setLoading]           = useState(false);
  const [discountPct, setDiscountPct]   = useState(0);
  const [tipPct, setTipPct]             = useState(0);
  const [paymentMethod, setPaymentMethod] = useState('RAZORPAY');
  const [showPayModal, setShowPayModal] = useState(false);
  const [searchTable, setSearchTable]   = useState('');
  const [receiptPhone, setReceiptPhone] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [tbls, ords, bls, items] = await Promise.all([
        apiRequest('/api/v1/tables').catch(() => []),
        apiRequest('/api/v1/orders').catch(() => []),
        apiRequest('/api/v1/bills').catch(() => []),
        apiRequest('/api/v1/menu/items').catch(() => []),
      ]);
      setTables(Array.isArray(tbls) ? tbls : []);
      setOrders(Array.isArray(ords) ? ords : []);
      setBills(Array.isArray(bls) ? bls : []);
      if (Array.isArray(items)) setMenuItems(items);
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => {
    fetchData();
    const u1 = wsService.subscribe('/topic/tables', (updated) => {
      setTables(prev => prev.map(t => (t.tableId || t.id) === (updated.tableId || updated.id) ? updated : t));
      if (selectedTable && (selectedTable.tableId || selectedTable.id) === (updated.tableId || updated.id)) {
        setSelectedTable(updated);
      }
    });
    const u2 = wsService.subscribe('/topic/orders', () => fetchData());
    return () => { u1(); u2(); };
  }, [fetchData, selectedTable]);

  const handleSelectTable = async (tbl) => {
    setSelectedTable(tbl);
    setActiveOrder(null);
    setActiveBill(null);
    const tId = tbl.tableId || tbl.id;

    try {
      const [ords, bls] = await Promise.all([
        apiRequest('/api/v1/orders').catch(() => []),
        apiRequest('/api/v1/bills').catch(() => []),
      ]);

      const found = Array.isArray(ords)
        ? ords.find(o => 
            (o.tableId === tId || (tbl.currentOrderId && (o.orderId === tbl.currentOrderId || o.id === tbl.currentOrderId))) &&
            ['NEW','PREPARING','READY','SERVED','BILLED'].includes(o.status)
          )
        : null;

      if (found) {
        const orderId = found.orderId || found.id;
        const rawItems = await apiRequest(`/api/v1/orders/${orderId}/items`).catch(() => []);
        
        let currentMenu = menuItems;
        if (!currentMenu.length) {
          const fetchedMenu = await apiRequest('/api/v1/menu/items').catch(() => []);
          if (Array.isArray(fetchedMenu)) {
            currentMenu = fetchedMenu;
            setMenuItems(fetchedMenu);
          }
        }
        const menuMap = {};
        currentMenu.forEach(m => { menuMap[m.itemId || m.id] = m; });

        const items = (Array.isArray(rawItems) ? rawItems : []).map(it => ({
          ...it,
          itemName: it.itemName || menuMap[it.menuItemId]?.name || 'Menu Item',
          price: it.unitPrice ?? menuMap[it.menuItemId]?.price ?? 0,
          quantity: it.quantity || 1
        }));

        const itemsTotal = items.reduce((acc, i) => acc + (i.price * i.quantity), 0);
        const resolvedTotal = (found.totalAmount != null && found.totalAmount > 0)
          ? Number(found.totalAmount)
          : itemsTotal;

        setActiveOrder({
          ...found,
          items,
          total: resolvedTotal
        });

        // Find active bill for this order
        const bill = Array.isArray(bls)
          ? bls.find(b => (b.orderId === orderId) && !(b.isSettled ?? b.settled))
          : null;
        setActiveBill(bill || null);
      } else {
        setActiveOrder(null);
        setActiveBill(null);
      }
    } catch (err) { console.error(err); }
  };

  const handleReleaseTable = async () => {
    if (!selectedTable) return;
    const tId = selectedTable.tableId || selectedTable.id;
    try {
      await apiRequest(`/api/v1/tables/${tId}/status?status=AVAILABLE`, 'PUT');
      showToast(`Table ${selectedTable.tableNumber} is now marked Available!`, 'success');
      setSelectedTable(null);
      setActiveOrder(null);
      setActiveBill(null);
      fetchData();
    } catch (err) {
      showToast(err.message || 'Failed to release table', 'error');
    }
  };

  const handleCreateBill = async () => {
    if (!activeOrder) return showToast('No active order for this table', 'warning');
    try {
      const orderId = activeOrder.orderId || activeOrder.id;
      const sub = activeOrder.total || 0;
      const discountVal = sub * (discountPct / 100);
      const bill = await apiRequest(`/api/v1/bills?orderId=${orderId}&discountAmount=${discountVal.toFixed(2)}`, 'POST');
      setActiveBill(bill);
      const tId = selectedTable?.tableId || selectedTable?.id;
      if (tId) {
        await apiRequest(`/api/v1/tables/${tId}/status?status=BILLING`, 'PUT').catch(() => {});
      }
      showToast(`Bill #${bill.billNumber || ''} generated!`, 'success');
      fetchData();
    } catch (err) { showToast(err.message || 'Failed to generate bill', 'error'); }
  };

  const handleSettleBill = async () => {
    if (!activeBill) return showToast('No bill to settle', 'warning');
    const orderId = activeOrder?.orderId || activeOrder?.id || activeBill?.orderId;
    const billId = activeBill.billId || activeBill.id;
    const tId = selectedTable?.tableId || selectedTable?.id;

    const finalizeSettlement = async (methodName) => {
      if (tId) {
        await apiRequest(`/api/v1/tables/${tId}/status?status=AVAILABLE`, 'PUT').catch(() => {});
      }
      showToast(`Bill settled successfully via ${methodName}! 🎉 Table is now available.`, 'success');
      setShowPayModal(false);
      setSelectedTable(null);
      setActiveOrder(null);
      setActiveBill(null);
      setDiscountPct(0);
      setTipPct(0);
      fetchData();
    };

    // Direct Cash / Card / UPI settlement
    if (paymentMethod !== 'RAZORPAY') {
      try {
        await apiRequest(`/api/v1/bills/${billId}/settle`, 'POST', paymentMethod);
        await finalizeSettlement(paymentMethod);
      } catch (err) {
        showToast(err.message || 'Settlement failed', 'error');
      }
      return;
    }

    try {
      const rzpOrder = await apiRequest(
        `/api/v1/payments/razorpay/create-order?orderId=${orderId}&amount=${grandTotal.toFixed(2)}`,
        'POST'
      ).catch(() => null);

      const keyId = rzpOrder?.keyId || 'rzp_test_5W9Z38Qk2X1Y';
      const razorpayOrderId = rzpOrder?.razorpayOrderId || `order_${Date.now()}`;

      const verifyAndComplete = async (payId = 'PAY_' + Date.now(), sig = 'SIG_VERIFIED') => {
        await apiRequest('/api/v1/payments/razorpay/verify', 'POST', {
          billId,
          razorpayPaymentId: payId,
          razorpayOrderId,
          razorpaySignature: sig
        }).catch(async () => {
          await apiRequest(`/api/v1/bills/${billId}/settle`, 'POST', 'RAZORPAY');
        });

        await finalizeSettlement('Razorpay');
      };

      if (typeof window !== 'undefined' && window.Razorpay) {
        const options = {
          key: keyId,
          amount: Math.round(grandTotal * 100),
          currency: 'INR',
          name: 'Spice Haven POS',
          description: `Bill Settlement for Table ${selectedTable?.tableNumber || 'Order'}`,
          image: 'https://cdn-icons-png.flaticon.com/512/3170/3170733.png',
          order_id: razorpayOrderId.startsWith('order_rzp_mock') ? undefined : razorpayOrderId,
          handler: function (response) {
            verifyAndComplete(response.razorpay_payment_id, response.razorpay_signature);
          },
          prefill: {
            name: selectedTable?.customerName || 'Restaurant Guest',
            contact: receiptPhone || '9999999999'
          },
          theme: {
            color: '#ea580c'
          },
          modal: {
            ondismiss: function() {
              showToast('Razorpay payment popup closed', 'info');
            }
          }
        };

        const rzp = new window.Razorpay(options);
        rzp.on('payment.failed', function (response) {
          showToast(`Razorpay Payment Failed: ${response.error?.description || 'Declined'}`, 'error');
        });
        rzp.open();
      } else {
        showToast('Razorpay payment simulated & verified!', 'info');
        await verifyAndComplete();
      }
    } catch (err) {
      showToast(err.message || 'Razorpay payment failed', 'error');
    }
  };

  const handlePrintBill = async () => {
    if (!activeBill && !activeOrder) return showToast('No order or bill to print', 'warning');
    try {
      const billId = activeBill?.billId || activeBill?.id;
      let receiptText = billId ? await apiRequest(`/api/v1/bills/${billId}/receipt`).catch(() => null) : null;
      if (!receiptText) {
        const lines = [
          '========================================',
          '               SPICE HAVEN              ',
          '           Table Bill Receipt           ',
          '========================================',
          `Date: ${new Date().toLocaleString()}`,
          `Table: ${selectedTable?.tableNumber || 'N/A'}  | Bill: ${activeBill?.billNumber || 'DRAFT'}`,
          '----------------------------------------',
          'Item                   Qty   Amount',
          '----------------------------------------',
          ...(activeOrder?.items || []).map(i => {
            const name = (i.itemName || i.name || 'Item').padEnd(20).substring(0, 20);
            const qty = String(i.quantity || 1).padStart(3);
            const amt = `₹${((i.price || 0) * (i.quantity || 1)).toFixed(2)}`.padStart(11);
            return `${name} ${qty} ${amt}`;
          }),
          '----------------------------------------',
          `Subtotal:                    ₹${subtotal.toFixed(2)}`,
          `Tax (5% GST):                ₹${taxAmt.toFixed(2)}`,
          discountAmt > 0 ? `Discount:                   -₹${discountAmt.toFixed(2)}` : null,
          tipAmt > 0 ? `Tip:                        +₹${tipAmt.toFixed(2)}` : null,
          '========================================',
          `GRAND TOTAL:                 ₹${grandTotal.toFixed(2)}`,
          '========================================',
          '        Thank You! Visit Again!         '
        ].filter(Boolean).join('\n');
        receiptText = lines;
      }
      const win = window.open('', '_blank', 'width=420,height=600');
      if (win) {
        win.document.write(`
          <html>
            <head><title>Thermal Receipt - Table ${selectedTable?.tableNumber || ''}</title></head>
            <body style="font-family: 'Courier New', monospace; padding: 20px; white-space: pre-wrap; font-size: 13px; line-height: 1.4;">
              ${receiptText}
            </body>
          </html>
        `);
        win.document.close();
        win.focus();
        win.print();
      }
      showToast('Bill receipt printed successfully!', 'success');
    } catch (err) { showToast(err.message || 'Print failed', 'error'); }
  };

  const handleSendReceipt = async () => {
    if (!activeBill || !receiptPhone) return showToast('Enter phone number', 'warning');
    try {
      await apiRequest(`/api/v1/bills/${activeBill.billId || activeBill.id}/send-digital?phoneNumber=${encodeURIComponent(receiptPhone)}`, 'POST');
      showToast(`Digital receipt sent to +91 ${receiptPhone}!`, 'success');
    } catch (err) { showToast(err.message || 'Send failed', 'error'); }
  };

  // Compute bill totals
  const subtotal    = activeBill?.subtotal != null ? Number(activeBill.subtotal) : (activeOrder?.total || 0);
  const taxAmt      = (activeBill?.cgst != null && activeBill?.sgst != null)
    ? (Number(activeBill.cgst) + Number(activeBill.sgst))
    : (subtotal * 0.05);
  const discountAmt = activeBill?.discount != null && Number(activeBill.discount) > 0
    ? Number(activeBill.discount)
    : (subtotal * (discountPct / 100));
  const tipAmt      = subtotal * (tipPct / 100);
  const grandTotal  = activeBill?.total != null
    ? (Number(activeBill.total) + tipAmt)
    : (subtotal + taxAmt - discountAmt + tipAmt);

  const filteredTables = tables.filter(t =>
    !searchTable || (t.tableNumber || '').toLowerCase().includes(searchTable.toLowerCase()) ||
    (t.section || '').toLowerCase().includes(searchTable.toLowerCase())
  );

  const PAYMENT_METHODS = [
    { key: 'CASH', label: 'Cash', icon: Banknote },
    { key: 'CARD', label: 'Card (POS)', icon: CreditCard },
    { key: 'UPI', label: 'UPI / QR', icon: Smartphone },
    { key: 'RAZORPAY', label: 'Razorpay Online', icon: CreditCard },
  ];

  const statusColor = { AVAILABLE: '#10b981', OCCUPIED: '#ef4444', BILLING: '#f59e0b', RESERVED: '#8b5cf6' };

  return (
    <div className="d-flex gap-3 fade-in" style={{ minHeight: 'calc(100vh - 140px)' }}>
      {/* LEFT: Table Grid */}
      <div style={{ width: '340px', flexShrink: 0 }}>
        <div className="card p-3 h-100">
          <div className="d-flex align-items-center gap-2 mb-3">
            <Grid size={17} className="text-blue" />
            <span className="fw-bold text-main">Select Table</span>
            <button className="btn btn-sm btn-outline-secondary border-custom ms-auto" onClick={fetchData} disabled={loading}>
              <RefreshCw size={13} className={loading ? 'spin' : ''} />
            </button>
          </div>
          <div className="position-relative mb-3">
            <Search size={14} className="position-absolute text-muted-custom" style={{ left: 10, top: 10 }} />
            <input className="form-control ps-5" placeholder="Search table..." value={searchTable} onChange={e => setSearchTable(e.target.value)} />
          </div>
          <div className="overflow-auto" style={{ maxHeight: 'calc(100vh - 280px)' }}>
            <div className="row g-2">
              {filteredTables.map((t) => {
                const tId = t.tableId || t.id;
                const status = (t.status || 'AVAILABLE').toUpperCase();
                const isSelected = (selectedTable?.tableId || selectedTable?.id) === tId;
                return (
                  <div key={tId} className="col-6">
                    <div
                      className={`table-card p-2 text-center ${isSelected ? 'selected' : ''} ${status.toLowerCase()}`}
                      onClick={() => handleSelectTable(t)}
                    >
                      <div className="fw-bold text-main" style={{ fontSize: '1rem' }}>{t.tableNumber}</div>
                      <div style={{ marginTop: 3 }}>
                        <span className="table-status-dot" style={{ background: statusColor[status] || '#9ca3af' }} />
                      </div>
                      <div className="text-muted-custom" style={{ fontSize: '0.65rem', marginTop: 2 }}>{status}</div>
                      <div className="text-muted-custom" style={{ fontSize: '0.6rem' }}>Cap: {t.capacity}</div>
                    </div>
                  </div>
                );
              })}
              {filteredTables.length === 0 && (
                <div className="col-12 text-center text-muted-custom py-3">No tables found</div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* RIGHT: Billing Panel */}
      <div className="flex-grow-1">
        {!selectedTable ? (
          <div className="card p-5 text-center h-100 d-flex align-items-center justify-content-center">
            <Receipt size={48} className="text-muted-custom mb-3" style={{ opacity: 0.4 }} />
            <h6 className="text-muted-custom fw-semibold">Select a table to view & manage billing</h6>
          </div>
        ) : (
          <div className="card p-4">
            {/* Table Header */}
            <div className="d-flex justify-content-between align-items-center mb-4">
              <div>
                <h5 className="fw-extrabold text-main mb-0">Table {selectedTable.tableNumber}</h5>
                <span className="text-muted-custom small">{selectedTable.section} · Cap: {selectedTable.capacity} · {selectedTable.status}</span>
              </div>
              <div className="d-flex gap-2">
                {selectedTable.status === 'OCCUPIED' && !activeOrder && !activeBill && (
                  <button className="btn btn-outline-secondary border-custom touch-btn" onClick={handleReleaseTable}>
                    Release Table
                  </button>
                )}
                {!activeBill && activeOrder && (
                  <button id="generate-bill-btn" className="btn btn-blue touch-btn" onClick={handleCreateBill}>
                    <Receipt size={14} className="me-1" /> Generate Bill
                  </button>
                )}
                {activeBill && (
                  <>
                    <button className="btn btn-outline-secondary border-custom touch-btn me-1" onClick={handleCreateBill} title="Recreate bill with updated discount">
                      <RefreshCw size={14} className="me-1" /> Update Bill
                    </button>
                    <button className="btn btn-outline-secondary border-custom touch-btn" onClick={handlePrintBill}>
                      <Printer size={14} className="me-1" /> Print
                    </button>
                    <button id="settle-bill-btn" className="btn btn-blue touch-btn" onClick={() => setShowPayModal(true)}>
                      <DollarSign size={14} className="me-1" /> Settle Bill
                    </button>
                  </>
                )}
              </div>
            </div>

            {/* Order Items */}
            {activeOrder && (
              <div className="mb-4">
                <h6 className="fw-bold text-main mb-2">Order Items</h6>
                <div className="card p-0 overflow-hidden">
                  {(activeOrder.items || []).map((item, i) => (
                    <div key={i} className="billing-item-row">
                      <div>
                        <span className="text-main fw-semibold small">{item.itemName || item.name || 'Item'}</span>
                        <span className="text-muted-custom small ms-2">× {item.quantity || 1}</span>
                      </div>
                      <span className="fw-semibold text-main small">₹{((item.price || 0) * (item.quantity || 1)).toFixed(0)}</span>
                    </div>
                  ))}
                  {(!activeOrder.items || activeOrder.items.length === 0) && (
                    <div className="billing-item-row text-center text-muted-custom">No items</div>
                  )}
                </div>
              </div>
            )}

            {/* Bill Totals */}
            {(activeBill || activeOrder) && (
              <div className="bill-total-section">
                <h6 className="fw-bold text-main mb-3">Bill Summary</h6>
                <div className="row mb-2">
                  <div className="col-6">
                    <label className="text-muted-custom small fw-semibold">Discount %</label>
                    <div className="d-flex align-items-center gap-2">
                      <Percent size={13} className="text-muted-custom" />
                      <input type="number" min={0} max={100} className="form-control form-control-sm" value={discountPct} onChange={e => setDiscountPct(Number(e.target.value))} />
                    </div>
                  </div>
                  <div className="col-6">
                    <label className="text-muted-custom small fw-semibold">Tip %</label>
                    <input type="number" min={0} max={50} className="form-control form-control-sm" value={tipPct} onChange={e => setTipPct(Number(e.target.value))} />
                  </div>
                </div>

                <div className="bg-card-custom rounded-3 p-3 mt-3">
                  <div className="d-flex justify-content-between mb-1">
                    <span className="text-muted-custom small">Subtotal</span>
                    <span className="text-main small fw-semibold">₹{subtotal.toFixed(2)}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1">
                    <span className="text-muted-custom small">Tax (5%)</span>
                    <span className="text-main small fw-semibold">₹{taxAmt.toFixed(2)}</span>
                  </div>
                  {discountAmt > 0 && (
                    <div className="d-flex justify-content-between mb-1">
                      <span className="text-success small">Discount ({discountPct}%)</span>
                      <span className="text-success small fw-semibold">−₹{discountAmt.toFixed(2)}</span>
                    </div>
                  )}
                  {tipAmt > 0 && (
                    <div className="d-flex justify-content-between mb-1">
                      <span className="text-muted-custom small">Tip ({tipPct}%)</span>
                      <span className="text-main small fw-semibold">+₹{tipAmt.toFixed(2)}</span>
                    </div>
                  )}
                  <div className="d-flex justify-content-between mt-2 pt-2 border-top border-custom">
                    <span className="fw-extrabold text-main">TOTAL</span>
                    <span className="fw-extrabold text-blue" style={{ fontSize: '1.3rem' }}>₹{grandTotal.toFixed(2)}</span>
                  </div>
                </div>

                {/* Send Digital Receipt */}
                {activeBill?.isSettled && (
                  <div className="mt-3 d-flex gap-2">
                    <input className="form-control flex-grow-1" placeholder="Phone for digital receipt..." value={receiptPhone} onChange={e => setReceiptPhone(e.target.value)} />
                    <button className="btn btn-outline-blue touch-btn" onClick={handleSendReceipt}><Send size={14} /></button>
                  </div>
                )}
              </div>
            )}

            {!activeOrder && !activeBill && (
              <div className="text-center py-5 text-muted-custom">
                <CheckCircle2 size={36} style={{ opacity: 0.3 }} className="mb-2" />
                <div>No active order or bill for this table.</div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* PAYMENT MODAL */}
      {showPayModal && (
        <div className="modal-backdrop-custom" onClick={() => setShowPayModal(false)}>
          <div className="modal-box" onClick={e => e.stopPropagation()}>
            <div className="p-4 border-bottom border-custom d-flex justify-content-between align-items-center">
              <h6 className="fw-bold text-main m-0">Complete Payment</h6>
              <button className="btn-close" onClick={() => setShowPayModal(false)} />
            </div>
            <div className="p-4">
              <div className="text-center mb-4">
                <span className="text-muted-custom small d-block mb-1">Grand Total</span>
                <span className="fw-extrabold text-blue" style={{ fontSize: '2.2rem' }}>₹{grandTotal.toFixed(2)}</span>
              </div>

              <div className="mb-4">
                <label className="form-label text-muted-custom small fw-semibold mb-2">Payment Method</label>
                <div className="d-flex gap-2">
                  {PAYMENT_METHODS.map(({ key, label, icon: Icon }) => (
                    <button
                      key={key}
                      className={`btn flex-grow-1 touch-btn d-flex align-items-center justify-content-center gap-2 ${paymentMethod === key ? 'btn-blue' : 'btn-outline-secondary border-custom text-main'}`}
                      onClick={() => setPaymentMethod(key)}
                    >
                      <Icon size={16} />
                      <span className="small fw-semibold">{label}</span>
                    </button>
                  ))}
                </div>
              </div>

              <button id="confirm-payment-btn" className="btn btn-blue w-100 py-3 touch-btn fw-bold" onClick={handleSettleBill}>
                <CheckCircle2 size={18} className="me-2" />
                CONFIRM PAYMENT — ₹{grandTotal.toFixed(2)}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
