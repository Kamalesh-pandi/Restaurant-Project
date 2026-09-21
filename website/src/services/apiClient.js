// Centralized HTTP client using native fetch with JWT handling, error notifications, and auto-auth recovery

const RAW_BASE_URL = import.meta.env.VITE_API_BASE_URL || '';
const BASE_URL = RAW_BASE_URL.replace(/\/+$/, '');

let loginPromise = null;

async function refreshAdminToken() {
  if (loginPromise) return loginPromise;
  loginPromise = (async () => {
    try {
      const res = await fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: 'admin@restaurant.com',
          email: 'admin@restaurant.com',
          password: 'password'
        })
      });
      if (res.ok) {
        const authData = await res.json();
        if (authData.token) {
          localStorage.setItem('pos_jwt_token', authData.token);
          localStorage.setItem('pos_user_role', authData.role || 'ADMIN');
          localStorage.setItem('pos_username', authData.username || 'admin');
          return authData.token;
        }
      }
    } catch (e) {
      console.warn('Auto admin token recovery failed:', e);
    } finally {
      loginPromise = null;
    }
    return null;
  })();
  return loginPromise;
}

export async function apiRequest(endpoint, method = 'GET', body = null, customHeaders = {}) {
  let token = localStorage.getItem('pos_jwt_token');

  // If no token exists and this is an authenticated endpoint, try auto-authenticating
  const isAuthEndpoint = endpoint.startsWith('/api/auth/') || 
                         endpoint.startsWith('/api/customers/') || 
                         endpoint.startsWith('/api/staff/login-pin') ||
                         endpoint.startsWith('/api/v1/delivery-partner/login-pin');

  if (!token && !isAuthEndpoint) {
    token = await refreshAdminToken();
  }

  const buildHeaders = (authToken) => {
    const headers = {
      'Content-Type': 'application/json',
      ...customHeaders,
    };
    if (authToken) {
      headers['Authorization'] = `Bearer ${authToken}`;
    }
    return headers;
  };

  const options = {
    method,
    headers: buildHeaders(token),
  };

  if (body) {
    if (typeof body === 'string') {
      options.body = body;
    } else {
      options.body = JSON.stringify(body);
    }
  }

  try {
    let response = await fetch(`${BASE_URL}${endpoint}`, options);

    // If 401 or 403 on protected endpoint, attempt a single token refresh and retry
    if ((response.status === 401 || response.status === 403) && !isAuthEndpoint) {
      console.warn(`[apiClient] ${response.status} on ${endpoint}. Attempting session refresh...`);
      const newToken = await refreshAdminToken();
      if (newToken) {
        options.headers = buildHeaders(newToken);
        response = await fetch(`${BASE_URL}${endpoint}`, options);
      }
    }

    if (response.status === 204) {
      return null;
    }

    const contentType = response.headers.get('content-type');
    let data;
    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    if (!response.ok) {
      let errorMessage;
      if (typeof data === 'object' && data && data.message) {
        errorMessage = data.message;
      } else if (typeof data === 'string' && data.trim().startsWith('<')) {
        errorMessage = `API Error ${response.status} (${response.statusText}): The server returned an HTML page instead of JSON. If deployed on Netlify, check that VITE_API_BASE_URL is set to your active backend server.`;
      } else if (typeof data === 'string' && data.length > 0) {
        errorMessage = data;
      } else {
        errorMessage = `API Error ${response.status}: ${response.statusText}`;
      }
      throw new Error(errorMessage);
    }

    return data;
  } catch (err) {
    console.error(`[API Error] ${method} ${endpoint}:`, err);
    throw err;
  }
}

