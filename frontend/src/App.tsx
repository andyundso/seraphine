import React, { useEffect, useRef, useState } from 'react';

function App() {
  const [alarms, setAlarms] = useState();
  const ws = useRef<WebSocket | null>(null);

  useEffect(() => {
    ws.current = new WebSocket('ws://localhost:8000/alarms');
    ws.current.onopen = () => console.log("WebSocket openend");
    ws.current.onclose = () => console.log("WebSocket closed");

    return () => {
      ws.current?.close();
    }
  }, [])

  useEffect(() => {
    if (!ws.current) return;

    ws.current.onmessage = e => {
      const message = JSON.parse(e.data);
      setAlarms(message)
    };
  }, [alarms]);

  return (
    <>
      <h3 className="title is-3">Netdata alarms</h3>
      <table className="table is-bordered">
        <thead>
          <tr>
            <th>System</th>
            <th>Alarm</th>
            <th>Last status change</th>
            <th>Current value</th>
          </tr>
        </thead>
        <tbody>

        </tbody>
      </table>
    </>
  );
}

export default App;
