import mysql.connector
from mysql.connector import pooling
from config import Config

# A small connection pool is friendlier than opening a fresh TCP
# connection on every request, and it survives fine inside a container.
_pool = pooling.MySQLConnectionPool(
    pool_name="lms_pool",
    pool_size=5,
    host=Config.DB_HOST,
    port=Config.DB_PORT,
    user=Config.DB_USER,
    password=Config.DB_PASSWORD,
    database=Config.DB_NAME,
    charset="utf8mb4",
    collation="utf8mb4_unicode_ci"
)


def get_connection():
    """Grab a connection from the pool. Caller is responsible for closing it
    (use it in a `with` block or call .close() when done — closing returns
    it to the pool, it doesn't actually disconnect)."""
    return _pool.get_connection()


def query_one(sql, params=None):
    """Run a SELECT and return a single row as a dict, or None."""
    conn = get_connection()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(sql, params or ())
        row = cur.fetchone()
        cur.close()
        return row
    finally:
        conn.close()


def query_all(sql, params=None):
    """Run a SELECT and return all rows as a list of dicts."""
    conn = get_connection()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(sql, params or ())
        rows = cur.fetchall()
        cur.close()
        return rows
    finally:
        conn.close()


def execute(sql, params=None):
    """Run an INSERT/UPDATE/DELETE. Returns (lastrowid, rowcount)."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql, params or ())
        conn.commit()
        last_id, row_count = cur.lastrowid, cur.rowcount
        cur.close()
        return last_id, row_count
    finally:
        conn.close()
