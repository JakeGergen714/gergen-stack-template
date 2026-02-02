import React, { useEffect, useState } from 'react'
import ReactDOM from 'react-dom/client'

// Type definition for window.ENV
declare global {
  interface Window {
    ENV: {
      API_URL: string;
      ENV_NAME: string;
    }
  }
}

const App = () => {
  const [health, setHealth] = useState<any>(null);
  const [error, setError] = useState<string>("");

  const apiUrl = window.ENV?.API_URL || "http://localhost:8080";

  useEffect(() => {
    fetch(`${apiUrl}/actuator/health`)
      .then(res => res.json())
      .then(data => setHealth(data))
      .catch(err => setError(err.message));
  }, [apiUrl]);

  return (
    <div style={{ fontFamily: 'system-ui, sans-serif', maxWidth: '800px', margin: '0 auto', padding: '2rem' }}>
      <h1>Gergen Stack: {window.ENV?.ENV_NAME}</h1>
      <p>API URL: <code>{apiUrl}</code></p>
      
      <div style={{ padding: '1rem', border: '1px solid #ccc', borderRadius: '4px', marginTop: '1rem' }}>
        <h3>Backend Status</h3>
        {error && <p style={{ color: 'red' }}>Error: {error}</p>}
        {!health && !error && <p>Loading...</p>}
        {health && <pre>{JSON.stringify(health, null, 2)}</pre>}
      </div>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
