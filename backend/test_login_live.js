async function testLogin(baseUrl, label) {
  console.log(`\n==================================================`);
  console.log(`TESTING LOGIN ON: ${label} (${baseUrl})`);
  console.log(`==================================================`);

  // 1. Check health
  try {
    const healthRes = await fetch(`${baseUrl.replace('/api/v1', '')}/health`);
    const healthJson = await healthRes.json();
    console.log(`[Health] Status: ${healthRes.status}`);
    console.log(`[Health] Database:`, healthJson.database);
  } catch (err) {
    console.log(`[Health] Failed to connect:`, err.message);
  }

  // 2. Test Admin Login
  try {
    const adminBody = {
      phoneNumber: '0900000000',
      password: 'AdminPassword123!',
      deviceId: 'test-device-123',
    };
    console.log(`\n[Admin Login] POST ${baseUrl}/auth/admin/login`);
    console.log(`Payload:`, JSON.stringify(adminBody));
    
    const res = await fetch(`${baseUrl}/auth/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(adminBody),
    });

    const resJson = await res.json();
    console.log(`[Admin Login] Response HTTP Status:`, res.status);
    console.log(`[Admin Login] Response Body:`, JSON.stringify(resJson, null, 2));
  } catch (err) {
    console.log(`[Admin Login] Network Error:`, err.message);
  }

  // 3. Test Owner Login
  try {
    const ownerBody = {
      phoneNumber: '0911223344',
      password: 'Password123!',
      deviceId: 'test-device-123',
    };
    console.log(`\n[Owner Login] POST ${baseUrl}/auth/login`);
    console.log(`Payload:`, JSON.stringify(ownerBody));

    const res = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(ownerBody),
    });

    const resJson = await res.json();
    console.log(`[Owner Login] Response HTTP Status:`, res.status);
    console.log(`[Owner Login] Response Body:`, JSON.stringify(resJson, null, 2));
  } catch (err) {
    console.log(`[Owner Login] Network Error:`, err.message);
  }
}

async function run() {
  // Test 1: Remote Cloud Backend (Render)
  await testLogin('https://kera-spare-tracker-api.onrender.com/api/v1', 'RENDER CLOUD');

  // Test 2: Local Backend if running
  await testLogin('http://localhost:7000/api/v1', 'LOCAL SERVER');
}

run();
