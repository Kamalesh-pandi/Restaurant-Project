async function testLogins() {
  console.log('--- TESTING POS BACKEND LOGIN ENDPOINTS ---');

  // Test 1: Staff PIN login (Manager PIN 1111)
  try {
    const res1 = await fetch('http://localhost:8080/api/staff/login-pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin: '1111' })
    });
    const data1 = await res1.json();
    console.log('1. PIN 1111 Login Status:', res1.status, data1);
  } catch (err) {
    console.error('1. PIN 1111 Error:', err.message);
  }

  // Test 2: Staff PIN login with name (manager + 1111)
  try {
    const res2 = await fetch('http://localhost:8080/api/staff/login-pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'manager', pin: '1111' })
    });
    const data2 = await res2.json();
    console.log('2. Name manager PIN 1111 Login Status:', res2.status, data2);
  } catch (err) {
    console.error('2. Name manager Error:', err.message);
  }

  // Test 3: Admin login
  try {
    const res3 = await fetch('http://localhost:8080/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'admin', email: 'admin@restaurant.com', password: 'password' })
    });
    const data3 = await res3.json();
    console.log('3. Admin Email Login Status:', res3.status, data3);
  } catch (err) {
    console.error('3. Admin Email Login Error:', err.message);
  }
}

testLogins();
