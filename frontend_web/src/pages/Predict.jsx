import { useState } from 'react'
import { CheckCircle, XCircle, Lightbulb, Search, Leaf } from 'lucide-react'
import { api } from '../api'

const now = new Date()

const defaultForm = {
  year: now.getFullYear(),
  month: now.getMonth() + 1,
  land_area: 5,
  distance_to_coast: 3,
  soil_permeability: 5,
  temperature: 31,
  rainfall: 60,
  humidity: 68,
  solar_radiation: 5.5,
  wind_speed: 14,
  brine_salinity: 280,
  notes: ''
}

const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

function Field({ label, hint, children }) {
  return (
    <div className="form-group">
      <label>
        {label}{hint && <span className="form-optional">{hint}</span>}
      </label>
      {children}
    </div>
  )
}

export default function Predict() {
  const [form, setForm] = useState(defaultForm)
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))
  const num = (k, v) => set(k, parseFloat(v) || 0)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    setResult(null)
    try {
      const res = await api.predict(form)
      setResult(res)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const isViable = result?.viable === 1

  return (
    <div className="page-inner">
      <div className="page-header">
        <div>
          <h2>Manual Assessment</h2>
          <p>Enter environmental parameters to assess land suitability for a saltern</p>
        </div>
      </div>

      <div className="predict-grid">
        {/* Form */}
        <div className="card">
          <div className="card-header"><span>Site Parameters</span></div>
          <div className="card-body">
            <form onSubmit={handleSubmit}>
              <p className="section-label">Time Period</p>
              <div className="form-row">
                <Field label="Year">
                  <input type="number" value={form.year} onChange={e => num('year', e.target.value)} min="2020" max="2030" required />
                </Field>
                <Field label="Month">
                  <select value={form.month} onChange={e => num('month', e.target.value)}>
                    {MONTHS.map((m, i) => <option key={i} value={i + 1}>{m}</option>)}
                  </select>
                </Field>
              </div>

              <p className="section-label">Land Properties</p>
              <div className="form-row">
                <Field label="Land Area" hint="acres">
                  <input type="number" step="0.1" value={form.land_area} onChange={e => num('land_area', e.target.value)} required />
                </Field>
                <Field label="Distance to Coast" hint="km">
                  <input type="number" step="0.1" value={form.distance_to_coast} onChange={e => num('distance_to_coast', e.target.value)} required />
                </Field>
              </div>
              <Field label="Soil Permeability" hint="1 = very low · 10 = very high">
                <input type="range" min="1" max="10" step="0.5" value={form.soil_permeability}
                  onChange={e => num('soil_permeability', e.target.value)} />
                <div className="range-value">{form.soil_permeability}</div>
              </Field>

              <p className="section-label">Climate Data</p>
              <div className="form-row">
                <Field label="Avg Temperature" hint="°C">
                  <input type="number" step="0.1" value={form.temperature} onChange={e => num('temperature', e.target.value)} required />
                </Field>
                <Field label="Rainfall" hint="mm/month">
                  <input type="number" step="0.1" value={form.rainfall} onChange={e => num('rainfall', e.target.value)} required />
                </Field>
              </div>
              <div className="form-row">
                <Field label="Humidity" hint="%">
                  <input type="number" step="1" value={form.humidity} onChange={e => num('humidity', e.target.value)} min="0" max="100" required />
                </Field>
                <Field label="Solar Radiation" hint="kWh/m²">
                  <input type="number" step="0.1" value={form.solar_radiation} onChange={e => num('solar_radiation', e.target.value)} required />
                </Field>
              </div>
              <Field label="Wind Speed" hint="km/h">
                <input type="number" step="0.5" value={form.wind_speed} onChange={e => num('wind_speed', e.target.value)} required />
              </Field>

              <p className="section-label">Water Quality</p>
              <Field label="Brine Salinity" hint="g/L — typical range 250–320">
                <input type="number" step="1" value={form.brine_salinity} onChange={e => num('brine_salinity', e.target.value)} required />
              </Field>

              <p className="section-label">Notes</p>
              <Field label="Site Notes" hint="optional">
                <input type="text" value={form.notes} onChange={e => set('notes', e.target.value)} placeholder="e.g. Site near Puttalam lagoon" />
              </Field>

              {error && <div className="error-msg">{error}</div>}

              <button className="btn btn-primary" type="submit" disabled={loading} style={{ marginTop: 8 }}>
                {loading
                  ? <><span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} /> Analysing…</>
                  : <><Search size={15} /> Run Assessment</>
                }
              </button>
            </form>
          </div>
        </div>

        {/* Result panel */}
        <div>
          {!result && !loading && (
            <div className="card">
              <div className="card-body">
                <div className="empty-state" style={{ padding: '48px 20px' }}>
                  <Leaf size={36} strokeWidth={1.2} style={{ color: 'var(--text-faint)', marginBottom: 12 }} />
                  <p>Fill in the parameters and run the assessment to see results here.</p>
                </div>
              </div>
            </div>
          )}

          {loading && (
            <div className="card">
              <div className="card-body">
                <div className="loading" style={{ padding: '60px 20px' }}>
                  <div className="spinner" /> Running ML models…
                </div>
              </div>
            </div>
          )}

          {result && (
            <>
              <div className={`result-card ${isViable ? 'viable' : 'not-viable'}`}>
                <div className="result-verdict">
                  {isViable
                    ? <CheckCircle size={20} strokeWidth={2} />
                    : <XCircle size={20} strokeWidth={2} />
                  }
                  <span>{isViable ? 'Viable' : 'Not Viable'}</span>
                </div>
                <div className="result-percent">{result.viability_probability}%</div>
                <div className="result-label">viability probability</div>
                <div className="result-details">
                  <div className="result-detail-item">
                    <div className="label">Est. Yield</div>
                    <div className="value">{result.estimated_yield_tons > 0 ? `${result.estimated_yield_tons} t` : '—'}</div>
                  </div>
                  <div className="result-detail-item">
                    <div className="label">Evaporation Index</div>
                    <div className="value">{result.evaporation_index}</div>
                  </div>
                </div>
              </div>

              {result.recommendation?.length > 0 && (
                <div className="card" style={{ marginTop: 16 }}>
                  <div className="card-header">
                    <Lightbulb size={15} style={{ color: 'var(--teal)' }} />
                    <span>Recommendations</span>
                  </div>
                  <div className="card-body">
                    <ul className="tips-list">
                      {result.recommendation.map((tip, i) => (
                        <li key={i} className="tip-item">{tip}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}
