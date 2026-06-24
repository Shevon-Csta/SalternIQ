"""
SalternIQ — Model Training Script
Generates synthetic Sri Lankan saltern data and trains:
  - viability_model.pkl  : RandomForestClassifier (viable / not viable)
  - yield_model.pkl      : GradientBoostingRegressor (estimated yield in tons)

Run with:  python train_models.py
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, r2_score
import joblib
import os

np.random.seed(42)
N = 2000

# ── Synthetic feature generation ──────────────────────────────────────────────
# Modelled on Sri Lanka's northwest/southeast coastal saltern conditions.
# Key regions: Hambantota, Puttalam, Elephant Pass, Kalpitiya

year  = np.random.randint(2019, 2026, N)
month = np.random.randint(1, 13, N)

# Coastal location — most viable sites are < 10 km from coast
distance_to_coast_km = np.random.exponential(scale=5, size=N).clip(0.5, 40)

# Land area: small to medium farms
land_area_acres = np.random.lognormal(mean=1.5, sigma=0.8, size=N).clip(0.5, 100)

# Soil permeability: 1–10 scale; higher = better drainage for brine evaporation
soil_permeability = np.random.uniform(1, 10, N)

# Sri Lanka climate: hot/dry season May–Sep (dry zone), wet season Oct–Jan
# Temperature: 28–35°C coastal
avg_temperature_C = np.random.normal(31, 2.5, N).clip(24, 38)

# Rainfall: drier months better for salt production
rainfall_mm = np.abs(np.random.normal(60, 45, N)).clip(0, 300)

# Humidity: 60–85% typical
humidity_percent = np.random.normal(70, 8, N).clip(40, 95)

# Solar radiation: 4–7 kWh/m²/day
solar_radiation_kwh_m2 = np.random.normal(5.5, 0.8, N).clip(3, 8)

# Wind speed: 10–25 km/h
wind_speed_kmh = np.random.normal(16, 4, N).clip(3, 35)

# Brine salinity: 240–320 g/L
brine_salinity_gL = np.random.normal(280, 20, N).clip(200, 340)

# Derived evaporation index (mirrors build_input_df in main.py)
evaporation_index = (
    0.45 * avg_temperature_C +
    0.35 * solar_radiation_kwh_m2 +
    0.25 * wind_speed_kmh -
    0.5  * humidity_percent / 10 -
    0.4  * rainfall_mm / 30
)

# ── Viability labelling ────────────────────────────────────────────────────────
# A site is viable when conditions favour high evaporation and brine concentration.
# Rules grounded in Sri Lankan saltern literature:
#   - Must be close to coast (< 15 km)
#   - Good soil drainage (permeability >= 5)
#   - High evaporation (> 16)
#   - Moderate rainfall (< 120 mm)
#   - Adequate brine salinity (> 260 g/L)
#   - Temperature >= 29°C

viability_score = (
    (distance_to_coast_km < 15).astype(float) * 2.0 +
    (soil_permeability >= 5).astype(float)          * 1.5 +
    (evaporation_index > 16).astype(float)          * 2.0 +
    (rainfall_mm < 120).astype(float)               * 1.5 +
    (brine_salinity_gL > 260).astype(float)         * 1.5 +
    (avg_temperature_C >= 29).astype(float)         * 1.0
)

# Threshold score for viability; add noise so boundaries are fuzzy
noise = np.random.normal(0, 0.5, N)
viable = ((viability_score + noise) >= 5.5).astype(int)

# ── Yield labelling (tons/season) ─────────────────────────────────────────────
# Only meaningful for viable sites; correlated with land area and evaporation
base_yield = (
    land_area_acres * 0.8 +
    evaporation_index * 0.3 +
    brine_salinity_gL * 0.02 -
    rainfall_mm * 0.05 -
    distance_to_coast_km * 0.1
)
yield_tons = np.where(
    viable == 1,
    np.clip(base_yield + np.random.normal(0, 2, N), 1, 150),
    np.random.uniform(0.1, 2.0, N)   # near-zero for non-viable
)

# ── Build DataFrame ────────────────────────────────────────────────────────────
df = pd.DataFrame({
    "year":                   year,
    "month":                  month,
    "land_area_acres":        land_area_acres,
    "distance_to_coast_km":   distance_to_coast_km,
    "soil_permeability":      soil_permeability,
    "avg_temperature_C":      avg_temperature_C,
    "rainfall_mm":            rainfall_mm,
    "humidity_percent":       humidity_percent,
    "solar_radiation_kwh_m2": solar_radiation_kwh_m2,
    "wind_speed_kmh":         wind_speed_kmh,
    "evaporation_index":      evaporation_index,
    "brine_salinity_gL":      brine_salinity_gL,
    "viable":                 viable,
    "yield_tons":             yield_tons,
})

FEATURES = [
    "year", "month", "land_area_acres", "distance_to_coast_km",
    "soil_permeability", "avg_temperature_C", "rainfall_mm",
    "humidity_percent", "solar_radiation_kwh_m2", "wind_speed_kmh",
    "evaporation_index", "brine_salinity_gL",
]

X = df[FEATURES]
y_cls = df["viable"]
y_reg = df["yield_tons"]

X_train, X_test, yc_train, yc_test = train_test_split(X, y_cls, test_size=0.2, random_state=42)
_, _, yr_train, yr_test             = train_test_split(X, y_reg, test_size=0.2, random_state=42)

# ── Train classifier ───────────────────────────────────────────────────────────
clf = RandomForestClassifier(
    n_estimators=200,
    max_depth=12,
    min_samples_split=4,
    random_state=42,
    n_jobs=-1,
)
clf.fit(X_train, yc_train)
acc = accuracy_score(yc_test, clf.predict(X_test))
print(f"Viability classifier accuracy: {acc:.3f}")

# ── Train regressor ────────────────────────────────────────────────────────────
reg = GradientBoostingRegressor(
    n_estimators=200,
    max_depth=5,
    learning_rate=0.08,
    random_state=42,
)
reg.fit(X_train, yr_train)
r2 = r2_score(yr_test, reg.predict(X_test))
print(f"Yield regressor R²:            {r2:.3f}")

# ── Save models ────────────────────────────────────────────────────────────────
out_dir = os.path.dirname(os.path.abspath(__file__))
clf_path = os.path.join(out_dir, "viability_model.pkl")
reg_path = os.path.join(out_dir, "yield_model.pkl")

joblib.dump(clf, clf_path)
joblib.dump(reg, reg_path)

print(f"\nSaved  viability_model.pkl  →  {clf_path}")
print(f"Saved  yield_model.pkl      →  {reg_path}")
print("\nDone. Restart the backend server.")
