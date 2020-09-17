import React from "react";

export const Notification = () =>
  <div className="notification is-warning">
    <button className="delete"></button>
    Connection to the backend is lost.
    We'll try again in a few seconds.
  </div>
