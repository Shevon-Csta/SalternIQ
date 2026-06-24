import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { FlaskConical, MapPin, History, ArrowRight } from 'lucide-react'
import { api } from '../api'

const HERO_IMG = 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=1920&q=80'

export default function Dashboard() {
  const [stats, setStats]   = useState(null)
  const [recent, setRecent] = useState([])
  const [loading, setLoading] = useState(true)
  const [user, setUser]     = useState(null)

  useEffect(() => {
    Promise.all([api.stats(), api.history(), api.me()])
      .then(([s, h, u]) => {
        setStats(s)
        setRecent(h.predictions.slice(0, 5))
        setUser(u)
      })
      .finally(() => setLoading(false))
  }, [])

  if (loading) return (
    <div className="loading"><div className="spinner" /> Loading dashboard…</div>
  )

  const viabilityRate = stats?.total_predictions > 0
    ? Math.round((stats.viable_count / stats.total_predictions) * 100)
    : 0

  const firstName = user?.name?.split(' ')[0] ?? 'there'
  const today = new Date().toLocaleDateString('en-GB', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
  })

  return (
    <div className="dash-page">

      {/* ── Hero banner ──────────────────────────────────────────── */}
      <div
        className="dash-hero"
        style={{ backgroundImage: `url(${HERO_IMG})` }}
      >
        <div className="dash-hero-overlay" />
        <div className="dash-hero-content">
          <p className="dash-hero-date">{today}</p>
          <h1 className="dash-hero-title">Welcome back, {firstName}.</h1>
          <p className="dash-hero-sub">
            {stats?.total_predictions === 0
              ? 'You have no assessments yet. Start with a site below.'
              : `You have run ${stats.total_predictions} assessment${stats.total_predictions !== 1 ? 's' : ''} — ${stats.viable_count} viable site${stats.viable_count !== 1 ? 's' : ''} found.`
            }
          </p>
          <div className="dash-hero-actions">
            <Link to="/app/predict" className="dash-btn-white">
              Manual assessment <ArrowRight size={14} />
            </Link>
            <Link to="/app/geo-predict" className="dash-btn-outline">
              Geo assessment
            </Link>
          </div>
        </div>

        {/* Inline stats overlay */}
        {stats?.total_predictions > 0 && (
          <div className="dash-hero-stats">
            <div className="dhs-item">
              <div className="dhs-value">{stats.total_predictions}</div>
              <div className="dhs-label">Total assessments</div>
            </div>
            <div className="dhs-divider" />
            <div className="dhs-item">
              <div className="dhs-value" style={{ color: '#6ee7b7' }}>{stats.viable_count}</div>
              <div className="dhs-label">Viable sites</div>
            </div>
            <div className="dhs-divider" />
            <div className="dhs-item">
              <div className="dhs-value" style={{ color: '#fca5a5' }}>{stats.not_viable_count}</div>
              <div className="dhs-label">Not viable</div>
            </div>
            <div className="dhs-divider" />
            <div className="dhs-item">
              <div className="dhs-value" style={{ color: '#5ec5c5' }}>
                {stats.avg_estimated_yield ? `${stats.avg_estimated_yield}t` : '—'}
              </div>
              <div className="dhs-label">Avg est. yield</div>
            </div>
          </div>
        )}
      </div>

      <div className="dash-body">

        {/* ── Viability bar (only when data exists) ─────────────── */}
        {stats?.total_predictions > 0 && (
          <div className="dash-viability-row">
            <div className="dvr-label">
              Site viability rate — {viabilityRate}%
            </div>
            <div className="dvr-bar">
              <div className="dvr-fill" style={{ width: `${viabilityRate}%` }} />
            </div>
            <div className="dvr-ends">
              <span>{stats.viable_count} viable</span>
              <span>{stats.not_viable_count} not viable</span>
            </div>
          </div>
        )}

        {/* ── Start an assessment ───────────────────────────────── */}
        <div className="dash-section-label">Run an assessment</div>
        <div className="dash-actions-grid">
          <Link to="/app/predict" className="dash-action-block">
            <div className="dab-num">01</div>
            <FlaskConical size={22} className="dab-icon" />
            <h3>Manual Assessment</h3>
            <p>Enter soil, climate, and site parameters directly to get a viability verdict and yield estimate.</p>
            <span className="dab-arrow"><ArrowRight size={16} /></span>
          </Link>
          <Link to="/app/geo-predict" className="dash-action-block">
            <div className="dab-num">02</div>
            <MapPin size={22} className="dab-icon" />
            <h3>Geo Assessment</h3>
            <p>Click a point on the Sri Lanka coastline. Climate data is fetched automatically from satellite archives.</p>
            <span className="dab-arrow"><ArrowRight size={16} /></span>
          </Link>
          <Link to="/app/history" className="dash-action-block">
            <div className="dab-num">03</div>
            <History size={22} className="dab-icon" />
            <h3>Assessment History</h3>
            <p>Review all past site evaluations, filter by viability, and compare results across locations.</p>
            <span className="dab-arrow"><ArrowRight size={16} /></span>
          </Link>
        </div>

        {/* ── Recent assessments ────────────────────────────────── */}
        {recent.length > 0 && (
          <>
            <div className="dash-section-row">
              <div className="dash-section-label" style={{ marginBottom: 0 }}>Recent assessments</div>
              <Link to="/app/history" className="dash-view-all">
                View all <ArrowRight size={13} />
              </Link>
            </div>
            <div className="dash-recent-list">
              {recent.map((p, i) => (
                <div className="drl-row" key={p.id}>
                  <div className="drl-num">{String(i + 1).padStart(2, '0')}</div>
                  <div className="drl-date">
                    {new Date(p.created_at).toLocaleDateString('en-GB', {
                      day: '2-digit', month: 'short', year: 'numeric'
                    })}
                  </div>
                  <div className="drl-type">
                    {p.latitude ? 'Geo' : 'Manual'}
                  </div>
                  <div className="drl-area">{p.land_area} ac</div>
                  <div className={`drl-verdict ${p.viable ? 'viable' : 'not-viable'}`}>
                    {p.viable ? 'Viable' : 'Not viable'}
                  </div>
                  <div className="drl-prob">
                    {(p.viability_probability * 100).toFixed(1)}%
                  </div>
                  <div className="drl-yield">
                    {p.viable ? `${p.estimated_yield?.toFixed(1)} t` : '—'}
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {recent.length === 0 && (
          <div className="dash-empty">
            <p>No assessments yet.</p>
            <Link to="/app/predict">Run your first assessment →</Link>
          </div>
        )}

      </div>
    </div>
  )
}
