// Centralized HTTP client using native fetch with JWT handling
const BASE_URL = ''; // Relative path, handled by Vite proxy to http://localhost:8080

export async function apiRequest(endpoint, method = 'GET', body = null, customHeaders = {}) {
  // Do NOT send Authorization header on login/auth endpoints
  const isAuthEndpoint = endpoint.includes('/login') || endpoint.includes('/login-pin');
  const token = !isAuthEndpoint ? (localStorage.getItem('staff_jwt_token') || localStorage.getItem('pos_jwt_token')) : null;

  const headers = {
    'Content-Type': 'application/json',
    ...customHeaders,
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const options = {
    method,
    headers,
  };

  if (body) {
    if (typeof body === 'string') {
      options.body = body;
    } else {
      options.body = JSON.stringify(body);
    }
  }

  try {
    const response = await fetch(`${BASE_URL}${endpoint}`, options);

    if (response.status === 401 && !isAuthEndpoint) {
      console.warn('[StaffAPI] Session expired or unauthorized.');
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
      const errorMessage = typeof data === 'object' && data.message ? data.message : (typeof data === 'string' ? data : 'API Error occurred');
      throw new Error(errorMessage);
    }

    return data;
  } catch (err) {
    console.error(`[StaffAPI Error] ${method} ${endpoint}:`, err);
    throw err;
  }
}
