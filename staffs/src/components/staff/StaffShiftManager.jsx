import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { useAuth } from '../../context/AuthContext';
import { 
  Users, 
  UserPlus, 
  Clock, 
  Calendar, 
  ShieldCheck, 
  Award, 
  FileSpreadsheet, 
  CheckCircle2, 
  XCircle, 
  Key, 
  Trash2, 
  Edit3, 
  Phone, 
  Mail, 
  AlertTriangle, 
  Lock,
  Plus
} from 'lucide-react';

export default function StaffShiftManager({ showToast, isManagerView = false }) {
  const { session, role } = useAuth();
  const isManager = isManagerView || role === 'MANAGER' || session?.role === 'MANAGER';

  // Data States
  const [staffList, setStaffList] = useState([]);
  const [adminList, setAdminList] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selectedStaffPerf, setSelectedStaffPerf] = useState(null);

  // Tabs: 'ROSTER', 'ADMINS', 'ATTENDANCE', 'SHIFTS', 'AUDIT_LOGS'
  const [activeTab, setActiveTab] = useState('ROSTER');

  // Modals
  const [showStaffModal, setShowStaffModal] = useState(false);
  const [editingStaffId, setEditingStaffId] = useState(null);
  const [staffForm, setStaffForm] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'CAPTAIN',
    pin: '1234',
    salary: '25000'
  });

  const [showAdminModal, setShowAdminModal] = useState(false);
  const [adminForm, setAdminForm] = useState({
    name: '',
    username: '',
    email: '',
    phone: '',
    password: '',
    accessLevel: 'SUPER_ADMIN'
  });

  const [showClockModal, setShowClockModal] = useState(false);
  const [clockMode, setClockMode] = useState('IN'); // 'IN' or 'OUT'
  const [clockForm, setClockForm] = useState({ name: '', pin: '' });

  const [showShiftModal, setShowShiftModal] = useState(false);
  const [shiftForm, setShiftForm] = useState({
    shiftName: 'Morning Shift',
    startTime: '09:00',
    endTime: '17:00'
  });

  const [showAuditModal, setShowAuditModal] = useState(false);
  const [auditForm, setAuditForm] = useState({
    action: 'VOID_ITEM',
    reason: 'Guest changed order',
    amount: '150',
    managerPin: '1234'
  });

  useEffect(() => {
    fetchStaff();
    if (!isManager) {
      fetchAdmins();
    }
  }, [isManager]);

  const fetchStaff = async () => {
    setLoading(true);
    try {
      const res = await apiRequest('/api/staff');
      const list = Array.isArray(res) ? res : [];
      setStaffList(list);
    } catch (err) {
      console.error('Error fetching staff list:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchAdmins = async () => {
    try {
      const res = await apiRequest('/api/v1/admin');
      if (Array.isArray(res)) setAdminList(res);
    } catch (err) {
      console.error('Error fetching admin list:', err);
    }
  };

  // Role Badge Renderer with High Contrast & Clear Color Distinction
  const getRoleBadge = (role) => {
    const r = (role || 'STAFF').toUpperCase();
    switch (r) {
      case 'SUPER_ADMIN':
      case 'ADMIN':
        return (
          <span className="badge bg-danger text-white border border-danger-subtle px-3 py-2 fw-bold shadow-sm" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>
            🛡️ {r === 'SUPER_ADMIN' ? 'SUPER ADMIN' : 'SYSTEM ADMIN'}
          </span>
        );
      case 'MANAGER':
        return (
          <span className="badge bg-blue text-white border border-blue-subtle px-3 py-2 fw-bold shadow-sm" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>
            👑 MANAGER
          </span>
        );
      case 'CASHIER':
        return (
          <span className="badge bg-success text-white border border-success-subtle px-3 py-2 fw-bold shadow-sm" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>
            💵 CASHIER
          </span>
        );
      case 'CAPTAIN':
      case 'WAITER':
        return (
          <span className="badge bg-info text-dark border border-info-subtle px-3 py-2 fw-bold shadow-sm" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>
            🍽️ CAPTAIN / WAITER
          </span>
        );
      case 'KITCHEN':
      case 'CHEF':
        return (
          <span className="badge bg-warning text-dark border border-warning-subtle px-3 py-2 fw-bold shadow-sm" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>
            👨‍🍳 KITCHEN CHEF
          </span>
        );
      default:
        return (
          <span className="badge bg-dark text-white border border-secondary px-3 py-2 fw-bold shadow-sm" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>
            👤 {r}
          </span>
        );
    }
  };

  // 1. Create or Update Staff
  const handleSaveStaff = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        name: staffForm.name.trim(),
        email: staffForm.email.trim(),
        phoneNumber: staffForm.phone.trim(),
        phone: staffForm.phone.trim(),
        role: staffForm.role,
        pin: staffForm.pin.trim(),
        salary: parseFloat(staffForm.salary) || 0
      };

      if (editingStaffId) {
        await apiRequest(`/api/staff/${editingStaffId}`, 'PUT', payload);
        if (showToast) showToast(`Staff member '${staffForm.name}' updated!`, 'success');
      } else {
        await apiRequest('/api/staff', 'POST', payload);
        if (showToast) showToast(`Staff member '${staffForm.name}' created!`, 'success');
      }

      setShowStaffModal(false);
      resetStaffForm();
      fetchStaff();
    } catch (err) {
      if (showToast) showToast(err.message || 'Saving staff failed', 'error');
    }
  };

  const resetStaffForm = () => {
    setEditingStaffId(null);
    setStaffForm({
      name: '',
      email: '',
      phone: '',
      role: 'CAPTAIN',
      pin: '1234',
      salary: '25000'
    });
  };

  // Create System Admin
  const handleSaveAdmin = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/admin', 'POST', {
        name: adminForm.name.trim(),
        username: adminForm.username.trim(),
        email: adminForm.email.trim(),
        phoneNumber: adminForm.phone.trim(),
        phone: adminForm.phone.trim(),
        password: adminForm.password,
        adminAccessLevel: adminForm.accessLevel
      });
      if (showToast) showToast(`System Admin '${adminForm.name}' created!`, 'success');
      setShowAdminModal(false);
      setAdminForm({ name: '', username: '', email: '', phone: '', password: '', accessLevel: 'SUPER_ADMIN' });
      fetchAdmins();
    } catch (err) {
      if (showToast) showToast(err.message || 'Saving admin failed', 'error');
    }
  };

  // Toggle Admin Active
  const handleToggleAdminActive = async (adminId) => {
    try {
      await apiRequest(`/api/v1/admin/${adminId}/toggle-active`, 'PATCH');
      if (showToast) showToast('Admin active status toggled!', 'info');
      fetchAdmins();
    } catch (err) {
      if (showToast) showToast(err.message || 'Status toggle failed', 'error');
    }
  };

  // Delete Admin
  const handleDeleteAdmin = async (adminId) => {
    if (!window.confirm('Delete this System Admin account permanently?')) return;
    try {
      await apiRequest(`/api/v1/admin/${adminId}`, 'DELETE');
      if (showToast) showToast('System Admin deleted', 'warning');
      fetchAdmins();
    } catch (err) {
      if (showToast) showToast(err.message || 'Deletion failed', 'error');
    }
  };

  // 2. Toggle Active Status
  const handleToggleActive = async (staffId) => {
    try {
      await apiRequest(`/api/staff/${staffId}/toggle-active`, 'PATCH');
      if (showToast) showToast('Staff active status toggled!', 'info');
      fetchStaff();
    } catch (err) {
      if (showToast) showToast(err.message || 'Status toggle failed', 'error');
    }
  };

  // 3. Delete Staff
  const handleDeleteStaff = async (staffId) => {
    if (!window.confirm('Delete this staff record permanently?')) return;
    try {
      await apiRequest(`/api/staff/${staffId}`, 'DELETE');
      if (showToast) showToast('Staff member deleted', 'warning');
      fetchStaff();
    } catch (err) {
      if (showToast) showToast(err.message || 'Deletion failed', 'error');
    }
  };

  // 4. Clock In / Out
  const handleClockAction = async (e) => {
    e.preventDefault();
    try {
      const endpoint = clockMode === 'IN' ? '/api/staff/clock-in' : '/api/staff/clock-out';
      await apiRequest(`${endpoint}?name=${encodeURIComponent(clockForm.name)}&pin=${clockForm.pin}`, 'POST');
      if (showToast) showToast(`Clock-${clockMode} successful for ${clockForm.name}!`, 'success');
      setShowClockModal(false);
      setClockForm({ name: '', pin: '' });
    } catch (err) {
      if (showToast) showToast(err.message || `Clock-${clockMode} failed`, 'error');
    }
  };

  // 5. Create Shift
  const handleCreateShift = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/staff/shifts', 'POST', shiftForm);
      if (showToast) showToast(`Shift '${shiftForm.shiftName}' created!`, 'success');
      setShowShiftModal(false);
    } catch (err) {
      if (showToast) showToast(err.message || 'Shift creation failed', 'error');
    }
  };

  // 6. Log Manager Override Audit
  const handleLogAudit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest(
        `/api/staff/audit?action=${auditForm.action}&reason=${encodeURIComponent(auditForm.reason)}&amount=${auditForm.amount}&managerPin=${auditForm.managerPin}`,
        'POST'
      );
      if (showToast) showToast('Manager override action logged to audit trail!', 'success');
      setShowAuditModal(false);
    } catch (err) {
      if (showToast) showToast(err.message || 'Audit logging failed', 'error');
    }
  };

  // 7. Export Payroll CSV
  const handleExportPayroll = async () => {
    try {
      if (showToast) showToast('Exporting Payroll CSV report...', 'info');
      const csvData = await apiRequest('/api/staff/payroll/export');
      const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `payroll_export_${new Date().toISOString().substring(0, 10)}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      if (showToast) showToast('Payroll CSV downloaded successfully!', 'success');
    } catch (err) {
      if (showToast) showToast(err.message || 'Payroll export failed', 'error');
    }
  };

  // 8. Fetch Staff Performance
  const handleViewPerformance = async (staffId) => {
    try {
      const res = await apiRequest(`/api/staff/${staffId}/performance`);
      setSelectedStaffPerf(res);
    } catch (err) {
      if (showToast) showToast('Error fetching staff performance', 'error');
    }
  };

  return (
    <div className="staff-shift-manager">
      {/* Header Bar */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <Users size={22} className="text-secondary-custom" />
              Staff Roster, Shift Scheduling & Attendance Control
            </h5>
            <span className="text-muted-custom small">
              Manage employee accounts, PIN logins, shift assignments, clock-in/out attendance & manager override audit trails
            </span>
          </div>

          <div className="d-flex flex-wrap gap-2">
            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={handleExportPayroll}>
              <FileSpreadsheet size={14} className="me-1 text-success" /> Export Payroll CSV
            </button>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => { setClockMode('IN'); setShowClockModal(true); }}>
              <Clock size={14} className="me-1 text-primary" /> Clock In / Out
            </button>

            <button className="btn btn-outline-secondary touch-btn btn-sm" onClick={() => setShowShiftModal(true)}>
              <Calendar size={14} className="me-1" /> Create Shift
            </button>

            {!isManager && (
              <button className="btn btn-outline-primary touch-btn btn-sm fw-bold" onClick={() => setShowAdminModal(true)}>
                <ShieldCheck size={14} className="me-1" /> Add System Admin
              </button>
            )}

            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => { resetStaffForm(); setShowStaffModal(true); }}>
              <UserPlus size={14} className="me-1" /> Add New Staff
            </button>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="d-flex gap-2 mb-4 overflow-auto">
        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'ROSTER' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('ROSTER')}
        >
          Employee Roster ({staffList.length})
        </button>

        {!isManager && (
          <button
            className={`btn btn-sm rounded-pill px-3 ${activeTab === 'ADMINS' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
            onClick={() => setActiveTab('ADMINS')}
          >
            System Administrators ({adminList.length})
          </button>
        )}

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'ATTENDANCE' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('ATTENDANCE')}
        >
          Clock Attendance Terminal
        </button>

        <button
          className={`btn btn-sm rounded-pill px-3 ${activeTab === 'AUDIT_LOGS' ? 'btn-secondary fw-bold text-white' : 'btn-outline-secondary border-custom text-main'}`}
          onClick={() => setActiveTab('AUDIT_LOGS')}
        >
          Manager PIN Override Audits
        </button>
      </div>

      {/* TAB 1: EMPLOYEE ROSTER */}
      {activeTab === 'ROSTER' && (
        <div className="card bg-surface border-custom shadow-sm p-3">
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Employee Name</th>
                  <th>System Role</th>
                  <th>Contact Info</th>
                  <th>PIN Code</th>
                  <th>Monthly Salary</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {staffList.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="text-center py-4 text-muted-custom">
                      No staff members registered. Click "+ Add New Staff" to create an employee account.
                    </td>
                  </tr>
                ) : (
                  staffList.map((s) => {
                    const sId = s.staffId || s.id;
                    const isActive = s.active !== false;

                    return (
                      <tr key={sId}>
                        <td className="fw-bold text-main">
                          <Users size={15} className="me-2 text-danger" />
                          {s.name}
                        </td>
                        <td>
                          {getRoleBadge(s.role)}
                        </td>
                        <td className="text-muted-custom small">
                          <div><Phone size={12} className="me-1 text-primary" /><strong className="text-main">{s.phoneNumber || s.phone || 'N/A'}</strong></div>
                          <div><Mail size={12} className="me-1 text-primary" />{s.email || 'N/A'}</div>
                        </td>
                        <td><code className="fw-bold">****</code></td>
                        <td className="fw-bold text-main">₹{Number(s.salary || 25000).toLocaleString()}</td>
                        <td>
                          <button
                            className={`btn btn-xs fw-bold ${isActive ? 'btn-success' : 'btn-secondary'}`}
                            onClick={() => handleToggleActive(sId)}
                          >
                            {isActive ? 'ACTIVE' : 'INACTIVE'}
                          </button>
                        </td>
                        <td>
                          <div className="d-flex gap-1">
                            <button
                              className="btn btn-xs btn-outline-secondary"
                              onClick={() => {
                                setEditingStaffId(sId);
                                setStaffForm({
                                  name: s.name || '',
                                  email: s.email || '',
                                  phone: s.phoneNumber || s.phone || '',
                                  role: s.role || 'CAPTAIN',
                                  pin: s.pin || '1234',
                                  salary: String(s.salary || '25000')
                                });
                                setShowStaffModal(true);
                              }}
                            >
                              <Edit3 size={12} />
                            </button>

                            <button className="btn btn-xs btn-outline-danger" onClick={() => handleDeleteStaff(sId)}>
                              <Trash2 size={12} />
                            </button>

                            <button className="btn btn-xs btn-outline-primary" onClick={() => handleViewPerformance(sId)}>
                              <Award size={12} /> Performance
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Performance Modal Snapshot */}
          {selectedStaffPerf && (
            <div className="p-3 bg-card-custom rounded-3 border border-custom mt-3 d-flex justify-content-between align-items-center">
              <div>
                <span className="fw-bold text-main d-block">Staff Performance Score for {selectedStaffPerf.staffName}:</span>
                <span className="text-muted-custom small">Orders Served: {selectedStaffPerf.totalOrders || 0} • Total Sales: ₹{Number(selectedStaffPerf.totalSalesGenerated || 0).toLocaleString()}</span>
              </div>
              <button className="btn btn-sm btn-outline-secondary" onClick={() => setSelectedStaffPerf(null)}>Close</button>
            </div>
          )}
        </div>
      )}

      {/* TAB: SYSTEM ADMINISTRATORS */}
      {activeTab === 'ADMINS' && (
        <div className="card bg-surface border-custom shadow-sm p-3">
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th>Admin Name & Username</th>
                  <th>System Access Level</th>
                  <th>Contact Info</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {adminList.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="text-center py-4 text-muted-custom">
                      No system admin accounts found. Click "+ Add System Admin" to create one.
                    </td>
                  </tr>
                ) : (
                  adminList.map((a) => {
                    const aId = a.adminId || a.id;
                    const isActive = a.active !== false;

                    return (
                      <tr key={aId}>
                        <td className="fw-bold text-main">
                          <ShieldCheck size={16} className="me-2 text-primary" />
                          {a.name}
                          <span className="text-muted-custom small font-monospace d-block ms-4">@{a.username || 'admin'}</span>
                        </td>
                        <td>
                          {getRoleBadge(a.adminAccessLevel || 'SUPER_ADMIN')}
                        </td>
                        <td className="text-muted-custom small">
                          <div><Phone size={12} className="me-1 text-primary" /><strong className="text-main">{a.phoneNumber || a.phone || 'N/A'}</strong></div>
                          <div><Mail size={12} className="me-1 text-primary" />{a.email || 'N/A'}</div>
                        </td>
                        <td>
                          <button
                            className={`btn btn-xs fw-bold ${isActive ? 'btn-success' : 'btn-secondary'}`}
                            onClick={() => handleToggleAdminActive(aId)}
                          >
                            {isActive ? 'ACTIVE' : 'INACTIVE'}
                          </button>
                        </td>
                        <td>
                          <div className="d-flex gap-1">
                            <button className="btn btn-xs btn-outline-danger" onClick={() => handleDeleteAdmin(aId)}>
                              <Trash2 size={12} /> Delete
                            </button>
                          </div>
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

      {/* TAB 2: CLOCK ATTENDANCE */}
      {activeTab === 'ATTENDANCE' && (
        <div className="card bg-surface border-custom shadow-sm p-4 text-center">
          <Clock size={40} className="text-secondary-custom mb-3 mx-auto" />
          <h5 className="fw-bold text-main mb-2">Staff Attendance Kiosk Terminal</h5>
          <p className="text-muted-custom small mb-4">
            Clock In / Clock Out with staff name and 4-digit security PIN.
          </p>

          <div className="d-flex justify-content-center gap-3">
            <button className="btn btn-success touch-btn fw-bold px-4 py-2" onClick={() => { setClockMode('IN'); setShowClockModal(true); }}>
              CLOCK IN (START SHIFT)
            </button>

            <button className="btn btn-danger touch-btn fw-bold px-4 py-2" onClick={() => { setClockMode('OUT'); setShowClockModal(true); }}>
              CLOCK OUT (END SHIFT)
            </button>
          </div>
        </div>
      )}

      {/* TAB 3: AUDIT LOGS */}
      {activeTab === 'AUDIT_LOGS' && (
        <div className="card bg-surface border-custom shadow-sm p-4">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h6 className="fw-bold text-main m-0">Manager Override & High-Value Action Audits</h6>
            <button className="btn btn-secondary touch-btn btn-sm fw-bold" onClick={() => setShowAuditModal(true)}>
              + Log Manager Override Action
            </button>
          </div>

          <p className="text-muted-custom small">
            All bill voids, complimentary meals, discount overrides, and cash drawer reconciliations are logged with Manager PIN verification.
          </p>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 1: ADD / EDIT STAFF                                  */}
      {/* ========================================================= */}
      {showStaffModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">
                  {editingStaffId ? 'Edit Staff Account' : 'Add New Staff Member'}
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowStaffModal(false)}></button>
              </div>

              <form onSubmit={handleSaveStaff}>
                <div className="modal-body">
                  <div className="alert alert-info py-2 small d-flex align-items-center gap-2 mb-3">
                    <Mail size={16} />
                    <span>An automated email with terminal credentials & PIN code will be sent to the staff member's email address upon creation.</span>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Full Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Rahul Sharma"
                      value={staffForm.name}
                      onChange={(e) => setStaffForm({ ...staffForm, name: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Email Address (PIN Credentials Sent Here)</label>
                    <input
                      type="email"
                      className="form-control"
                      placeholder="staff@restaurant.com"
                      value={staffForm.email}
                      onChange={(e) => setStaffForm({ ...staffForm, email: e.target.value })}
                    />
                  </div>

                  <div className="row g-3 mb-3">
                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Role *</label>
                      <select
                        className="form-select"
                        value={staffForm.role}
                        onChange={(e) => setStaffForm({ ...staffForm, role: e.target.value })}
                      >
                        {!isManager && <option value="ADMIN">ADMIN</option>}
                        <option value="MANAGER">MANAGER</option>
                        <option value="CASHIER">CASHIER</option>
                        <option value="CAPTAIN">CAPTAIN (WAITER)</option>
                        <option value="KITCHEN">KITCHEN CHEF</option>
                      </select>
                    </div>

                    <div className="col-12 col-md-6">
                      <div className="d-flex justify-content-between align-items-center mb-1">
                        <label className="form-label text-muted-custom small fw-semibold m-0">Security PIN Code *</label>
                        <button
                          type="button"
                          className="btn btn-sm btn-link text-primary p-0 text-decoration-none micro-text fw-bold"
                          onClick={() => setStaffForm({ ...staffForm, pin: String(Math.floor(1000 + Math.random() * 9000)) })}
                        >
                          Generate PIN
                        </button>
                      </div>
                      <input
                        type="text"
                        maxLength="6"
                        className="form-control font-monospace"
                        required
                        placeholder="1234"
                        value={staffForm.pin}
                        onChange={(e) => setStaffForm({ ...staffForm, pin: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="row g-3 mb-3">
                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Mobile Phone</label>
                      <input
                        type="tel"
                        className="form-control"
                        placeholder="9876543210"
                        value={staffForm.phone}
                        onChange={(e) => setStaffForm({ ...staffForm, phone: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Monthly Salary (₹)</label>
                      <input
                        type="number"
                        className="form-control"
                        value={staffForm.salary}
                        onChange={(e) => setStaffForm({ ...staffForm, salary: e.target.value })}
                      />
                    </div>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowStaffModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Save Staff Account
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: CLOCK IN / CLOCK OUT KIOSK                        */}
      {/* ========================================================= */}
      {showClockModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">
                  Staff Clock-{clockMode} Terminal
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowClockModal(false)}></button>
              </div>

              <form onSubmit={handleClockAction}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Staff Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="Enter staff name"
                      value={clockForm.name}
                      onChange={(e) => setClockForm({ ...clockForm, name: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Security PIN *</label>
                    <input
                      type="password"
                      maxLength="6"
                      className="form-control"
                      required
                      placeholder="****"
                      value={clockForm.pin}
                      onChange={(e) => setClockForm({ ...clockForm, pin: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowClockModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className={`btn fw-bold px-4 ${clockMode === 'IN' ? 'btn-success' : 'btn-danger'}`}>
                    Confirm Clock-{clockMode}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 3: LOG MANAGER OVERRIDE AUDIT                        */}
      {/* ========================================================= */}
      {showAuditModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Log Manager Override Action</h5>
                <button type="button" className="btn-close" onClick={() => setShowAuditModal(false)}></button>
              </div>

              <form onSubmit={handleLogAudit}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Override Action Type *</label>
                    <select
                      className="form-select"
                      value={auditForm.action}
                      onChange={(e) => setAuditForm({ ...auditForm, action: e.target.value })}
                    >
                      <option value="VOID_ITEM">VOID ITEM FROM ORDER</option>
                      <option value="VOID_BILL">VOID SETTLED BILL</option>
                      <option value="COMPLIMENTARY_DISCOUNT">100% COMPLIMENTARY MEAL</option>
                      <option value="PRICE_OVERRIDE">PRICE OVERRIDE</option>
                    </select>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Override Amount (₹)</label>
                    <input
                      type="number"
                      className="form-control"
                      value={auditForm.amount}
                      onChange={(e) => setAuditForm({ ...auditForm, amount: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Reason for Override *</label>
                    <textarea
                      className="form-control"
                      rows="2"
                      required
                      placeholder="e.g. Customer requested food replacement"
                      value={auditForm.reason}
                      onChange={(e) => setAuditForm({ ...auditForm, reason: e.target.value })}
                    ></textarea>
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Manager Verification PIN *</label>
                    <input
                      type="password"
                      className="form-control"
                      required
                      placeholder="Enter manager PIN"
                      value={auditForm.managerPin}
                      onChange={(e) => setAuditForm({ ...auditForm, managerPin: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowAuditModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Record Audit Log
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 4: ADD SYSTEM ADMIN                                  */}
      {/* ========================================================= */}
      {showAdminModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Add System Administrator</h5>
                <button type="button" className="btn-close" onClick={() => setShowAdminModal(false)}></button>
              </div>

              <form onSubmit={handleSaveAdmin}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Admin Full Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. System Admin"
                      value={adminForm.name}
                      onChange={(e) => setAdminForm({ ...adminForm, name: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Username *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="admin_username"
                      value={adminForm.username}
                      onChange={(e) => setAdminForm({ ...adminForm, username: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Email Address</label>
                    <input
                      type="email"
                      className="form-control"
                      placeholder="admin@restaurant.com"
                      value={adminForm.email}
                      onChange={(e) => setAdminForm({ ...adminForm, email: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Mobile Phone Number</label>
                    <input
                      type="tel"
                      className="form-control"
                      placeholder="9876543210"
                      value={adminForm.phone}
                      onChange={(e) => setAdminForm({ ...adminForm, phone: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Password *</label>
                    <input
                      type="password"
                      className="form-control"
                      required
                      value={adminForm.password}
                      onChange={(e) => setAdminForm({ ...adminForm, password: e.target.value })}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowAdminModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-primary fw-bold px-4">
                    Create System Admin
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
