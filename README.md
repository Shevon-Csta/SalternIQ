# SalternIQ — Machine Learning Based Land Suitability Assessment for Salterns

**Author:** W.S.S. Costa (IIT No: 20230867 · UoW No: W2084398)  
**Supervisor:** Mr. Chathura Wickramasinghe  
**Programme:** BEng (Hons) Software Engineering — IIT Colombo / University of Westminster  
**Live deployment:** https://saltern-iq.vercel.app

---

## Project Overview

SalternIQ is a full-stack web application that predicts whether a coastal land site is suitable for salt farming, and estimates the monthly salt yield if viable. It uses a two-stage machine learning pipeline:

- **Stage 1 — RandomForestClassifier**: predicts binary viability (viable / not viable) from 12 environmental parameters
- **Stage 2 — GradientBoostingRegressor**: estimates monthly salt yield in metric tons for viable sites

The system supports manual parameter entry and a geo-prediction mode that retrieves historical climate data automatically from the Open-Meteo Archive API based on GPS coordinates.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 19, Vite 5, React Router v7, Leaflet.js |
| Backend | FastAPI (Python 3.11), SQLite, bcrypt, Resend API |
| ML | scikit-learn 1.5.2 (RandomForestClassifier + GradientBoostingRegressor) |
| Deployment | Vercel (frontend) + Render (backend + persistent disk) |

---

## Running Locally

### Prerequisites

- **Python 3.11** — https://www.python.org/downloads/release/python-3119/
- **Node.js 18+** — https://nodejs.org/

### Option A — Automatic (Windows)

Double-click `start.bat` in the project root. It opens two terminal windows — one for the backend, one for the frontend — and prints the local URLs when ready.

Then open **http://localhost:5173** in your browser.

### Option B — Manual

**Terminal 1 — Backend:**
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

**Terminal 2 — Frontend:**
```bash
cd frontend_web
npm install
npm run dev
```

Then open **http://localhost:5173** in your browser.

---

## Project Structure

```
saltern_app/
├── backend/
│   ├── main.py              # FastAPI application — all routes and business logic
│   ├── train_models.py      # Synthetic dataset generation and model training script
│   ├── requirements.txt     # Python dependencies
│   ├── viability_model.pkl  # Trained RandomForestClassifier
│   └── yield_model.pkl      # Trained GradientBoostingRegressor
├── frontend_web/
│   ├── src/
│   │   ├── pages/           # React page components (Dashboard, Predict, GeoPredict, etc.)
│   │   ├── components/      # Shared components (Layout, sidebar, verification banner)
│   │   └── api.js           # Centralised API client
│   ├── vite.config.js       # Vite dev server with proxy to backend
│   └── vercel.json          # SPA rewrite rule for Vercel deployment
├── render.yaml              # Render deployment configuration
├── start.bat                # One-click local startup script (Windows)
└── .gitignore
```

---

## Notes for Local Testing

**Email verification:** `config.py` is excluded from the repository (it contains credentials). Without it, email delivery is disabled and verification tokens are printed directly to the backend terminal output. To verify an account locally:

1. Register an account
2. Look in the **backend terminal** for a line like:  
   `[EMAIL DISABLED] Verification link for ...: http://localhost:5173/verify?token=...`
3. Copy that URL into your browser and click **Confirm email address**

**Database:** A fresh SQLite database (`salterniq.db`) is created automatically on first startup — no setup required.

**ML models:** Both `.pkl` files are included in the repository. If you need to retrain them (e.g. after a scikit-learn version change), run:
```bash
cd backend
python train_models.py
```

**Admin panel:** The admin panel is accessible at `/app/admin`. Access is granted to the account whose email matches the `ADMIN_EMAIL` environment variable (or the value in `config.py` if running locally with credentials).

---

## Retraining the Models

The synthetic dataset and training pipeline are fully contained in `backend/train_models.py`. Running it regenerates both `.pkl` files in place. The dataset covers 2,000 synthetic site-month records across three Sri Lankan coastal regions (Puttalam, Hambantota, Mannar) with 12 environmental features and domain-validated viability thresholds.

---

## Live Application

The deployed application is available at **https://saltern-iq.vercel.app** and requires no local setup to use. Registration and email verification are fully functional in the live environment.
