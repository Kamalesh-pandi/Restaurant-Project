async function testViteProxy() {
  console.log('--- TESTING VITE PROXY PORT 5174 ---');
  try {
    const res = await fetch('http://localhost:5174/api/staff/login-pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin: '1111' })
    });
    const data = await res.json();
    console.log('Vite Proxy 5174 PIN 1111 Status:', res.status, data);
  } catch (err) {
    console.error('Vite Proxy 5174 Error:', err.message);
  }
}

testViteProxy();
