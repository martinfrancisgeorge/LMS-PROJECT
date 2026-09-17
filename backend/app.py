from datetime import date
from functools import wraps

from flask import Flask, request, jsonify, session, send_from_directory
from werkzeug.security import generate_password_hash, check_password_hash

from config import Config
import db

app = Flask(__name__, static_folder="../frontend", static_url_path="")
app.config.from_object(Config)


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
def login_required(fn):
    """Simple decorator: block the route unless a user is logged in."""
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if "user_id" not in session:
            return jsonify({"error": "Not logged in"}), 401
        return fn(*args, **kwargs)
    return wrapper


def current_user():
    return db.query_one(
        "SELECT id, full_name, email, interest_field FROM users WHERE id = %s",
        (session["user_id"],),
    )


# ------------------------------------------------------------------
# Serve the plain HTML/CSS/JS frontend
# ------------------------------------------------------------------
@app.route("/")
def serve_index():
    return send_from_directory(app.static_folder, "index.html")


@app.route("/dashboard.html")
def serve_dashboard():
    return send_from_directory(app.static_folder, "dashboard.html")


# ------------------------------------------------------------------
# Auth
# ------------------------------------------------------------------
@app.route("/api/signup", methods=["POST"])
def signup():
    data = request.get_json(silent=True) or {}
    full_name = (data.get("full_name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not full_name or not email or not password:
        return jsonify({"error": "Name, email and password are all required."}), 400
    if len(password) < 8:
        return jsonify({"error": "Password must be at least 8 characters."}), 400
    if "@" not in email or "." not in email:
        return jsonify({"error": "Enter a valid email address."}), 400

    existing = db.query_one("SELECT id FROM users WHERE email = %s", (email,))
    if existing:
        return jsonify({"error": "An account with that email already exists."}), 409

    password_hash = generate_password_hash(password)
    user_id, _ = db.execute(
        "INSERT INTO users (full_name, email, password_hash) VALUES (%s, %s, %s)",
        (full_name, email, password_hash),
    )

    session["user_id"] = user_id
    return jsonify({"message": "Account created.", "user": {
        "id": user_id, "full_name": full_name, "email": email, "interest_field": None
    }}), 201


@app.route("/api/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    user = db.query_one(
        "SELECT id, full_name, email, password_hash, interest_field FROM users WHERE email = %s",
        (email,),
    )
    if not user or not check_password_hash(user["password_hash"], password):
        return jsonify({"error": "Invalid email or password."}), 401

    session["user_id"] = user["id"]
    return jsonify({"message": "Logged in.", "user": {
        "id": user["id"], "full_name": user["full_name"],
        "email": user["email"], "interest_field": user["interest_field"],
    }})


@app.route("/api/logout", methods=["POST"])
def logout():
    session.clear()
    return jsonify({"message": "Logged out."})


@app.route("/api/me", methods=["GET"])
@login_required
def me():
    return jsonify({"user": current_user()})


# ------------------------------------------------------------------
# Fields of interest
# ------------------------------------------------------------------
@app.route("/api/fields", methods=["GET"])
def list_fields():
    return jsonify({"fields": db.query_all("SELECT slug, label, icon FROM fields ORDER BY label")})


@app.route("/api/interest", methods=["POST"])
@login_required
def set_interest():
    data = request.get_json(silent=True) or {}
    slug = data.get("field_slug")

    valid = db.query_one("SELECT slug FROM fields WHERE slug = %s", (slug,))
    if not valid:
        return jsonify({"error": "Unknown field."}), 400

    db.execute("UPDATE users SET interest_field = %s WHERE id = %s", (slug, session["user_id"]))
    return jsonify({"message": "Field of interest updated.", "interest_field": slug})


# ------------------------------------------------------------------
# Materials
# ------------------------------------------------------------------
@app.route("/api/materials", methods=["GET"])
@login_required
def materials():
    # Defaults to the student's chosen field, but a `field` query param
    # lets them browse other fields too.
    field = request.args.get("field")
    if not field:
        user = current_user()
        field = user["interest_field"]
    if not field:
        return jsonify({"materials": [], "field": None})

    rows = db.query_all(
        "SELECT id, title, url, resource_type, platform, description "
        "FROM materials WHERE field_slug = %s ORDER BY id",
        (field,),
    )
    return jsonify({"materials": rows, "field": field})


# ------------------------------------------------------------------
# Time tracking
# ------------------------------------------------------------------
@app.route("/api/track", methods=["POST"])
@login_required
def track_time():
    """
    Called by the frontend as a periodic heartbeat while the dashboard
    tab is open and focused. We add a fixed interval server-side
    (rather than trusting a client-supplied number) to keep it honest.
    """
    today = date.today()
    seconds = Config.HEARTBEAT_INTERVAL_SECONDS

    db.execute(
        """
        INSERT INTO time_logs (user_id, log_date, seconds_spent)
        VALUES (%s, %s, %s)
        ON DUPLICATE KEY UPDATE seconds_spent = seconds_spent + VALUES(seconds_spent)
        """,
        (session["user_id"], today, seconds),
    )
    return jsonify({"message": "ok"})


@app.route("/api/time-stats", methods=["GET"])
@login_required
def time_stats():
    today = date.today()
    today_row = db.query_one(
        "SELECT seconds_spent FROM time_logs WHERE user_id = %s AND log_date = %s",
        (session["user_id"], today),
    )
    total_row = db.query_one(
        "SELECT COALESCE(SUM(seconds_spent), 0) AS total FROM time_logs WHERE user_id = %s",
        (session["user_id"],),
    )
    return jsonify({
        "today_seconds": today_row["seconds_spent"] if today_row else 0,
        "total_seconds": int(total_row["total"]) if total_row else 0,
    })


if __name__ == "__main__":
    # host 0.0.0.0 so this is reachable when it's later run inside a container
    app.run(host="0.0.0.0", port=Config.PORT, debug=Config.DEBUG)
