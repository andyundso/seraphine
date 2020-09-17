import React, { useEffect, useRef, useState } from 'react';
import { SystemAlarms } from './types'
import { formatISO9075, fromUnixTime } from 'date-fns'
import useWebSocket from 'react-use-websocket';
import { Notification } from './Notification';

function App() {
  const [alarms, setAlarms] = useState<SystemAlarms>({});
  const didUnmount = useRef(false);

  const {
    readyState
  } = useWebSocket('ws://localhost:8000/alarms', {

    onMessage: (data) => {
      const message: SystemAlarms = JSON.parse(data.data);
      setAlarms(message)
    },

    shouldReconnect: (closeEvent) => {
      /*
        useWebSocket will handle unmounting for you, but this is an example of a 
        case in which you would not want it to automatically reconnect
      */
      return didUnmount.current === false;
    }
  });

  return (
    <>
      <h3 className="title is-3">Netdata alarms</h3>

      { readyState != 1 && <Notification />}

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
