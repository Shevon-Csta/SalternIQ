import { useState, useEffect } from 'react'
import {
  Users, CheckCircle, Mail, Layers, TrendingUp,
  RefreshCw, Crown, Trash2
} from 'lucide-react'
import { api } from '../api'

function StatCard({ icon: Icon, label, value, color }) {
  return (
    <div className="stat-card">
      <div className="stat-card-top">
        <div className="stat-icon-wrap" style={color ? { color } : {}}>
          <Icon size={17} />
        </div>
        <div className="stat-label">{label}</div>
      </div>
      <div className="stat-value" style={color ? { color } : {}}>{value}</div>
    </div>
  )
}

export default function Admin() {
  const [users, setUsers]       = useState([])
  const [stats, setStats]       = useState(null)
  const [loading, setLoading]   = useState(true)
  const [deleting, setDeleting] = useState(null)
  const [error, setError]       = useState('')
  const [filter, setFilter]     = useState('all')

  const load = () => {
    setLoading(true)
    Promise.all([api.admin.users(), api.admin.stats()])
      .then(([u, s]) => { setUsers(u.users); setStats(s) })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const handleDelete = async (user) => {
    if (!window.confirm(`Delete account for ${user.name} (${user.email})?\n\nThis will also delete all their predictions. This cannot be undone.`)) return
    setDeleting(user.id)
    try {
      await api.admin.deleteUser(user.id)
      setUsers(prev => prev.filter(u => u.id !== user.id))
    } catch (e) {
      alert(`Could not delete: ${e.message}`)
    } finally {
      setDeleting(null)
    }
  }

  const filtered = users.filter(u => {
    if (filter === 'verified')   return u.verified
    if (filter === 'unverified') return !u.verified
    return true
  })

  if (loading) return <div className="loading"><div className="spinner" /> Loading admin panel…</div>

  return (
    <div className="page-inner">
      <div className="page-header">
        <div>
          <h2>Admin Panel</h2>
          <p>Manage user accounts and view system-wide statistics</p>
        </div>
        <button className="btn btn-secondary" onClick={load}>
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {error && <div className="error-msg" style={{ marginBottom: 20 }}>{error}</div>}

      {stats && (
        <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(5, 1fr)' }}>
          <StatCard icon={Users}       label="Total Users"        value={stats.total_users} />
          <StatCard icon={CheckCircle} label="Verified"           value={stats.verified_users}    color="var(--success)" />
          <StatCard icon={Mail}        label="Unverified"         value={stats.unverified_users}  color="var(--warning)" />
          <StatCard icon={Layers}      label="Total Assessments"  value={stats.total_predictions} />
          <StatCard icon={TrendingUp}  label="Viable Sites Found" value={stats.viable_predictions} color="var(--teal)" />
        </div>
      )}

      <div className="tabs-row">
        <div className="tabs">
          <button className={`tab-btn ${filter === 'all' ? 'active' : ''}`} onClick={() => setFilter('all')}>
            All ({users.length})
          </button>
          <button className={`tab-btn ${filter === 'verified' ? 'active' : ''}`} onClick={() => setFilter('verified')}>
            Verified ({users.filter(u => u.verified).length})
          </button>
          <button className={`tab-btn ${filter === 'unverified' ? 'active' : ''}`} onClick={() => setFilter('unverified')}>
            Unverified ({users.filter(u => !u.verified).length})
          </button>
        </div>
      </div>

      <div className="card">
        <div className="card-body" style={{ padding: 0 }}>
          {filtered.length === 0 ? (
            <div className="empty-state" style={{ padding: '48px 24px' }}>
              <Users size={36} strokeWidth={1.2} style={{ color: 'var(--text-faint)', marginBottom: 12 }} />
              <p>No users match this filter.</p>
            </div>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Farm Name</th>
                    <th>Location</th>
                    <th>Status</th>
                    <th>Assessments</th>
                    <th>Joined</th>
                    <th>Role</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map(u => (
                    <tr key={u.id}>
                      <td style={{ color: 'var(--text-faint)', fontSize: 12 }}>{u.id}</td>
                      <td style={{ fontWeight: 500 }}>{u.name}</td>
                      <td style={{ color: 'var(--text-muted)', fontSize: 13 }}>{u.email}</td>
                      <td style={{ color: 'var(--text-muted)', fontSize: 13 }}>{u.farm_name || '—'}</td>
                      <td style={{ color: 'var(--text-muted)', fontSize: 13 }}>{u.location || '—'}</td>
                      <td>
                        <span
                          className="badge"
                          style={u.verified
                            ? { background: 'var(--success-bg)', color: 'var(--success)' }
                            : { background: 'var(--warning-bg)', color: 'var(--warning)' }
                          }
                        >
                          {u.verified ? 'Verified' : 'Unverified'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'center' }}>{u.prediction_count}</td>
                      <td style={{ fontSize: 13, color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                        {new Date(u.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </td>
                      <td>
                        {u.is_admin
                          ? (
                            <span className="badge" style={{ background: '#ede9fe', color: '#6d28d9', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                              <Crown size={11} /> Admin
                            </span>
                          ) : (
                            <span className="badge" style={{ background: 'var(--bg)', color: 'var(--text-muted)' }}>User</span>
                          )
                        }
                      </td>
                      <td>
                        {!u.is_admin && (
                          <button
                            className="btn-danger-sm"
                            onClick={() => handleDelete(u)}
                            disabled={deleting === u.id}
                            title="Delete account"
                          >
                            {deleting === u.id
                              ? <span className="spinner" style={{ width: 12, height: 12, borderWidth: 2 }} />
                              : <Trash2 size={13} />
                            }
                          </button>
                        )}
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
