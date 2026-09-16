import { apiRequest } from './apiClient';

// ── 4-Digit PIN-based staff login (uses /api/staff/login-pin) ──
export async function loginWithPin(pin, name) {
  const targetPin = typeof pin === 'object' ? pin.pin : pin;
  const targetName = typeof pin === 'object' ? pin.name : name;
  const body = targetName ? { name: targetName, pin: targetPin } : { pin: targetPin };

  const data = await apiRequest('/api/staff/login-pin', 'POST', body);
  if (data && data.token) {
    const role = typeof data.role === 'string' ? data.role : data.role?.name || 'CASHIER';
    saveSession(data.token, role, data.name, data.staffId);
  }
  return data;
}

// ── Clock-in / Clock-out ──
export async function clockIn(name, pin) {
  return apiRequest(`/api/staff/clock-in?name=${encodeURIComponent(name)}&pin=${encodeURIComponent(pin)}`, 'POST');
}

export async function clockOut(name, pin) {
  return apiRequest(`/api/staff/clock-out?name=${encodeURIComponent(name)}&pin=${encodeURIComponent(pin)}`, 'POST');
}

// ── Session helpers ──
export function saveSession(token, role, username, staffId) {
  localStorage.setItem('staff_jwt_token', token);
  localStorage.setItem('pos_jwt_token', token);
  localStorage.setItem('staff_user_role', role);
  localStorage.setItem('pos_user_role', role);
  localStorage.setItem('staff_username', username || '');
  localStorage.setItem('pos_username', username || '');
  if (staffId) localStorage.setItem('staff_id', staffId);
}

export function clearSession() {
  localStorage.removeItem('staff_jwt_token');
  localStorage.removeItem('pos_jwt_token');
  localStorage.removeItem('staff_user_role');
  localStorage.removeItem('pos_user_role');
  localStorage.removeItem('staff_username');
  localStorage.removeItem('pos_username');
  localStorage.removeItem('staff_id');
  localStorage.removeItem('staff_active_role');
  localStorage.removeItem('pos_active_role');
}

export function getStoredSession() {
  const token       = localStorage.getItem('staff_jwt_token') || localStorage.getItem('pos_jwt_token');
  const role        = localStorage.getItem('staff_user_role') || localStorage.getItem('pos_user_role');
  const primaryRole = role;
  const username    = localStorage.getItem('staff_username') || localStorage.getItem('pos_username');
  const staffId     = localStorage.getItem('staff_id');
  return { token, role, primaryRole, username, staffId };
}

