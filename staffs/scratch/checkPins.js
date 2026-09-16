async function checkPinMatch() {
  const pins = ['1111', '1234', '2222', '3333', '4444', '0000'];
  for (const pin of pins) {
    const res = await fetch('http://localhost:8080/api/staff/login-pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin })
    });
    const data = await res.json();
    console.log(`PIN '${pin}' -> HTTP ${res.status}:`, data);
  }
}

checkPinMatch();
