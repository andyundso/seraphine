import React, { useEffect, useRef, useState } from 'react';
import { SystemAlarms } from './types'
import { formatISO9075, fromUnixTime } from 'date-fns'

function App() {
  const [alarms, setAlarms] = useState<SystemAlarms>({});
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
      const message: SystemAlarms = JSON.parse(e.data);
      setAlarms(message)
    };
  }, [alarms]);

  return (
    <>
      <h3 className="title is-3">Netdata alarms</h3>

      { Object.keys(alarms).length > 0 && <table className="table is-bordered">
        <thead>
          <tr>
            <th>System</th>
            <th>Alarm</th>
            <th>Current value</th>
            <th>Last status change</th>
          </tr>
        </thead>
        <tbody>
          {Object.keys(alarms).map(system_name =>
            alarms[system_name].map(alarms =>
              <tr key={alarms.value}>
                <td>{system_name} </td>
                <td>{alarms.name}</td>
                <td>{alarms.value}</td>
                <td>{formatISO9075(fromUnixTime(alarms.last_raised))}</td>
              </tr>
            )
          )}
        </tbody>
      </table>}

      { Object.keys(alarms).length <= 0 && <p>No data available</p>}
    </>
  );
}

export default App;
