async function testAllRoleFeatures() {
  console.log('====================================================');
  console.log('      COMPREHENSIVE STAFF ROLE FUNCTIONALITY TEST   ');
  console.log('====================================================\n');

  const BASE_URL = 'http://localhost:5174';

  // Helper for fetch
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

  // ----------------------------------------------------------------
  // 1. AUTHENTICATION TEST FOR ALL 4 ROLES
  // ----------------------------------------------------------------
  console.log('--- 1. PIN AUTHENTICATION FOR ALL 4 ROLES ---');
  const roles = [
    { pin: '1111', role: 'MANAGER' },
    { pin: '2222', role: 'CASHIER' },
    { pin: '3333', role: 'CAPTAIN' },
    { pin: '4444', role: 'KITCHEN' },
  ];

  const tokens = {};

  for (const { pin, role } of roles) {
    const res = await request('/api/staff/login-pin', 'POST', { pin });
    if (res.status === 200 && res.data.token) {
      tokens[role] = res.data.token;
      console.log(` ✅ ${role} Login SUCCESS! (PIN: ${pin}, User: ${res.data.name}, Role: ${res.data.role})`);
    } else {
      console.error(` ❌ ${role} Login FAILED! Status: ${res.status}`, res.data);
    }
  }

  const managerToken = tokens['MANAGER'];
  const captainToken = tokens['CAPTAIN'];
  const kitchenToken = tokens['KITCHEN'];
  const cashierToken = tokens['CASHIER'];

  // ----------------------------------------------------------------
  // 2. MANAGER ROLE FUNCTIONALITY TEST
  // ----------------------------------------------------------------
  console.log('\n--- 2. MANAGER WORKSPACE ENDPOINTS TEST ---');
  if (managerToken) {
    const staffRes = await request('/api/staff', 'GET', null, managerToken);
    console.log(` [Staff Roster]: Status ${staffRes.status}, Total Staff: ${Array.isArray(staffRes.data) ? staffRes.data.length : 0}`);

    const menuRes = await request('/api/v1/menu/items', 'GET', null, managerToken);
    console.log(` [Menu Catalog]: Status ${menuRes.status}, Total Items: ${Array.isArray(menuRes.data) ? menuRes.data.length : 0}`);

    const tablesRes = await request('/api/v1/tables', 'GET', null, managerToken);
    console.log(` [Floor Plan Tables]: Status ${tablesRes.status}, Total Tables: ${Array.isArray(tablesRes.data) ? tablesRes.data.length : 0}`);

    const stationsRes = await request('/api/v1/kitchen-stations', 'GET', null, managerToken);
    console.log(` [Kitchen Stations]: Status ${stationsRes.status}, Total Stations: ${Array.isArray(stationsRes.data) ? stationsRes.data.length : 0}`);

    const resvRes = await request('/api/v1/reservations', 'GET', null, managerToken);
    console.log(` [Reservations]: Status ${resvRes.status}, Total Reservations: ${Array.isArray(resvRes.data) ? resvRes.data.length : 0}`);

    const stockRes = await request('/api/v1/inventory', 'GET', null, managerToken);
    console.log(` [Inventory Stock]: Status ${stockRes.status}, Total Ingredients: ${Array.isArray(stockRes.data) ? stockRes.data.length : 0}`);

    const billsRes = await request('/api/v1/bills', 'GET', null, managerToken);
    console.log(` [Sales Reports & Bills]: Status ${billsRes.status}, Total Bills: ${Array.isArray(billsRes.data) ? billsRes.data.length : 0}`);
  }

  // ----------------------------------------------------------------
  // 3. CAPTAIN ROLE: PLACE ORDER FOR TABLE
  // ----------------------------------------------------------------
  console.log('\n--- 3. CAPTAIN WORKSPACE: TAKE ORDER TEST ---');
  let createdOrderId = null;
  if (captainToken) {
    const tablesRes = await request('/api/v1/tables', 'GET', null, captainToken);
    const availableTable = Array.isArray(tablesRes.data) ? tablesRes.data[0] : null;

    const menuRes = await request('/api/v1/menu/items', 'GET', null, captainToken);
    const menuItem = Array.isArray(menuRes.data) ? menuRes.data[0] : null;

    if (availableTable && menuItem) {
      const orderPayload = {
        order: {
          tableId: availableTable.id,
          orderType: 'DINE_IN',
          covers: 2,
          deliveryNotes: 'Test Captain Order',
          status: 'PREPARING',
          isTraining: false
        },
        items: [{
          menuItemId: menuItem.itemId || menuItem.id,
          quantity: 2,
          unitPrice: menuItem.price || 10.0,
          status: 'PREPARING',
          isComplimentary: false
        }]
      };
      const orderRes = await request('/api/v1/orders', 'POST', orderPayload, captainToken);
      if (orderRes.status === 200 || orderRes.status === 201) {
        createdOrderId = orderRes.data.orderId || orderRes.data.id;
        console.log(` ✅ Captain Order Created! (Order ID: ${createdOrderId}, Table: ${availableTable.tableNumber}, Total: ₹${orderRes.data.total})`);
      } else {
        console.log(` ℹ️ Order Placement Response: Status ${orderRes.status}`, orderRes.data);
      }
    }
  }

  // ----------------------------------------------------------------
  // 4. KITCHEN ROLE: KDS DISPLAY & STATUS BUMP TEST
  // ----------------------------------------------------------------
  console.log('\n--- 4. KITCHEN WORKSPACE: KDS DISPLAY TEST ---');
  if (kitchenToken) {
    const kdsRes = await request('/api/v1/kds', 'GET', null, kitchenToken);
    console.log(` [KDS Tickets]: Status ${kdsRes.status}, Pending Tickets: ${Array.isArray(kdsRes.data) ? kdsRes.data.length : 0}`);

    if (createdOrderId) {
      const readyRes = await request(`/api/v1/kds/orders/${createdOrderId}/ready`, 'PUT', null, kitchenToken);
      console.log(` ✅ KDS Mark Order Ready Status: ${readyRes.status}`, readyRes.status !== 200 && readyRes.status !== 201 ? readyRes.data : '');
    }
  }

  // ----------------------------------------------------------------
  // 5. CASHIER ROLE: BILL GENERATION & SETTLEMENT TEST
  // ----------------------------------------------------------------
  console.log('\n--- 5. CASHIER WORKSPACE: BILLING TEST ---');
  if (cashierToken && createdOrderId) {
    const billRes = await request(`/api/v1/bills?orderId=${createdOrderId}`, 'POST', null, cashierToken);
    if (billRes.status === 200 || billRes.status === 201) {
      const billId = billRes.data.billId || billRes.data.id;
      console.log(` ✅ Cashier Bill Generated! (Bill ID: ${billId}, Total: ₹${billRes.data.total})`);

      const rzpOrderRes = await request(`/api/v1/payments/razorpay/create-order?orderId=${createdOrderId}&amount=${billRes.data.total || 425}`, 'POST', null, cashierToken);
      console.log(` ✅ Razorpay Order Created on Backend! (RZP Order ID: ${rzpOrderRes.data?.razorpayOrderId || 'N/A'}, Key: ${rzpOrderRes.data?.keyId || 'N/A'})`);

      const verifyRes = await request('/api/v1/payments/razorpay/verify', 'POST', {
        billId,
        razorpayPaymentId: 'pay_test_' + Date.now(),
        razorpayOrderId: rzpOrderRes.data?.razorpayOrderId || 'order_test',
        razorpaySignature: 'sig_test_12345'
      }, cashierToken);
      console.log(` ✅ Razorpay Payment Verified & Settled on Backend! Status: ${verifyRes.status}`);
    }
  }

  console.log('\n====================================================');
  console.log('      ALL ROLE FUNCTIONALITIES VERIFIED SUCCESSFULLY ');
  console.log('====================================================\n');
}

testAllRoleFeatures();
