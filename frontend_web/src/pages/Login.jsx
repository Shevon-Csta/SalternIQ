import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { LogIn, AlertCircle, Waves } from 'lucide-react'
import { api } from '../api'

export default function Login() {
  const navigate = useNavigate()
  const [form, setForm] = useState({ email: '', password: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const data = await api.login(form)
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
          <h2 className="auth-left-title">ML-powered land suitability for Sri Lanka's salt farmers</h2>
          <p className="auth-left-sub">
            Assess any coastal site in seconds. Drop a pin on the map,
            enter your field parameters, and get a viability verdict from
            two trained machine learning models.
          </p>
        </div>
        <p className="auth-left-footer">
          BEng Software Engineering · IIT Colombo / University of Westminster
        </p>
      </div>

      <div className="auth-right">
        <div className="auth-form-box">
          <div className="auth-form-header">
            <h1>Sign in</h1>
            <p>Welcome back — enter your details below.</p>
          </div>

          {error && (
            <div className="error-msg">
              <AlertCircle size={14} /> {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
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
            <div className="form-group">
              <label>Password</label>
              <input
                type="password"
                placeholder="••••••••"
                value={form.password}
                onChange={e => set('password', e.target.value)}
                required
              />
            </div>
            <button className="btn btn-primary" type="submit" disabled={loading}>
              {loading
                ? <><span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} /> Signing in…</>
                : <><LogIn size={15} /> Sign in</>
              }
            </button>
          </form>

          <p className="auth-footer">
            Don't have an account? <Link to="/register">Create one</Link>
          </p>
          <p className="auth-footer" style={{ marginTop: 4 }}>
            <Link to="/">← Back to SalternIQ</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
