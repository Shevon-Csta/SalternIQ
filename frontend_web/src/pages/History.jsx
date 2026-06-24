import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { MapPin, FlaskConical, ClipboardList, Plus } from 'lucide-react'
import { api } from '../api'

export default function History() {
  const [predictions, setPredictions] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')

  useEffect(() => {
    api.history().then(d => setPredictions(d.predictions)).finally(() => setLoading(false))
  }, [])

  const filtered = predictions.filter(p => {
    if (filter === 'viable')     return p.viable === 1
    if (filter === 'not-viable') return p.viable === 0
    return true
  })

  if (loading) return <div className="loading"><div className="spinner" /> Loading history…</div>

  return (
    <div className="page-inner">
      <div className="page-header">
        <div>
          <h2>Assessment History</h2>
          <p>All past suitability assessments — up to 50 most recent</p>
        </div>
        <Link to="/app/predict" className="btn btn-primary">
          <Plus size={15} /> New Assessment
        </Link>
      </div>

      <div className="tabs-row">
        <div className="tabs">
          <button className={`tab-btn ${filter === 'all' ? 'active' : ''}`} onClick={() => setFilter('all')}>
            All ({predictions.length})
          </button>
          <button className={`tab-btn ${filter === 'viable' ? 'active' : ''}`} onClick={() => setFilter('viable')}>
            Viable ({predictions.filter(p => p.viable === 1).length})
          </button>
          <button className={`tab-btn ${filter === 'not-viable' ? 'active' : ''}`} onClick={() => setFilter('not-viable')}>
            Not Viable ({predictions.filter(p => p.viable === 0).length})
          </button>
        </div>
      </div>

      <div className="card">
        <div className="card-body" style={{ padding: 0 }}>
          {filtered.length === 0 ? (
            <div className="empty-state" style={{ padding: '48px 24px' }}>
              <ClipboardList size={36} strokeWidth={1.2} style={{ color: 'var(--text-faint)', marginBottom: 12 }} />
              <p>{predictions.length === 0
                ? <><Link to="/app/predict">Run your first assessment</Link> to see results here.</>
                : 'No results match this filter.'
              }</p>
            </div>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Date</th>
                    <th>Type</th>
                    <th>Land Area</th>
                    <th>Viability</th>
                    <th>Probability</th>
                    <th>Est. Yield</th>
                    <th>Temperature</th>
                    <th>Rainfall</th>
                    <th>Salinity</th>
                    <th>Notes</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((p, i) => (
                    <tr key={p.id}>
                      <td style={{ color: 'var(--text-faint)', fontSize: 12 }}>{filtered.length - i}</td>
                      <td style={{ whiteSpace: 'nowrap' }}>
                        {new Date(p.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </td>
                      <td>
                        <span className="type-pill">
                          {p.latitude
                            ? <><MapPin size={11} /> Geo</>
                            : <><FlaskConical size={11} /> Manual</>
                          }
                        </span>
                      </td>
                      <td>{p.land_area} ac</td>
                      <td>
                        <span className={`badge ${p.viable ? 'badge-viable' : 'badge-not-viable'}`}>
                          {p.viable ? 'Viable' : 'Not Viable'}
                        </span>
                      </td>
                      <td><span style={{ fontWeight: 600 }}>{(p.viability_probability * 100).toFixed(1)}%</span></td>
                      <td>{p.viable ? `${p.estimated_yield?.toFixed(1)} t` : '—'}</td>
                      <td>{p.temperature != null ? `${p.temperature}°C` : '—'}</td>
                      <td>{p.rainfall != null ? `${p.rainfall} mm` : '—'}</td>
                      <td>{p.brine_salinity != null ? `${p.brine_salinity} g/L` : '—'}</td>
                      <td style={{ color: 'var(--text-muted)', fontSize: 13, maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {p.notes || '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
