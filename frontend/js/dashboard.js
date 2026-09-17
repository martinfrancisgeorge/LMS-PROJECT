let allFields = [];
let currentUser = null;
let browsingField = null; // field currently shown in the grid (may differ from user's saved interest)

const fieldListEl = document.getElementById("field-list");
const fieldPickGridEl = document.getElementById("field-pick-grid");
const onboardingEl = document.getElementById("onboarding");
const materialGridEl = document.getElementById("material-grid");
const emptyStateEl = document.getElementById("empty-state");
const greetingEl = document.getElementById("greeting");
const subheadingEl = document.getElementById("subheading");

function formatHMS(totalSeconds) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = Math.floor(totalSeconds % 60);
  return [h, m, s].map((n) => String(n).padStart(2, "0")).join(":");
}

async function init() {
  try {
    const [{ user }, { fields }] = await Promise.all([apiGet("/api/me"), apiGet("/api/fields")]);
    currentUser = user;
    allFields = fields;
  } catch (err) {
    // Not logged in (or session expired) — bounce to the login page.
    window.location.href = "index.html";
    return;
  }

  greetingEl.textContent = `Hey, ${currentUser.full_name.split(" ")[0]}`;
  renderSidebarFields();
  refreshTimeStats();

  if (currentUser.interest_field) {
    subheadingEl.textContent = "Here's your feed.";
    await showMaterialsFor(currentUser.interest_field);
  } else {
    subheadingEl.textContent = "One quick step before your feed shows up.";
    onboardingEl.classList.remove("hidden");
    renderOnboardingGrid();
  }
}

function fieldMeta(slug) {
  return allFields.find((f) => f.slug === slug);
}

function renderSidebarFields() {
  fieldListEl.innerHTML = "";
  allFields.forEach((f) => {
    const li = document.createElement("li");
    const btn = document.createElement("button");
    btn.type = "button";
    btn.dataset.slug = f.slug;
    btn.innerHTML = `<span>${f.icon}</span><span>${f.label}</span>` +
      (currentUser.interest_field === f.slug ? '<span class="star">★</span>' : "");
    btn.addEventListener("click", () => showMaterialsFor(f.slug));
    li.appendChild(btn);
    fieldListEl.appendChild(li);
  });
}

function highlightSidebar(slug) {
  document.querySelectorAll("#field-list button").forEach((btn) => {
    btn.classList.toggle("active", btn.dataset.slug === slug);
  });
}

function renderOnboardingGrid() {
  fieldPickGridEl.innerHTML = "";
  allFields.forEach((f) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "field-pick-btn";
    btn.innerHTML = `<span class="icon">${f.icon}</span>${f.label}`;
    btn.addEventListener("click", () => selectField(f.slug));
    fieldPickGridEl.appendChild(btn);
  });
}

async function selectField(slug) {
  await apiPost("/api/interest", { field_slug: slug });
  currentUser.interest_field = slug;
  onboardingEl.classList.add("hidden");
  subheadingEl.textContent = "Here's your feed.";
  renderSidebarFields();
  await showMaterialsFor(slug);
}

async function showMaterialsFor(slug) {
  browsingField = slug;
  highlightSidebar(slug);

  const meta = fieldMeta(slug);
  const isPrimary = currentUser.interest_field === slug;
  greetingEl.textContent = `Hey, ${currentUser.full_name.split(" ")[0]}`;
  subheadingEl.textContent = isPrimary
    ? `Your field: ${meta ? meta.label : slug}`
    : `Browsing: ${meta ? meta.label : slug}`;

  const { materials } = await apiGet(`/api/materials?field=${encodeURIComponent(slug)}`);
  renderMaterials(materials);
}

function renderMaterials(materials) {
  materialGridEl.innerHTML = "";

  if (!materials || materials.length === 0) {
    materialGridEl.classList.add("hidden");
    emptyStateEl.classList.remove("hidden");
    return;
  }

  emptyStateEl.classList.add("hidden");
  materialGridEl.classList.remove("hidden");

  materials.forEach((m) => {
    const card = document.createElement("div");
    card.className = "material-card";
    card.innerHTML = `
      <span class="material-type">${m.resource_type}</span>
      <h3>${escapeHtml(m.title)}</h3>
      <p>${escapeHtml(m.description || "")}</p>
      <span class="platform">${escapeHtml(m.platform || "")}</span>
      <a class="open-link" href="${m.url}" target="_blank" rel="noopener noreferrer">Open resource →</a>
    `;
    materialGridEl.appendChild(card);
  });
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

async function refreshTimeStats() {
  try {
    const stats = await apiGet("/api/time-stats");
    document.getElementById("uptime-today").textContent = formatHMS(stats.today_seconds);
    document.getElementById("uptime-total").textContent = formatHMS(stats.total_seconds);
  } catch (err) {
    // non-fatal — the readout just won't update this cycle
  }
}
// exposed so tracker.js can refresh the readout after each heartbeat
window.refreshTimeStats = refreshTimeStats;

document.getElementById("logout-btn").addEventListener("click", async () => {
  try {
    await apiPost("/api/logout", {});
  } finally {
    window.location.href = "index.html";
  }
});

init();
