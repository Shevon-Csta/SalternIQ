import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { UserPlus, AlertCircle, Waves } from 'lucide-react'
import { api } from '../api'

export default function Register() {
  const navigate = useNavigate()
  const [form, setForm] = useState({
    name: '', email: '', password: '', confirm: '',
    farm_name: '', location: ''
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (form.password !== form.confirm) { setError('Passwords do not match'); return }
    if (form.password.length < 6) { setError('Password must be at least 6 characters'); return }
    setLoading(true)
    try {
      const { confirm, ...payload } = form
      const data = await api.register(payload)
      localStorage.setItem('token', data.token)
      navigate('/app/dashboard')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-wrap">
      <div className="auth-left">
        <div className="auth-left-inner">
          <div className="auth-brand">
            <Waves size={28} strokeWidth={1.8} />
            <span>SalternIQ</span>
          </div>
          <h2 className="auth-left-title">Start assessing your land with machine learning</h2>
          <p className="auth-left-sub">
            Create a free account to access the full assessment suite —
            manual parameter input, GPS-based climate fetch, and a complete
            history of your past site evaluations.
          </p>
        </div>
        <p className="auth-left-footer">
          BEng Software Engineering · IIT Colombo / University of Westminster
        </p>
      </div>

      <div className="auth-right">
        <div className="auth-form-box">
          <div className="auth-form-header">
            <h1>Create account</h1>
            <p>Set up your SalternIQ account below.</p>
          </div>

          {error && (
            <div className="error-msg">
              <AlertCircle size={14} /> {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Full name</label>
              <input
                type="text"
                placeholder="Your name"
                value={form.name}
                onChange={e => set('name', e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label>Email address</label>
              <input
                type="email"
                placeholder="you@example.com"
                value={form.email}
                onChange={e => set('email', e.target.value)}
                required
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Password</label>
                <input
                  type="password"
                  placeholder="Min. 6 characters"
                  value={form.password}
                  onChange={e => set('password', e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label>Confirm password</label>
                <input
                  type="password"
                  placeholder="Repeat password"
                  value={form.confirm}
                  onChange={e => set('confirm', e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Farm name <span className="form-optional">optional</span></label>
                <input
                  type="text"
                  placeholder="e.g. Puttalam Salt Farm"
                  value={form.farm_name}
                  onChange={e => set('farm_name', e.target.value)}
                />
              </div>
              <div className="form-group">
                <label>Location <span className="form-optional">optional</span></label>
                <input
                  type="text"
                  placeholder="e.g. Puttalam, LK"
                  value={form.location}
                  onChange={e => set('location', e.target.value)}
                />
              </div>
            </div>

            <button className="btn btn-primary" type="submit" disabled={loading}>
              {loading
                ? <><span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} /> Creating account…</>
                : <><UserPlus size={15} /> Create account</>
              }
            </button>
          </form>

          <p className="auth-footer">
            Already have an account? <Link to="/login">Sign in</Link>
          </p>
          <p className="auth-footer" style={{ marginTop: 4 }}>
            <Link to="/">← Back to SalternIQ</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
