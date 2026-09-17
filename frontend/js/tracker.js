// Must match backend/config.py HEARTBEAT_INTERVAL_SECONDS (default 30s).
const HEARTBEAT_INTERVAL_MS = 30 * 1000;

async function sendHeartbeat() {
  // Only count time when the tab is actually visible and focused —
  // an unfocused background tab shouldn't rack up "study time".
  if (document.visibilityState !== "visible" || !document.hasFocus()) return;

  try {
    await apiPost("/api/track", {});
    if (typeof window.refreshTimeStats === "function") {
      window.refreshTimeStats();
    }
  } catch (err) {
    // If the session expired mid-page, the next dashboard action
    // (or page reload) will bounce the user back to login anyway.
  }
}

setInterval(sendHeartbeat, HEARTBEAT_INTERVAL_MS);
