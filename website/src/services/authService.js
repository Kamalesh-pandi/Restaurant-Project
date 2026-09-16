import { apiRequest } from './apiClient';

export async function loginWithEmail(email, password) {
  const data = await apiRequest('/api/auth/login', 'POST', { username: email, email, password });
  if (data && data.token) {
    saveSession(data.token, data.role, data.username);
  }
  return data;
}

export async function loginWithPin(pin) {
  const data = await apiRequest('/api/staff/login-pin', 'POST', { pin });
  if (data && data.token) {
    saveSession(data.token, data.role || data.staffRole, data.staffName || 'Staff');
  }
  return data;
}

export function saveSession(token, role, username) {
  localStorage.setItem('pos_jwt_token', token);
  localStorage.setItem('pos_user_role', role);
  localStorage.setItem('pos_username', username);
}

export function clearSession() {
  localStorage.removeItem('pos_jwt_token');
  localStorage.removeItem('pos_user_role');
  localStorage.removeItem('pos_username');
  localStorage.removeItem('pos_active_role');
}

export function getStoredSession() {
  const token = localStorage.getItem('pos_jwt_token');
  const role = localStorage.getItem('pos_active_role') || localStorage.getItem('pos_user_role');
  const primaryRole = localStorage.getItem('pos_user_role');
  const username = localStorage.getItem('pos_username');
  return { token, role, primaryRole, username };
}

export function setActiveRole(role) {
  localStorage.setItem('pos_active_role', role);
}
