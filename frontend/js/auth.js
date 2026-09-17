// ------------------------------------------------------------
// Tiny fetch helpers: talk JSON, send the session cookie.
// Shared with dashboard.js / tracker.js (loaded on both pages).
// ------------------------------------------------------------
async function apiPost(path, body) {
  const res = await fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "same-origin",
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || "Something went wrong.");
  return data;
}

async function apiGet(path) {
  const res = await fetch(path, { credentials: "same-origin" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || "Something went wrong.");
  return data;
}

// ------------------------------------------------------------
// Everything below is auth-page-only. This file is also loaded
// on dashboard.html (for the helpers above), so guard on the
// elements actually existing before wiring listeners.
// ------------------------------------------------------------
const loginForm = document.getElementById("login-form");
const signupForm = document.getElementById("signup-form");
const tabLoginBtn = document.getElementById("tab-login-btn");
const tabSignupBtn = document.getElementById("tab-signup-btn");

if (loginForm && signupForm && tabLoginBtn && tabSignupBtn) {

  const showLogin = () => {
    loginForm.classList.remove("hidden");
    signupForm.classList.add("hidden");
    tabLoginBtn.classList.add("active");
    tabSignupBtn.classList.remove("active");
  };

  const showSignup = () => {
    signupForm.classList.remove("hidden");
    loginForm.classList.add("hidden");
    tabSignupBtn.classList.add("active");
    tabLoginBtn.classList.remove("active");
  };

  tabLoginBtn.addEventListener("click", showLogin);
  tabSignupBtn.addEventListener("click", showSignup);

  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const msg = document.getElementById("login-msg");
    const submitBtn = document.getElementById("login-submit");
    msg.className = "form-msg";
    msg.textContent = "";

    const email = document.getElementById("login-email").value.trim();
    const password = document.getElementById("login-password").value;

    submitBtn.disabled = true;
    try {
      await apiPost("/api/login", { email, password });
      window.location.href = "dashboard.html";
    } catch (err) {
      msg.className = "form-msg error";
      msg.textContent = err.message;
    } finally {
      submitBtn.disabled = false;
    }
  });

  signupForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const msg = document.getElementById("signup-msg");
    const submitBtn = document.getElementById("signup-submit");
    msg.className = "form-msg";
    msg.textContent = "";

    const full_name = document.getElementById("signup-name").value.trim();
    const email = document.getElementById("signup-email").value.trim();
    const password = document.getElementById("signup-password").value;

    submitBtn.disabled = true;
    try {
      await apiPost("/api/signup", { full_name, email, password });
      window.location.href = "dashboard.html";
    } catch (err) {
      msg.className = "form-msg error";
      msg.textContent = err.message;
    } finally {
      submitBtn.disabled = false;
    }
  });
}
