import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  Percent, 
  Plus, 
  Tag, 
  Sparkles, 
  Calendar, 
  Gift, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  DollarSign, 
  AlertTriangle 
} from 'lucide-react';

export default function DiscountPromotionsManager({ showToast }) {
  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(false);

  const [showPromoModal, setShowPromoModal] = useState(false);
  const [promoForm, setPromoForm] = useState({
    code: 'WELCOME20',
    title: 'Flat 20% Off Launch Special',
    discountPercent: '20',
    minBillValue: '500',
    validUntil: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10)
  });

  useEffect(() => {
    fetchPromotions();
  }, []);

  const fetchPromotions = async () => {
    setLoading(true);
    try {
      const res = await apiRequest('/api/v1/chain/promotions').catch(() => []);
      const list = Array.isArray(res) ? res : [];
      setPromotions(list);
    } catch (err) {
      console.error('Error fetching promotions:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreatePromo = async (e) => {
    e.preventDefault();
    try {
      const validToDate = new Date(promoForm.validUntil);
      await apiRequest('/api/v1/chain/promotions', 'POST', {
        code: promoForm.code.toUpperCase().trim(),
        promoCode: promoForm.code.toUpperCase().trim(),
        title: promoForm.title.trim(),
        description: promoForm.title.trim(),
        discountPercent: parseFloat(promoForm.discountPercent) || 10,
        discountPercentage: parseFloat(promoForm.discountPercent) || 10,
        minBillValue: parseFloat(promoForm.minBillValue) || 0,
        validFrom: new Date().toISOString(),
        validTo: isNaN(validToDate.getTime()) ? new Date(Date.now() + 14 * 86400000).toISOString() : validToDate.toISOString(),
        validUntil: promoForm.validUntil,
        isActive: true,
      });
      if (showToast) showToast(`Promotion coupon '${promoForm.code}' created!`, 'success');
      setShowPromoModal(false);
      fetchPromotions();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create promotion', 'error');
    }
  };

  return (
    <div className="discount-promotions-manager">
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <Percent size={22} className="text-secondary-custom" />
              Discounts, Coupon Codes & Loyalty Promotions
            </h5>
            <span className="text-muted-custom small">
              Configure bill discounts, campaign coupons, minimum order spends & brand promotions
            </span>
          </div>

          <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowPromoModal(true)}>
            <Plus size={14} className="me-1" /> Create New Coupon
          </button>
        </div>
      </div>

      <div className="card bg-surface border-custom shadow-sm p-4">
        <h6 className="fw-bold text-main mb-3">Active Promotional Coupons & Offers ({promotions.length})</h6>
        <div className="table-responsive">
          <table className="table table-hover align-middle mb-0">
            <thead>
              <tr>
                <th>Coupon Code</th>
                <th>Promotion Title</th>
                <th>Discount Percentage</th>
                <th>Min. Bill Value</th>
                <th>Valid Until</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {promotions.length === 0 ? (
                <tr>
                  <td colSpan="6" className="text-center py-4 text-muted-custom">
                    No promo coupons active. Click "+ Create New Coupon" to set up a brand discount offer.
                  </td>
                </tr>
              ) : (
                promotions.map((p, idx) => (
                  <tr key={p.id || idx}>
                    <td><code className="fw-bold text-danger fs-6">{p.promoCode || p.code}</code></td>
                    <td className="fw-bold text-main">{p.description || p.title}</td>
                    <td className="fw-bold text-success">{p.discountPercentage || p.discountPercent}% OFF</td>
                    <td className="text-muted-custom">₹{p.minBillValue || 0}</td>
                    <td className="text-muted-custom small">{p.validTo ? new Date(p.validTo).toLocaleDateString() : (p.validUntil || 'Ongoing')}</td>
                    <td><span className="badge bg-success bg-opacity-20 text-success">ACTIVE</span></td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* CREATE PROMO MODAL */}
      {showPromoModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Create Coupon Promotion</h5>
                <button type="button" className="btn-close" onClick={() => setShowPromoModal(false)}></button>
              </div>

              <form onSubmit={handleCreatePromo}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Coupon Code *</label>
                    <input
                      type="text"
                      className="form-control text-uppercase"
                      required
                      placeholder="e.g. SUMMER25"
                      value={promoForm.code}
                      onChange={(e) => setPromoForm({ ...promoForm, code: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Promotion Title *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Special Summer 25% Discount"
                      value={promoForm.title}
                      onChange={(e) => setPromoForm({ ...promoForm, title: e.target.value })}
                    />
                  </div>

                  <div className="row g-3 mb-3">
                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">Discount % *</label>
                      <input
                        type="number"
                        min="1"
                        max="100"
                        className="form-control"
                        required
                        value={promoForm.discountPercent}
                        onChange={(e) => setPromoForm({ ...promoForm, discountPercent: e.target.value })}
                      />
                    </div>

                    <div className="col-6">
                      <label className="form-label text-muted-custom small fw-semibold">Min Bill Spend (₹)</label>
                      <input
                        type="number"
                        className="form-control"
                        value={promoForm.minBillValue}
                        onChange={(e) => setPromoForm({ ...promoForm, minBillValue: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Valid Until Date</label>
                    <input
                      type="date"
                      className="form-control"
                      value={promoForm.validUntil}
                      onChange={(e) => setPromoForm({ ...promoForm, validUntil: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowPromoModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Create Coupon
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
