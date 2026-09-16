async function testAllPins() {
  const pins = ['1111', '2222', '3333', '4444'];
  for (const pin of pins) {
    const res = await fetch('http://localhost:8080/api/staff/login-pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin })
    });
    const data = await res.json();
    console.log(`PIN ${pin} -> Status ${res.status}:`, data.name, data.role);
  }
}

testAllPins();
