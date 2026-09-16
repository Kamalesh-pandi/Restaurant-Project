async function testFixedEndpoints() {
  console.log('Testing specific bug fixes and permissions...');
  const BASE_URL = 'http://localhost:5174';

  async function request(endpoint, method = 'GET', body = null, token = null) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const options = { method, headers };
    if (body) options.body = JSON.stringify(body);

    const res = await fetch(`${BASE_URL}${endpoint}`, options);
    const contentType = res.headers.get('content-type');
    let data;
    if (contentType && contentType.includes('application/json')) {
      data = await res.json();
    } else {
      data = await res.text();
    }
    return { status: res.status, data };
  }

  // 1. Logins
  const mgrRes = await request('/api/staff/login-pin', 'POST', { pin: '1111' });
  const cashierRes = await request('/api/staff/login-pin', 'POST', { pin: '2222' });
  const captainRes = await request('/api/staff/login-pin', 'POST', { pin: '3333' });
  const kitchenRes = await request('/api/staff/login-pin', 'POST', { pin: '4444' });

  const mgrToken = mgrRes.data.token;
  const cashierToken = cashierRes.data.token;
  const captainToken = captainRes.data.token;
  const kitchenToken = kitchenRes.data.token;

  console.log('\n--- 1. Chain Promotions Fix (GET & POST) ---');
  const promoGetRes = await request('/api/v1/chain/promotions', 'GET', null, mgrToken);
  console.log(`GET /api/v1/chain/promotions status: ${promoGetRes.status} (Count: ${Array.isArray(promoGetRes.data) ? promoGetRes.data.length : 0})`);

  const promoPostRes = await request('/api/v1/chain/promotions', 'POST', {
    promoCode: 'TEST50',
    description: '50% Test Promo',
    discountPercentage: 50,
    validFrom: new Date().toISOString(),
    validTo: new Date(Date.now() + 7 * 86400000).toISOString(),
    isActive: true
  }, mgrToken);
  console.log(`POST /api/v1/chain/promotions as MANAGER status: ${promoPostRes.status}`);

  console.log('\n--- 2. Turn Time Analytics for Cashier & Captain ---');
  const cashierTurn = await request('/api/v1/tables/analytics/turn-time', 'GET', null, cashierToken);
  console.log(`CASHIER /analytics/turn-time status: ${cashierTurn.status} (turnTime: ${cashierTurn.data})`);
  const captainTurn = await request('/api/v1/tables/analytics/turn-time', 'GET', null, captainToken);
  console.log(`CAPTAIN /analytics/turn-time status: ${captainTurn.status} (turnTime: ${captainTurn.data})`);

  console.log('\n--- 3. Reservation Analytics for Cashier & Captain ---');
  const cashierResv = await request('/api/v1/reservations/analytics', 'GET', null, cashierToken);
  console.log(`CASHIER /reservations/analytics status: ${cashierResv.status}`);
  const captainResv = await request('/api/v1/reservations/analytics', 'GET', null, captainToken);
  console.log(`CAPTAIN /reservations/analytics status: ${captainResv.status}`);

  console.log('\n--- 4. Kitchen Chef Station Creation ---');
  const stationPost = await request('/api/v1/kitchen-stations', 'POST', { name: 'GRILL_STATION' }, kitchenToken);
  console.log(`KITCHEN create station status: ${stationPost.status}`);

  console.log('\n--- 5. Manager Bill Generation ---');
  const orders = await request('/api/v1/orders', 'GET', null, mgrToken);
  const activeOrder = Array.isArray(orders.data) ? orders.data[0] : null;
  if (activeOrder) {
    const mgrBill = await request(`/api/v1/bills?orderId=${activeOrder.orderId || activeOrder.id}`, 'POST', null, mgrToken);
    console.log(`MANAGER generate bill status: ${mgrBill.status}`);
  }

  console.log('\n--- 6. Manager Payroll Export ---');
  const payroll = await request('/api/staff/payroll/export', 'GET', null, mgrToken);
  console.log(`MANAGER payroll export status: ${payroll.status} (CSV length: ${typeof payroll.data === 'string' ? payroll.data.length : 0})`);

  console.log('\nAll fixed endpoint tests completed!');
}

testFixedEndpoints();
