const { app, BrowserWindow } = require("electron");
const childProcess = require("child_process");
const fs = require("fs");
const http = require("http");
const path = require("path");

let rProcess = null;
let mainWindow = null;

function userRoot() {
  return process.env.ANALYTICS_WORKSTATION_USER_DATA ||
    path.join(process.env.LOCALAPPDATA || app.getPath("userData"), "AnalyticsWorkstation");
}

function logDir() {
  const dir = path.join(userRoot(), "logs");
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function findRscript() {
  if (process.env.RSCRIPT && fs.existsSync(process.env.RSCRIPT)) return process.env.RSCRIPT;
  const candidates = [
    "C:\\Program Files\\R\\R-4.5.2\\bin\\Rscript.exe",
    "C:\\Program Files\\R\\R-4.5.1\\bin\\Rscript.exe",
    "C:\\Program Files\\R\\R-4.4.3\\bin\\Rscript.exe"
  ];
  return candidates.find((candidate) => fs.existsSync(candidate)) || "Rscript";
}

function getPort() {
  return process.env.ANALYTICS_WORKSTATION_PORT || "0";
}

function waitForHealth(url, startedAt, timeoutMs) {
  return new Promise((resolve, reject) => {
    const attempt = () => {
      if (Date.now() - startedAt > timeoutMs) {
        reject(new Error(`Timed out waiting for ${url}`));
        return;
      }
      const request = http.get(url, (response) => {
        response.resume();
        if (response.statusCode >= 200 && response.statusCode < 500) {
          resolve(true);
        } else {
          setTimeout(attempt, 500);
        }
      });
      request.on("error", () => setTimeout(attempt, 500));
      request.setTimeout(1000, () => {
        request.destroy();
        setTimeout(attempt, 500);
      });
    };
    attempt();
  });
}

function createErrorWindow(message) {
  mainWindow = new BrowserWindow({ width: 980, height: 680, backgroundColor: "#07111f" });
  mainWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(`
    <html><body style="background:#07111f;color:#eaf2ff;font-family:Segoe UI,Arial;padding:40px">
      <h1>Analytics Workstation could not start</h1>
      <p>${message}</p>
      <p>See logs in: ${logDir()}</p>
    </body></html>
  `)}`);
}

async function startWorkstation() {
  const logs = logDir();
  const port = getPort() === "0" ? String(42000 + Math.floor(Math.random() * 10000)) : getPort();
  const url = `http://127.0.0.1:${port}`;
  const out = fs.openSync(path.join(logs, "electron-shiny.log"), "a");
  const err = fs.openSync(path.join(logs, "electron-shiny-error.log"), "a");

  rProcess = childProcess.spawn(findRscript(), ["-e", `AnalyticsShinyApp::run_workstation(host='127.0.0.1', port=${port}, launch_browser=FALSE)`], {
    cwd: userRoot(),
    env: { ...process.env, ANALYTICS_WORKSTATION_PORT: port },
    detached: false,
    stdio: ["ignore", out, err]
  });

  fs.writeFileSync(path.join(logs, "electron-shiny.pid"), String(rProcess.pid));

  try {
    await waitForHealth(url, Date.now(), 45000);
  } catch (error) {
    createErrorWindow(error.message);
    return;
  }

  mainWindow = new BrowserWindow({
    width: 1440,
    height: 950,
    backgroundColor: "#07111f",
    title: "Analytics Workstation"
  });
  mainWindow.loadURL(url);
}

app.whenReady().then(startWorkstation);

app.on("window-all-closed", () => {
  if (rProcess && !rProcess.killed) {
    rProcess.kill();
  }
  app.quit();
});
