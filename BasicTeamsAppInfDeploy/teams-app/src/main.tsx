import React from "react";
import ReactDOM from "react-dom/client";
import { app } from "@microsoft/teams-js";
import { App } from "./App";
import "./styles.css";

async function initializeTeams(): Promise<boolean> {
  try {
    await app.initialize();
    return true;
  } catch {
    return false;
  }
}

initializeTeams().then((isRunningInTeams) => {
  ReactDOM.createRoot(document.getElementById("root")!).render(
    <React.StrictMode>
      <App isRunningInTeams={isRunningInTeams} />
    </React.StrictMode>
  );
});
