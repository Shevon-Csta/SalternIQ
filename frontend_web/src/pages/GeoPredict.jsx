import { useState, useEffect, useRef } from 'react'
import { api } from '../api'

export default function GeoPredict() {
  const mapRef    = useRef(null)
  const leafletRef = useRef(null)   // L instance
  const markerRef = useRef(null)    // current pin
  const histMarkersRef = useRef([]) // history pins

  const [coords, setCoords] = useState(null)   // { lat, lng }
  const [form, setForm] = useState({
    land_area:         5,
    soil_permeability: 5,
    brine_salinity:    280,
    notes:             ''
  })
  const [result, setResult]   = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError]     = useState('')
  const [historyPins, setHistoryPins] = useState([])

  const num = (k, v) => setForm(f => ({ ...f, [k]: parseFloat(v) || 0 }))
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  // Load Leaflet and init map
  useEffect(() => {
    let map

    async function initMap() {
      // Dynamically import leaflet (avoids SSR issues)
      const L = (await import('leaflet')).default
      await import('leaflet/dist/leaflet.css')
      leafletRef.current = L

      // Fix default icon paths broken by Vite
      delete L.Icon.Default.prototype._getIconUrl
      L.Icon.Default.mergeOptions({
        iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
        iconUrl:       'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
        shadowUrl:     'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
      })

      if (mapRef.current && !mapRef.current._leaflet_id) {
        map = L.map(mapRef.current, { zoomControl: true }).setView([8.0, 80.7], 7)

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© <a href="https://www.openstreetmap.org/">OpenStreetMap</a>',
          maxZoom: 18,
        }).addTo(map)

        // Click handler
        map.on('click', (e) => {
          const { lat, lng } = e.latlng

          // Validate Sri Lanka bounds
          if (lat < 5.9 || lat > 9.9 || lng < 79.5 || lng > 82.0) {
            alert('Please click within Sri Lanka (lat 5.9–9.9, lng 79.5–82.0)')
            return
          }

          setCoords({ lat: parseFloat(lat.toFixed(5)), lng: parseFloat(lng.toFixed(5)) })
          setResult(null)
          setError('')

          if (markerRef.current) markerRef.current.remove()
          markerRef.current = L.marker([lat, lng])
            .addTo(map)
            .bindPopup(`${lat.toFixed(4)}°N, ${lng.toFixed(4)}°E — click "Run Assessment" to predict`)
            .openPopup()
        })

        mapRef.current._leafletMap = map
      }
    }

    initMap()

    return () => {
      if (mapRef.current?._leafletMap) {
        mapRef.current._leafletMap.remove()
        mapRef.current._leafletMap = null
      }
    }
  }, [])

  // Load history pins
  useEffect(() => {
    api.history().then(d => {
      const geo = d.predictions.filter(p => p.latitude && p.longitude)
      setHistoryPins(geo)
    }).catch(() => {})
  }, [result])

  // Draw history pins whenever they change
  useEffect(() => {
    const L   = leafletRef.current
    const map = mapRef.current?._leafletMap
    if (!L || !map) return

    histMarkersRef.current.forEach(m => m.remove())
    histMarkersRef.current = []

    historyPins.forEach(p => {
      const color  = p.viable ? '#16a34a' : '#dc2626'
      const icon = L.divIcon({
        className: '',
        html: `<div style="
          width:14px;height:14px;
          background:${color};
          border:2px solid #fff;
          border-radius:50%;
          box-shadow:0 1px 3px rgba(0,0,0,0.3)
        "></div>`,
        iconSize: [14, 14],
        iconAnchor: [7, 7],
      })
      const m = L.marker([p.latitude, p.longitude], { icon })
        .addTo(map)
        .bindPopup(`
          <b>${p.viable ? '✔ Viable' : '✘ Not Viable'}</b><br>
          Probability: ${(p.viability_probability * 100).toFixed(1)}%<br>
          ${p.viable ? `Yield: ${p.estimated_yield?.toFixed(1)} t<br>` : ''}
          ${new Date(p.created_at).toLocaleDateString()}
        `)
      histMarkersRef.current.push(m)
    })
  }, [historyPins])

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!coords) { setError('Click a location on the map first'); return }
    setError('')
    setLoading(true)
    setResult(null)
    try {
      const res = await api.geoPredict({
        latitude:          coords.lat,
        longitude:         coords.lng,
        land_area:         form.land_area,
        soil_permeability: form.soil_permeability,
        brine_salinity:    form.brine_salinity,
        notes:             form.notes,
      })
      setResult(res)

      // Update marker colour to result
      const L   = leafletRef.current
      const map = mapRef.current?._leafletMap
      if (L && map && markerRef.current) {
        markerRef.current.remove()
        const color = res.viable ? '#16a34a' : '#dc2626'
        const icon = L.divIcon({
          className: '',
          html: `<div style="
            width:18px;height:18px;
            background:${color};
            border:3px solid #fff;
            border-radius:50%;
            box-shadow:0 2px 6px rgba(0,0,0,0.4)
          "></div>`,
          iconSize: [18, 18],
          iconAnchor: [9, 9],
        })
        markerRef.current = L.marker([coords.lat, coords.lng], { icon })
          .addTo(map)
          .bindPopup(`
            <b>${res.viable ? '✔ Viable' : '✘ Not Viable'}</b><br>
            Probability: ${res.viability_probability}%
          `)
          .openPopup()
      }
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
          <h2>Geo Assessment</h2>
          <p>Click anywhere on the map to select a site — climate data is fetched automatically</p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 360px', gap: 24, alignItems: 'start' }}>

        {/* Map */}
        <div>
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <div style={{ background: 'var(--bg)', padding: '10px 16px', fontSize: 13, color: 'var(--text-muted)', borderBottom: '1px solid var(--border)' }}>
              Click anywhere in Sri Lanka to drop a pin &nbsp;·&nbsp;
              <span style={{ color: 'var(--success)' }}>● Viable</span> &nbsp;
              <span style={{ color: 'var(--danger)' }}>● Not viable</span> &nbsp;
              (past assessments shown)
            </div>
            <div ref={mapRef} style={{ height: 480 }} />
          </div>

          {coords && (
            <div style={{ marginTop: 10, padding: '10px 14px', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13, color: 'var(--text-muted)' }}>
              Selected: <strong style={{ color: 'var(--text)' }}>{coords.lat}°N, {coords.lng}°E</strong>
            </div>
          )}
        </div>

        {/* Form + Result */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div className="card">
            <div className="card-header"><span>Site parameters</span></div>
            <div className="card-body">
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Land Area <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>(acres)</span></label>
                <input type="number" step="0.1" value={form.land_area} onChange={e => num('land_area', e.target.value)} required />
              </div>

              <div className="form-group">
                <label>Brine Salinity <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>(g/L)</span></label>
                <input type="number" step="1" value={form.brine_salinity} onChange={e => num('brine_salinity', e.target.value)} required />
              </div>

              <div className="form-group">
                <label>Soil Permeability <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>(1–10)</span></label>
                <input type="range" min="1" max="10" step="0.5" value={form.soil_permeability}
                  onChange={e => num('soil_permeability', e.target.value)} />
                <div style={{ textAlign: 'right', fontSize: 13, color: 'var(--text-muted)' }}>{form.soil_permeability}</div>
              </div>

              <div className="form-group">
                <label>Notes <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>(optional)</span></label>
                <input type="text" value={form.notes} onChange={e => set('notes', e.target.value)} placeholder="e.g. Near Kalpitiya lagoon" />
              </div>

              {!coords && (
                <div style={{ padding: '10px 12px', background: 'var(--warning-bg)', borderRadius: 8, fontSize: 13, color: 'var(--warning)', marginBottom: 12, border: '1px solid #fde68a' }}>
                  Select a location on the map first
                </div>
              )}

              {error && <div className="error-msg">{error}</div>}

              <button className="btn btn-primary" type="submit" disabled={loading || !coords} style={{ marginTop: 4 }}>
                {loading
                  ? <><span className="spinner" style={{ width: 16, height: 16, borderWidth: 2 }} /> Fetching climate…</>
                  : 'Run Geo Assessment'}
              </button>
            </form>
            </div>
          </div>

          {result && (
            <>
              <div className={`result-card ${isViable ? 'viable' : 'not-viable'}`}>
                <div className="result-verdict">{isViable ? 'Viable' : 'Not Viable'}</div>
                <div className="result-percent">{result.viability_probability}%</div>
                <div className="result-label">viability probability</div>
                <div className="result-details">
                  <div className="result-detail-item">
                    <div className="label">Est. Yield</div>
                    <div className="value">{result.estimated_yield_tons > 0 ? `${result.estimated_yield_tons} t` : '—'}</div>
                  </div>
                  <div className="result-detail-item">
                    <div className="label">Evap. Index</div>
                    <div className="value">{result.climate?.evaporation_index}</div>
                  </div>
                </div>
              </div>

              {result.climate && (
                <div className="card">
                  <div className="card-header"><span>Auto-fetched Climate Data</span></div>
                  <div className="climate-grid">
                    <div className="climate-item"><div className="c-label">Temperature</div><div className="c-value">{result.climate.temperature}</div><div className="c-unit">°C avg</div></div>
                    <div className="climate-item"><div className="c-label">Rainfall</div><div className="c-value">{result.climate.rainfall}</div><div className="c-unit">mm/day</div></div>
                    <div className="climate-item"><div className="c-label">Wind Speed</div><div className="c-value">{result.climate.wind_speed}</div><div className="c-unit">km/h</div></div>
                  </div>
                </div>
              )}

              {result.recommendation?.length > 0 && (
                <div className="card">
                  <div className="card-header"><span>Recommendations</span></div>
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
