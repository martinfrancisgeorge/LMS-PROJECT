# Fieldwork — a small LMS (DevOps portfolio project)

Students sign up, pick a field (developer / devops / cybersecurity / linux /
cloud), get a curated feed of videos/articles/courses for that field, and can
see how much time they've spent in the app.

**Stack:** plain HTML/CSS/JS frontend · Python (Flask) backend · MySQL.

```
lms-project/
├── backend/
│   ├── app.py            # Flask app: routes + serves the frontend
│   ├── db.py              # MySQL connection pool + query helpers
│   ├── config.py          # All settings, read from env vars
│   ├── schema.sql          # Creates the database + tables
│   ├── seed_data.sql       # Learning fields + starter materials
│   ├── requirements.txt
│   └── .env.example
└── frontend/
    ├── index.html          # Login / signup
    ├── dashboard.html      # Field feed + time readout
    ├── css/style.css
    └── js/
        ├── auth.js         # login/signup calls
        ├── dashboard.js    # fields, materials, time display
        └── tracker.js      # sends a heartbeat every 30s while tab is active
```

## 1. Set up MySQL

```bash
mysql -u root -p < backend/schema.sql
mysql -u root -p < backend/seed_data.sql
```

This creates a `lms_db` database with `users`, `fields`, `materials`, and
`time_logs` tables, plus a starter set of curated materials per field. Add
more rows to `materials` any time — nothing is hardcoded in the app code.

## 2. Configure the backend

```bash
cd backend
cp .env.example .env    # then edit DB_PASSWORD etc.
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

`app.py` reads config from environment variables, not from `.env` directly —
either export the values from `.env.example` yourself, or add
`python-dotenv` later (one `pip install` + two lines in `app.py`) once you
containerize, since Docker Compose can also inject env vars for you without
needing dotenv at all.

## 3. Run it

```bash
export SECRET_KEY=some-long-random-string
export DB_PASSWORD=your-mysql-password
# (and any other vars from .env.example that differ from the defaults)
python3 app.py
```

Visit **http://localhost:5000** — Flask serves both the API and the
frontend (`frontend/` is mounted as the static folder), so there's nothing
separate to run for the UI and no CORS setup needed.

## How the pieces fit together

- **Auth**: `werkzeug.security` hashes passwords (no plaintext ever
  touches the DB); sessions are Flask's signed cookie — no separate
  session store needed for a project this size.
- **Field selection**: `users.interest_field` stores the student's primary
  track. The sidebar lets them browse any field's materials without
  changing their saved one.
- **Materials**: served straight from the `materials` table — swap in a
  live YouTube Data API call later if you want, the `/api/materials` route
  is the only place that would need to change.
- **Time tracking**: `frontend/js/tracker.js` pings `/api/track` every 30s
  while the dashboard tab is visible *and* focused. The server adds a fixed
  30s per ping (not a client-supplied number) so a student can't just send
  fake numbers to inflate their stats.

## Getting this ready for containerization (next phase)

The project's already structured for it:
- Backend and frontend are separate folders — Flask happens to serve both
  today, but you could split them into two containers later without
  restructuring.
- **Nothing is hardcoded** — host, port, DB credentials, secret key, and
  the heartbeat interval all come from environment variables
  (`config.py`), which map directly to `docker-compose.yml` `environment:`
  entries or a `.env` file.
- `db.py` uses a connection pool and reads `DB_HOST` from env — point it at
  a `mysql` service name in Compose and it works unchanged.
- Natural next steps: a `Dockerfile` for the backend (`python:3.12-slim`,
  copy `backend/` + `frontend/`, `pip install -r requirements.txt`, `CMD
  ["python", "app.py"]`), a `docker-compose.yml` with `web` + `mysql`
  services (mounting `schema.sql`/`seed_data.sql` into MySQL's
  `docker-entrypoint-initdb.d/` so it seeds itself on first boot), and a
  named volume for MySQL data so it persists across container restarts.

## Known limitations (worth knowing, not blockers)

- Sessions are cookie-based, so this runs as a single backend instance for
  now — fine for a portfolio project, but multi-instance deployments would
  need a shared session store (e.g. Redis) or JWTs instead.
- Materials are curated/manually seeded rather than pulled live from the
  YouTube API — deliberate, to avoid needing an API key/quota just to run
  the project, but easy to layer in later.
- No password reset / email verification flow — out of scope for the MVP.
