import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { loginWithPin, clearSession } from '../services/authService';
import {
  Utensils, Sun, Moon, Flame, Grid, DollarSign, ChefHat, Users, Delete, KeyRound,
} from 'lucide-react';

const ROLE_COLORS = {
  MANAGER:  { bg: '#dbeafe', text: '#1d4ed8', label: 'Manager' },
  CASHIER:  { bg: '#dcfce7', text: '#15803d', label: 'Cashier' },
  CAPTAIN:  { bg: '#fef9c3', text: '#a16207', label: 'Captain' },
  KITCHEN:  { bg: '#fee2e2', text: '#b91c1c', label: 'Kitchen' },
};

export default function StaffLogin() {
  const navigate = useNavigate();
  const { updateSession, showToast, theme, toggleTheme } = useAuth();

  const [pin, setPin]       = useState('');
  const [loading, setLoading] = useState(false);

  // PIN Keypad actions
  const handlePinDigit = (digit) => {
    if (pin.length < 6) setPin(prev => prev + digit);
  };

  const handlePinDelete = () => setPin(prev => prev.slice(0, -1));
  const handlePinClear  = () => setPin('');

  const executePinLogin = async (targetPin) => {
    const cleanPin = String(targetPin || '').trim();
    if (!cleanPin || cleanPin.length < 4) {
      return showToast('Please enter a 4-digit PIN code', 'warning');
    }
    setLoading(true);
    clearSession();

    let res;
    try {
      res = await loginWithPin(cleanPin);
    } catch (err) {
      setLoading(false);
      setPin('');
      const errorMsg = err.message || 'Invalid Staff PIN Code';
      showToast(errorMsg, 'error');
      return;
    }

    try {
      const roleRaw = typeof res.role === 'string' ? res.role : res.role?.name || 'CASHIER';
      showToast(`Welcome back, ${res.name || 'Staff'}! (${roleRaw})`, 'success');
      updateSession({
        token:       res.token,
        role:        roleRaw,
        primaryRole: roleRaw,
        username:    res.name || 'Staff Member',
        staffId:     res.staffId,
      });
      navigate('/dashboard', { replace: true });
    } catch (err) {
      console.error('Post-login navigation error:', err);
    } finally {
      setLoading(false);
      setPin('');
    }
  };

  const PIN_KEYS = ['1','2','3','4','5','6','7','8','9','C','0','⌫'];

  return (
    <div className="login-page-bg">
      <div className="login-glass-card" style={{ maxWidth: 860 }}>
        <div className="row g-0 align-items-stretch" style={{ minHeight: 500 }}>

          {/* LEFT HALF: PIN KEYPAD TERMINAL */}
          <div className="col-12 col-lg-6 p-4 d-flex flex-column justify-content-between">
            {/* Header */}
            <div>
              <div className="d-flex justify-content-between align-items-center mb-3">
                <div className="d-flex align-items-center gap-2">
                  <img 
                    src="/logo.png" 
                    alt="Spice Haven Logo" 
                    className="rounded-circle shadow-sm" 
                    style={{ width: '40px', height: '40px', objectFit: 'cover' }} 
                  />
                  <div>
                    <span className="fw-extrabold text-main d-block lh-1" style={{ fontSize: '1.05rem' }}>SPICE HAVEN POS</span>
                    <span className="text-muted-custom" style={{ fontSize: '0.62rem', letterSpacing: '0.08em', fontWeight: 600 }}>GOOD FOOD BRIGHTER DAYS</span>
                  </div>
                </div>
                <button className="btn btn-outline-secondary border-custom text-main p-2 rounded-circle touch-btn shadow-sm" onClick={toggleTheme}>
                  {theme === 'dark'   ? <Sun size={15} className="text-warning" /> :
                   theme === 'orange' ? <Flame size={15} className="text-danger" /> :
                                       <Moon size={15} />}
                </button>
              </div>

              <div className="text-center my-3">
                <h5 className="fw-extrabold text-main mb-1 d-flex align-items-center justify-content-center gap-2">
                  <KeyRound size={22} className="text-blue" />
                  Staff PIN Terminal
                </h5>
                <p className="text-muted-custom small mb-0">Enter your 4-Digit Staff PIN Code</p>
              </div>
            </div>

            {/* PIN Display Dots */}
            <div className="d-flex justify-content-center gap-3 my-3">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className={`pin-digit ${i < pin.length ? 'filled' : ''}`}>
                  {i < pin.length ? '●' : ''}
                </div>
              ))}
            </div>

            {/* PIN Keypad Grid */}
            <div className="d-grid mb-4" style={{ gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px' }}>
              {PIN_KEYS.map((key, idx) => {
                if (key === 'C') return (
                  <button key={idx} className="pin-btn mx-auto text-warning fw-bold" style={{ width: 62, height: 62, fontSize: '1.05rem' }} onClick={handlePinClear}>
                    CLEAR
                  </button>
                );
                if (key === '⌫') return (
                  <button key={idx} className="pin-btn delete-btn mx-auto" style={{ width: 62, height: 62 }} onClick={handlePinDelete} title="Backspace">
                    <Delete size={20} />
                  </button>
                );
                return (
                  <button key={idx} className="pin-btn mx-auto" style={{ width: 62, height: 62 }} onClick={() => handlePinDigit(key)}>
                    {key}
                  </button>
                );
              })}
            </div>

            {/* Submit Button */}
            <button
              id="pin-login-btn"
              className="btn btn-blue w-100 py-3 touch-btn fw-bold"
              onClick={() => executePinLogin(pin)}
              disabled={loading || pin.length < 4}
            >
              {loading ? 'VERIFYING PIN...' : 'ENTER PORTAL'}
            </button>
          </div>

          {/* RIGHT HALF: DECORATIVE BANNER */}
          <div className="col-12 col-lg-6 d-none d-lg-block">
            <div className="login-arch-graphics p-5">
              <svg className="position-absolute w-100 h-100 opacity-25" style={{ inset: 0 }}>
                <line x1="20%" y1="30%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
                <line x1="80%" y1="20%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
                <line x1="30%" y1="70%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
                <line x1="75%" y1="75%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
              </svg>

              <div className="position-relative text-center text-white z-1 py-4" style={{ maxWidth: 360 }}>
                <div className="position-relative mx-auto mb-4" style={{ width: 170, height: 170 }}>
                  <div className="position-absolute rounded-circle border border-white opacity-25 w-100 h-100 animate-ping" style={{ inset: 0 }} />
                  <div className="position-absolute top-50 start-50 translate-middle bg-white p-1 rounded-circle shadow-lg floating-node overflow-hidden" style={{ width: 88, height: 88, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <img src="/logo.png" alt="Spice Haven Logo" className="w-100 h-100 rounded-circle" style={{ objectFit: 'cover' }} />
                  </div>
                  <div className="position-absolute top-0 start-50 translate-middle-x bg-warning text-dark p-2 rounded-circle shadow-lg floating-node-2">
                    <Grid size={18} />
                  </div>
                  <div className="position-absolute top-50 end-0 translate-middle-y bg-info text-dark p-2 rounded-circle shadow-lg floating-node-3">
                    <DollarSign size={18} />
                  </div>
                  <div className="position-absolute bottom-0 start-50 translate-middle-x bg-danger text-white p-2 rounded-circle shadow-lg floating-node-2">
                    <Flame size={18} />
                  </div>
                  <div className="position-absolute top-50 start-0 translate-middle-y bg-success text-white p-2 rounded-circle shadow-lg floating-node-3">
                    <Users size={18} />
                  </div>
                </div>

                <h5 className="fw-extrabold mb-2 text-white">Staff Roles Workspace</h5>
                <div className="d-flex flex-wrap justify-content-center gap-2 mb-3">
                  {Object.entries(ROLE_COLORS).map(([role, { bg, text, label }]) => (
                    <span key={role} className="badge fw-semibold" style={{ background: `${bg}cc`, color: text, fontSize: '0.72rem', padding: '4px 8px' }}>
                      {label}
                    </span>
                  ))}
                </div>
                <p className="opacity-90 small mb-0">
                  Enter your 4-digit PIN for instant POS workspace access across Manager, Cashier, Captain, and Kitchen terminals.
                </p>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
