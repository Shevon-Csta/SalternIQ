"""
SalternIQ — FastAPI Backend
Author: Shevon Costa (Final Year Project)

Endpoints:
  POST /auth/register
  POST /auth/login
  POST /auth/logout
  GET  /auth/me
  GET  /auth/verify/{token}
  POST /auth/resend-verification
  POST /predict
  POST /predict/geo
  GET  /history
  GET  /dashboard/stats
"""

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional
import numpy as np
import pandas as pd
import joblib
import requests
import sqlite3
import bcrypt
import secrets
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
import os

# ── App ────────────────────────────────────────────────────────
app = FastAPI(title="SalternIQ API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

# ── Config ─────────────────────────────────────────────────────
# Locally: reads from config.py (gitignored, contains real credentials).
# In production (Render): config.py doesn't exist → reads from environment variables.
try:
    from config import SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, APP_URL
except ImportError:
    SMTP_HOST     = os.environ.get("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT     = int(os.environ.get("SMTP_PORT", "587"))
    SMTP_USER     = os.environ.get("SMTP_USER", "")
    SMTP_PASSWORD = os.environ.get("SMTP_PASSWORD", "")
    APP_URL       = os.environ.get("APP_URL", "http://localhost:5173")

# Resend HTTP API — used when RESEND_API_KEY is set (SMTP is the fallback)
# Render blocks outbound SMTP, so Resend is the primary delivery method in production
try:
    from config import RESEND_API_KEY
except ImportError:
    RESEND_API_KEY = os.environ.get("RESEND_API_KEY", "")

EMAIL_ENABLED = bool(RESEND_API_KEY or SMTP_USER)

try:
    from config import ADMIN_EMAIL
except ImportError:
    ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "")

MAX_FAILED_ATTEMPTS = 5
LOCKOUT_MINUTES     = 15

# ── Database ───────────────────────────────────────────────────
DB_PATH = os.environ.get("DB_PATH", os.path.join(os.path.dirname(os.path.abspath(__file__)), "salterniq.db"))

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    c.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            name            TEXT    NOT NULL,
            email           TEXT    UNIQUE NOT NULL,
            password_hash   TEXT    NOT NULL,
            farm_name       TEXT,
            location        TEXT,
            verified        INTEGER DEFAULT 0,
            failed_attempts INTEGER DEFAULT 0,
            locked_until    TEXT,
            created_at      TEXT    DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Safe column additions for schema migrations; silently skips if column already exists
    for col, defn in [
        ("verified",        "INTEGER DEFAULT 0"),
        ("failed_attempts", "INTEGER DEFAULT 0"),
        ("locked_until",    "TEXT"),
    ]:
        try:
            c.execute(f"ALTER TABLE users ADD COLUMN {col} {defn}")
        except Exception:
            pass

    c.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            token      TEXT    PRIMARY KEY,
            user_id    INTEGER NOT NULL,
            expires_at TEXT    NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS verification_tokens (
            token      TEXT    PRIMARY KEY,
            user_id    INTEGER NOT NULL,
            expires_at TEXT    NOT NULL,
            used       INTEGER DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS predictions (
            id                   INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id              INTEGER NOT NULL,
            latitude             REAL,
            longitude            REAL,
            land_area            REAL,
            distance_to_coast    REAL,
            soil_permeability    REAL,
            temperature          REAL,
            rainfall             REAL,
            humidity             REAL,
            solar_radiation      REAL,
            wind_speed           REAL,
            evaporation_index    REAL,
            brine_salinity       REAL,
            viable               INTEGER,
            viability_probability REAL,
            estimated_yield      REAL,
            notes                TEXT,
            created_at           TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)

    conn.commit()
    conn.close()

init_db()

# ── Load Models ────────────────────────────────────────────────
MODEL_DIR = os.path.dirname(os.path.abspath(__file__))

try:
    clf = joblib.load(os.path.join(MODEL_DIR, "viability_model.pkl"))
    reg = joblib.load(os.path.join(MODEL_DIR, "yield_model.pkl"))
    MODELS_LOADED = True
    print("✔  Models loaded")
except Exception as e:
    MODELS_LOADED = False
    print(f"⚠  Models not found: {e}")

# ── Security helpers ───────────────────────────────────────────
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(password: str, hashed: str) -> bool:
    """Supports both bcrypt (new) and SHA-256 (legacy) hashes."""
    if hashed.startswith('$2b$') or hashed.startswith('$2a$'):
        return bcrypt.checkpw(password.encode(), hashed.encode())
    # Legacy SHA-256 — compare and let login re-hash automatically
    import hashlib
    return hashlib.sha256(password.encode()).hexdigest() == hashed

def is_legacy_hash(hashed: str) -> bool:
    return not (hashed.startswith('$2b$') or hashed.startswith('$2a$'))

def generate_token() -> str:
    return secrets.token_urlsafe(32)

# ── Email ──────────────────────────────────────────────────────
def send_verification_email(to_email: str, name: str, token: str):
    link = f"{APP_URL}/verify?token={token}"

    if not EMAIL_ENABLED:
        print(f"\n📧  [EMAIL DISABLED] Verification link for {to_email}:\n    {link}\n", flush=True)
        return

    html = f"""
    <div style="font-family:sans-serif;max-width:480px;margin:auto;padding:32px">
      <h2 style="color:#0d8a8a">Verify your SalternIQ account</h2>
      <p>Hi {name},</p>
      <p>Click the button below to verify your email address and activate your account.</p>
      <a href="{link}"
         style="display:inline-block;margin:20px 0;padding:12px 28px;background:#0d8a8a;
                color:#fff;border-radius:8px;text-decoration:none;font-weight:600">
        Verify Email
      </a>
      <p style="color:#64748b;font-size:13px">
        This link expires in 24 hours.<br>
        If you didn't create a SalternIQ account, ignore this email.
      </p>
    </div>
    """

    # ── Resend HTTP API ────────────────────────────────────────────
    if RESEND_API_KEY:
        try:
            resp = requests.post(
                "https://api.resend.com/emails",
                headers={
                    "Authorization": f"Bearer {RESEND_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "from": "SalternIQ <onboarding@resend.dev>",
                    "to": [to_email],
                    "subject": "Verify your SalternIQ account",
                    "html": html,
                },
                timeout=10,
            )
            if resp.ok:
                print(f"✔  Verification email sent to {to_email}", flush=True)
            else:
                print(f"⚠  Resend error: {resp.status_code} {resp.text}", flush=True)
                print(f"   Verification link: {link}", flush=True)
        except Exception as e:
            print(f"⚠  Resend request failed: {e}", flush=True)
            print(f"   Verification link: {link}", flush=True)
        return

    # ── Fallback: SMTP ──────────────────────────────────────────
    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Verify your SalternIQ account"
    msg["From"]    = f"SalternIQ <{SMTP_USER}>"
    msg["To"]      = to_email
    msg.attach(MIMEText(html, "html"))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.ehlo()
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.sendmail(SMTP_USER, to_email, msg.as_string())
        print(f"✔  Verification email sent to {to_email}", flush=True)
    except Exception as e:
        print(f"⚠  Email failed: {e}", flush=True)
        print(f"   Verification link: {link}", flush=True)

# ── DB helpers ─────────────────────────────────────────────────
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    conn  = get_db()
    c     = conn.cursor()
    c.execute("""
        SELECT u.* FROM users u
        JOIN sessions s ON u.id = s.user_id
        WHERE s.token = ? AND s.expires_at > ?
    """, (token, datetime.utcnow().isoformat()))
    user = c.fetchone()
    conn.close()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    return dict(user)

def build_input_df(data):
    evaporation = (
        0.45 * data.temperature +
        0.35 * data.solar_radiation +
        0.25 * data.wind_speed -
        0.5  * data.humidity / 10 -
        0.4  * data.rainfall / 30
    )
    df = pd.DataFrame({
        "year":                   [data.year],
        "month":                  [data.month],
        "land_area_acres":        [data.land_area],
        "distance_to_coast_km":   [data.distance_to_coast],
        "soil_permeability":      [data.soil_permeability],
        "avg_temperature_C":      [data.temperature],
        "rainfall_mm":            [data.rainfall],
        "humidity_percent":       [data.humidity],
        "solar_radiation_kwh_m2": [data.solar_radiation],
        "wind_speed_kmh":         [data.wind_speed],
        "evaporation_index":      [evaporation],
        "brine_salinity_gL":      [data.brine_salinity],
    })
    return df, evaporation

# ── Schemas ────────────────────────────────────────────────────
class RegisterRequest(BaseModel):
    name:      str
    email:     str
    password:  str
    farm_name: Optional[str] = None
    location:  Optional[str] = None

class LoginRequest(BaseModel):
    email:    str
    password: str

class ManualPredictRequest(BaseModel):
    year:              int   = 2024
    month:             int   = 6
    land_area:         float
    distance_to_coast: float
    soil_permeability: float
    temperature:       float
    rainfall:          float
    humidity:          float
    solar_radiation:   float
    wind_speed:        float
    brine_salinity:    float
    notes:             Optional[str] = None

class GeoPredictRequest(BaseModel):
    latitude:          float
    longitude:         float
    land_area:         float
    soil_permeability: float
    brine_salinity:    float
    notes:             Optional[str] = None

class ResendVerificationRequest(BaseModel):
    email: str

# ── Auth routes ────────────────────────────────────────────────
@app.post("/auth/register")
def register(req: RegisterRequest):
    if len(req.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    conn = get_db()
    c    = conn.cursor()
    c.execute("SELECT id FROM users WHERE email = ?", (req.email,))
    if c.fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail="Email already registered")

    pw_hash = hash_password(req.password)
    c.execute("""
        INSERT INTO users (name, email, password_hash, farm_name, location, verified)
        VALUES (?, ?, ?, ?, ?, 0)
    """, (req.name, req.email, pw_hash, req.farm_name, req.location))
    user_id = c.lastrowid

    # Create session
    token   = generate_token()
    expires = (datetime.utcnow() + timedelta(days=30)).isoformat()
    c.execute("INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)",
              (token, user_id, expires))

    # Create verification token
    v_token   = generate_token()
    v_expires = (datetime.utcnow() + timedelta(hours=24)).isoformat()
    c.execute("""
        INSERT INTO verification_tokens (token, user_id, expires_at)
        VALUES (?, ?, ?)
    """, (v_token, user_id, v_expires))

    conn.commit()
    conn.close()

    send_verification_email(req.email, req.name, v_token)

    return {
        "token":    token,
        "verified": False,
        "user": {
            "id":        user_id,
            "name":      req.name,
            "email":     req.email,
            "farm_name": req.farm_name,
            "location":  req.location,
            "verified":  False,
        }
    }

@app.post("/auth/login")
def login(req: LoginRequest):
    conn = get_db()
    c    = conn.cursor()
    c.execute("SELECT * FROM users WHERE email = ?", (req.email,))
    user = c.fetchone()

    if not user:
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid email or password")

    user = dict(user)

    # Check lockout
    if user.get("locked_until"):
        locked_until = datetime.fromisoformat(user["locked_until"])
        if datetime.utcnow() < locked_until:
            remaining = int((locked_until - datetime.utcnow()).total_seconds() / 60) + 1
            conn.close()
            raise HTTPException(
                status_code=429,
                detail=f"Account locked due to too many failed attempts. Try again in {remaining} minute(s)."
            )
        else:
            # Lockout expired — reset counters
            conn.execute("UPDATE users SET failed_attempts=0, locked_until=NULL WHERE id=?", (user["id"],))
            conn.commit()

    # Verify password
    if not verify_password(req.password, user["password_hash"]):
        attempts = (user.get("failed_attempts") or 0) + 1
        if attempts >= MAX_FAILED_ATTEMPTS:
            lock_until = (datetime.utcnow() + timedelta(minutes=LOCKOUT_MINUTES)).isoformat()
            conn.execute(
                "UPDATE users SET failed_attempts=?, locked_until=? WHERE id=?",
                (attempts, lock_until, user["id"])
            )
            conn.commit()
            conn.close()
            raise HTTPException(
                status_code=429,
                detail=f"Too many failed attempts. Account locked for {LOCKOUT_MINUTES} minutes."
            )
        conn.execute("UPDATE users SET failed_attempts=? WHERE id=?", (attempts, user["id"]))
        conn.commit()
        conn.close()
        remaining = MAX_FAILED_ATTEMPTS - attempts
        raise HTTPException(
            status_code=401,
            detail=f"Invalid email or password. {remaining} attempt(s) remaining before lockout."
        )

    # Success — reset failed attempts, migrate legacy hash to bcrypt if needed
    token   = generate_token()
    expires = (datetime.utcnow() + timedelta(days=30)).isoformat()
    if is_legacy_hash(user["password_hash"]):
        new_hash = hash_password(req.password)
        conn.execute("UPDATE users SET password_hash=? WHERE id=?", (new_hash, user["id"]))
        print(f"✔  Migrated {user['email']} from SHA-256 to bcrypt")
    conn.execute("UPDATE users SET failed_attempts=0, locked_until=NULL WHERE id=?", (user["id"],))
    conn.execute("INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)",
                 (token, user["id"], expires))
    conn.commit()
    conn.close()

    return {
        "token":    token,
        "verified": bool(user.get("verified")),
        "user": {
            "id":        user["id"],
            "name":      user["name"],
            "email":     user["email"],
            "farm_name": user["farm_name"],
            "location":  user["location"],
            "verified":  bool(user.get("verified")),
        }
    }

@app.get("/auth/me")
def get_me(current_user=Depends(get_current_user)):
    return {
        "id":         current_user["id"],
        "name":       current_user["name"],
        "email":      current_user["email"],
        "farm_name":  current_user["farm_name"],
        "location":   current_user["location"],
        "verified":   bool(current_user.get("verified")),
        "is_admin":   current_user["email"] == ADMIN_EMAIL,
        "created_at": current_user["created_at"],
    }

@app.post("/auth/logout")
def logout(credentials: HTTPAuthorizationCredentials = Depends(security)):
    conn = get_db()
    conn.execute("DELETE FROM sessions WHERE token = ?", (credentials.credentials,))
    conn.commit()
    conn.close()
    return {"message": "Logged out"}

@app.get("/auth/verify/{token}")
def verify_email(token: str):
    conn = get_db()
    c    = conn.cursor()

    c.execute("SELECT * FROM verification_tokens WHERE token = ?", (token,))
    row = c.fetchone()

    if not row:
        conn.close()
        raise HTTPException(status_code=400, detail="Verification link is invalid or has expired")

    row = dict(row)

    # If already used, check whether user is actually verified — if so, treat as success.
    # This handles React StrictMode calling the endpoint twice in development.
    if row["used"]:
        c.execute("SELECT verified FROM users WHERE id=?", (row["user_id"],))
        user = c.fetchone()
        conn.close()
        if user and user["verified"]:
            return {"message": "Email verified successfully"}
        raise HTTPException(status_code=400, detail="Verification link has already been used")

    if row["expires_at"] <= datetime.utcnow().isoformat():
        conn.close()
        raise HTTPException(status_code=400, detail="Verification link has expired")

    conn.execute("UPDATE users SET verified=1 WHERE id=?", (row["user_id"],))
    conn.execute("UPDATE verification_tokens SET used=1 WHERE token=?", (token,))
    conn.commit()
    conn.close()
    return {"message": "Email verified successfully"}

@app.post("/auth/resend-verification")
def resend_verification(req: ResendVerificationRequest):
    conn = get_db()
    c    = conn.cursor()
    c.execute("SELECT * FROM users WHERE email=?", (req.email,))
    user = c.fetchone()

    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    user = dict(user)
    if user.get("verified"):
        conn.close()
        return {"message": "Email already verified"}

    v_token   = generate_token()
    v_expires = (datetime.utcnow() + timedelta(hours=24)).isoformat()
    conn.execute("""
        INSERT INTO verification_tokens (token, user_id, expires_at)
        VALUES (?, ?, ?)
    """, (v_token, user["id"], v_expires))
    conn.commit()
    conn.close()

    send_verification_email(user["email"], user["name"], v_token)
    return {"message": "Verification email sent"}

# ── Prediction routes ──────────────────────────────────────────
@app.post("/predict")
def predict_manual(req: ManualPredictRequest, current_user=Depends(get_current_user)):
    if not MODELS_LOADED:
        raise HTTPException(status_code=503, detail="ML models not loaded")

    input_df, evaporation = build_input_df(req)
    viable_prob    = float(clf.predict_proba(input_df)[0][1])
    viable         = int(clf.predict(input_df)[0])
    estimated_yield = float(reg.predict(input_df)[0]) if viable == 1 else 0.0

    conn = get_db()
    conn.execute("""
        INSERT INTO predictions (user_id, land_area, distance_to_coast,
        soil_permeability, temperature, rainfall, humidity, solar_radiation,
        wind_speed, evaporation_index, brine_salinity, viable,
        viability_probability, estimated_yield, notes)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (current_user["id"], req.land_area, req.distance_to_coast,
          req.soil_permeability, req.temperature, req.rainfall, req.humidity,
          req.solar_radiation, req.wind_speed, evaporation, req.brine_salinity,
          viable, viable_prob, estimated_yield, req.notes))
    conn.commit()
    conn.close()

    return {
        "viable":                 viable,
        "viability_probability":  round(viable_prob * 100, 2),
        "estimated_yield_tons":   round(estimated_yield, 2),
        "evaporation_index":      round(evaporation, 3),
        "recommendation":         _get_recommendation(viable, viable_prob, req)
    }

@app.post("/predict/geo")
def predict_geo(req: GeoPredictRequest, current_user=Depends(get_current_user)):
    if not MODELS_LOADED:
        raise HTTPException(status_code=503, detail="ML models not loaded")

    if not (5.9 <= req.latitude <= 9.9 and 79.5 <= req.longitude <= 82.0):
        raise HTTPException(status_code=400, detail="Coordinates outside Sri Lanka boundary")

    try:
        url = (
            "https://archive-api.open-meteo.com/v1/archive?"
            f"latitude={req.latitude}&longitude={req.longitude}"
            "&start_date=2023-01-01&end_date=2023-12-31"
            "&daily=temperature_2m_mean,precipitation_sum,windspeed_10m_mean"
            "&timezone=auto"
        )
        response  = requests.get(url, timeout=10)
        data      = response.json()
        df_daily  = pd.DataFrame(data["daily"])
        df_daily["time"]  = pd.to_datetime(df_daily["time"])
        df_daily["month"] = df_daily["time"].dt.month
        df_monthly        = df_daily.groupby("month").mean(numeric_only=True)
        latest            = df_monthly.mean()

        temperature = float(latest["temperature_2m_mean"])
        rainfall    = float(latest["precipitation_sum"])
        wind_speed  = float(latest["windspeed_10m_mean"])
        humidity    = 70.0
        solar       = 5.5
        distance_to_coast = 5.0

    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Climate API error: {str(e)}")

    evaporation = (
        0.45 * temperature +
        0.35 * solar +
        0.25 * wind_speed -
        0.5  * humidity / 10 -
        0.4  * rainfall / 30
    )

    now = datetime.now()
    input_df = pd.DataFrame({
        "year":                   [now.year],
        "month":                  [now.month],
        "land_area_acres":        [req.land_area],
        "distance_to_coast_km":   [distance_to_coast],
        "soil_permeability":      [req.soil_permeability],
        "avg_temperature_C":      [temperature],
        "rainfall_mm":            [rainfall],
        "humidity_percent":       [humidity],
        "solar_radiation_kwh_m2": [solar],
        "wind_speed_kmh":         [wind_speed],
        "evaporation_index":      [evaporation],
        "brine_salinity_gL":      [req.brine_salinity],
    })

    viable_prob    = float(clf.predict_proba(input_df)[0][1])
    viable         = int(clf.predict(input_df)[0])
    estimated_yield = float(reg.predict(input_df)[0]) if viable == 1 else 0.0

    conn = get_db()
    conn.execute("""
        INSERT INTO predictions (user_id, latitude, longitude, land_area,
        distance_to_coast, soil_permeability, temperature, rainfall, humidity,
        solar_radiation, wind_speed, evaporation_index, brine_salinity, viable,
        viability_probability, estimated_yield, notes)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (current_user["id"], req.latitude, req.longitude, req.land_area,
          distance_to_coast, req.soil_permeability, temperature, rainfall,
          humidity, solar, wind_speed, evaporation, req.brine_salinity,
          viable, viable_prob, estimated_yield, req.notes))
    conn.commit()
    conn.close()

    return {
        "viable":                viable,
        "viability_probability": round(viable_prob * 100, 2),
        "estimated_yield_tons":  round(estimated_yield, 2),
        "climate": {
            "temperature":      round(temperature, 2),
            "rainfall":         round(rainfall, 2),
            "wind_speed":       round(wind_speed, 2),
            "evaporation_index": round(evaporation, 3),
            "humidity":         humidity,
            "solar_radiation":  solar,
        },
        "recommendation": _get_recommendation_geo(viable, viable_prob, temperature, rainfall, evaporation)
    }

# ── History & Dashboard ────────────────────────────────────────
@app.get("/history")
def get_history(current_user=Depends(get_current_user)):
    conn = get_db()
    c    = conn.cursor()
    c.execute("""
        SELECT * FROM predictions WHERE user_id = ?
        ORDER BY created_at DESC LIMIT 50
    """, (current_user["id"],))
    rows = [dict(r) for r in c.fetchall()]
    conn.close()
    return {"predictions": rows}

@app.get("/dashboard/stats")
def get_stats(current_user=Depends(get_current_user)):
    conn = get_db()
    c    = conn.cursor()

    c.execute("SELECT COUNT(*) as total FROM predictions WHERE user_id=?", (current_user["id"],))
    total = c.fetchone()["total"]

    c.execute("SELECT COUNT(*) as viable FROM predictions WHERE user_id=? AND viable=1", (current_user["id"],))
    viable_count = c.fetchone()["viable"]

    c.execute("SELECT AVG(estimated_yield) as avg FROM predictions WHERE user_id=? AND viable=1", (current_user["id"],))
    avg_yield = round(c.fetchone()["avg"] or 0, 2)

    c.execute("SELECT AVG(viability_probability) as avg FROM predictions WHERE user_id=?", (current_user["id"],))
    avg_prob = round((c.fetchone()["avg"] or 0) * 100, 1)

    conn.close()

    return {
        "total_predictions":        total,
        "viable_count":             viable_count,
        "not_viable_count":         total - viable_count,
        "viability_rate":           round((viable_count / total * 100) if total > 0 else 0, 1),
        "avg_estimated_yield":      avg_yield,
        "avg_viability_probability": avg_prob,
    }

# ── Admin routes ──────────────────────────────────────────────
def require_admin(current_user=Depends(get_current_user)):
    if current_user["email"] != ADMIN_EMAIL:
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

@app.get("/admin/users")
def admin_list_users(admin=Depends(require_admin)):
    conn = get_db()
    c    = conn.cursor()
    c.execute("""
        SELECT u.id, u.name, u.email, u.farm_name, u.location,
               u.verified, u.created_at,
               COUNT(p.id) as prediction_count
        FROM users u
        LEFT JOIN predictions p ON p.user_id = u.id
        GROUP BY u.id
        ORDER BY u.created_at DESC
    """)
    users = [dict(r) for r in c.fetchall()]
    conn.close()
    for u in users:
        u["is_admin"] = (u["email"] == ADMIN_EMAIL)
        u["verified"] = bool(u["verified"])
    return {"users": users}

@app.delete("/admin/users/{user_id}")
def admin_delete_user(user_id: int, admin=Depends(require_admin)):
    conn = get_db()
    c    = conn.cursor()
    c.execute("SELECT email FROM users WHERE id=?", (user_id,))
    target = c.fetchone()
    if not target:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
    if target["email"] == ADMIN_EMAIL:
        conn.close()
        raise HTTPException(status_code=400, detail="Cannot delete the admin account")
    # Delete sessions, predictions, verification tokens, then user
    conn.execute("DELETE FROM sessions WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM verification_tokens WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM predictions WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM users WHERE id=?", (user_id,))
    conn.commit()
    conn.close()
    return {"message": f"User {user_id} deleted"}

@app.get("/admin/stats")
def admin_stats(admin=Depends(require_admin)):
    conn = get_db()
    c    = conn.cursor()
    c.execute("SELECT COUNT(*) as total FROM users")
    total_users = c.fetchone()["total"]
    c.execute("SELECT COUNT(*) as verified FROM users WHERE verified=1")
    verified_users = c.fetchone()["verified"]
    c.execute("SELECT COUNT(*) as total FROM predictions")
    total_predictions = c.fetchone()["total"]
    c.execute("SELECT COUNT(*) as viable FROM predictions WHERE viable=1")
    viable = c.fetchone()["viable"]
    conn.close()
    return {
        "total_users":        total_users,
        "verified_users":     verified_users,
        "unverified_users":   total_users - verified_users,
        "total_predictions":  total_predictions,
        "viable_predictions": viable,
    }

# ── Recommendation engine ──────────────────────────────────────
def _get_recommendation(viable, prob, req):
    tips = []
    if viable == 1:
        if req.rainfall > 100:
            tips.append("High rainfall detected — consider drainage infrastructure.")
        if req.brine_salinity < 260:
            tips.append("Salinity is borderline — monitor brine concentration closely.")
        if req.distance_to_coast > 15:
            tips.append("Distance to coast is high — transport costs may increase.")
        if not tips:
            tips.append("Conditions are optimal. Proceed with establishment planning.")
    else:
        if req.rainfall >= 120:
            tips.append("Rainfall is too high for reliable salt production.")
        if req.brine_salinity <= 250:
            tips.append("Brine salinity is too low — source water needs concentration.")
        if req.distance_to_coast >= 20:
            tips.append("Location too far from coast for viable saltern operations.")
        evap = 0.45*req.temperature + 0.35*req.solar_radiation + 0.25*req.wind_speed - 0.5*req.humidity/10 - 0.4*req.rainfall/30
        if evap <= 10:
            tips.append("Evaporation index is too low — insufficient drying conditions.")
    return tips

def _get_recommendation_geo(viable, prob, temp, rain, evap):
    tips = []
    if viable == 1:
        if rain > 100:
            tips.append("Seasonal rainfall is significant — plan for dry season operations.")
        if evap < 12:
            tips.append("Evaporation is moderate — yields may be lower in wet months.")
        if not tips:
            tips.append("Location shows strong saltern potential based on climate data.")
    else:
        if rain >= 120:
            tips.append("Annual rainfall is too high at this location.")
        if evap <= 10:
            tips.append("Insufficient evaporation conditions at this location.")
        tips.append("Consider locations further north or along the western dry coast.")
    return tips
