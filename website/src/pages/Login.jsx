import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { loginWithEmail } from '../services/authService';
import { 
  Utensils, 
  Lock, 
  Mail, 
  Sun, 
  Moon, 
  Eye, 
  EyeOff, 
  Grid, 
  DollarSign, 
  ChefHat, 
  BarChart3 
} from 'lucide-react';

export default function Login() {
  const navigate = useNavigate();
  const { updateSession, showToast, theme, toggleTheme } = useAuth();
  
  const [email, setEmail] = useState('admin@restaurant.com');
  const [password, setPassword] = useState('password');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [loading, setLoading] = useState(false);

  const redirectByRole = (role) => {
    navigate('/admin');
  };

  const handleEmailSubmit = async (e) => {
    if (e) e.preventDefault();
    if (!email || !password) return showToast('Please fill in email and password', 'warning');

    setLoading(true);
    try {
      const res = await loginWithEmail(email, password);
      showToast(`Welcome back, ${res.name || res.username || 'User'}!`, 'success');
      const role = 'ADMIN';
      updateSession({
        token: res.token,
        role: role,
        primaryRole: role,
        username: res.name || res.username || 'System Admin',
      });
      redirectByRole(role);
    } catch (err) {
      showToast(err.message || 'Invalid login credentials', 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page-bg">
      {/* Container matching reference mockup */}
      <div className="login-glass-card">
        <div className="row g-0 align-items-stretch" style={{ minHeight: '400px' }}>
          
          {/* LEFT HALF: SIGN IN FORM */}
          <div className="col-12 col-lg-6 p-3 p-md-4 d-flex flex-column justify-content-between">
            {/* Top Bar Header & Controls */}
            <div className="d-flex justify-content-between align-items-center mb-2">
              <div className="d-flex align-items-center gap-2">
                <img 
                  src="/logo.png" 
                  alt="Spice Haven Logo" 
                  className="rounded-circle shadow-sm" 
                  style={{ width: '42px', height: '42px', objectFit: 'cover' }} 
                />
                <div>
                  <span className="fw-extrabold fs-5 text-main tracking-wide d-block lh-1">SPICE HAVEN</span>
                  <span className="text-muted-custom" style={{ fontSize: '0.62rem', letterSpacing: '0.08em', fontWeight: 600 }}>GOOD FOOD BRIGHTER DAYS</span>
                </div>
              </div>

              <div className="d-flex align-items-center gap-2">
                <button
                  className="btn btn-outline-secondary border-custom text-main p-2 rounded-circle touch-btn shadow-sm"
                  onClick={toggleTheme}
                  title={`Switch to ${theme === 'dark' ? 'Light' : 'Dark'} Mode`}
                >
                  {theme === 'dark' ? <Sun size={16} className="text-warning" /> : <Moon size={16} className="text-indigo" />}
                </button>
              </div>
            </div>

            {/* Form Title */}
            <div className="mb-3">
              <h3 className="fw-bold text-main mb-2">Sign In to Admin Portal</h3>
              <p className="text-muted-custom small mb-3">Management & Operations Portal</p>
            </div>

            {/* Form Content */}
            <form onSubmit={handleEmailSubmit}>
              <div className="mb-3">
                <label className="form-label text-muted-custom small fw-semibold">Email</label>
                <input
                  type="email"
                  className="form-control"
                  placeholder="Enter Email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
              </div>

              <div className="mb-3">
                <div className="d-flex justify-content-between align-items-center mb-1">
                  <label className="form-label text-muted-custom small fw-semibold m-0">Password</label>
                  <a href="#forgot" className="text-decoration-none small fw-semibold" style={{ color: '#4f46e5' }}>
                    Forgot password?
                  </a>
                </div>
                <div className="position-relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    className="form-control pe-5"
                    placeholder="Enter Password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                  <button
                    type="button"
                    className="btn btn-link text-muted-custom position-absolute end-0 top-50 translate-middle-y me-2 border-0 p-0"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              <div className="form-check mb-4">
                <input
                  type="checkbox"
                  className="form-check-input"
                  id="rememberCheck"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                />
                <label className="form-check-label text-muted-custom small" htmlFor="rememberCheck">
                  Remember me
                </label>
              </div>

              <button
                type="submit"
                className="btn btn-indigo w-100 py-3 touch-btn mb-3"
                disabled={loading}
              >
                {loading ? 'SIGNING IN...' : 'SIGN IN'}
              </button>
            </form>


          </div>

          {/* RIGHT HALF: DECORATIVE SEMI-CIRCLE ARCH BANNER WITH FLOATING TECH NODES */}
          <div className="col-12 col-lg-6 d-none d-lg-block">
            <div className="login-arch-graphics p-5">
              {/* Background Glowing Lines SVG */}
              <svg className="position-absolute w-100 h-100 opacity-25" style={{ inset: 0 }}>
                <line x1="20%" y1="30%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
                <line x1="80%" y1="20%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
                <line x1="30%" y1="70%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
                <line x1="75%" y1="75%" x2="50%" y2="50%" stroke="#ffffff" strokeWidth="2" strokeDasharray="4" />
              </svg>

              <div className="position-relative text-center text-white z-1 py-4" style={{ maxWidth: '380px' }}>
                {/* Central Floating Node Graphic */}
                <div className="position-relative mx-auto mb-4" style={{ width: '180px', height: '180px' }}>
                  {/* Outer Pulsing Ring */}
                  <div className="position-absolute rounded-circle border border-white opacity-25 w-100 h-100 animate-ping" style={{ inset: 0 }}></div>
                  
                  {/* Central Character Avatar Badge */}
                  <div className="position-absolute top-50 start-50 translate-middle bg-white p-1 rounded-circle shadow-lg d-flex align-items-center justify-content-center floating-node overflow-hidden" style={{ width: '96px', height: '96px' }}>
                    <img src="/logo.png" alt="Spice Haven" className="w-100 h-100 rounded-circle" style={{ objectFit: 'cover' }} />
                  </div>

                  {/* Satellite Module Badges */}
                  <div className="position-absolute top-0 start-50 translate-middle-x bg-warning text-dark p-2 rounded-circle shadow-lg floating-node-2">
                    <Grid size={22} />
                  </div>
                  <div className="position-absolute top-50 end-0 translate-middle-y bg-info text-dark p-2 rounded-circle shadow-lg floating-node-3">
                    <DollarSign size={22} />
                  </div>
                  <div className="position-absolute bottom-0 start-50 translate-middle-x bg-danger text-white p-2 rounded-circle shadow-lg floating-node-2">
                    <ChefHat size={22} />
                  </div>
                  <div className="position-absolute top-50 start-0 translate-middle-y bg-success text-white p-2 rounded-circle shadow-lg floating-node-3">
                    <BarChart3 size={22} />
                  </div>
                </div>

                <h3 className="fw-extrabold mb-2 text-white">Unified POS Ecosystem</h3>
                <p className="opacity-90 small mb-0 leading-relaxed">
                  Real-time STOMP WebSockets connecting Floor Maps, Billing Terminals, Kitchen Displays & Manager Analytics.
                </p>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

