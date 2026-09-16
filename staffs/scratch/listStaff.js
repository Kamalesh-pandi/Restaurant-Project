async function listAllStaff() {
  // Login as admin first
  const adminRes = await fetch('http://localhost:8080/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'password' })
  });
  const adminData = await adminRes.json();
  const token = adminData.token;

  console.log('Admin Login OK, fetching /api/staff...');

  const staffRes = await fetch('http://localhost:8080/api/staff', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const staffList = await staffRes.json();
  console.log('--- ALL STAFF MEMBERS IN DATABASE ---');
  console.log(staffList);
}

listAllStaff();
