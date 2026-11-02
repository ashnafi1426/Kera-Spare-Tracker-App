async function check() {
  try {
    const res = await fetch('https://kera-spare-tracker-api.onrender.com/health');
    const json = await res.json();
    console.log('Render health status:', res.status, json);
  } catch (err) {
    console.log('Render health error:', err.message);
  }
}
check();
