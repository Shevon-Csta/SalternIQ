import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import {
  LayoutDashboard, FlaskConical, MapPin,
  History, Crown, LogOut, Mail
} from 'lucide-react'
import { api } from '../api'

const API = import.meta.env.VITE_API_URL || ''

export default function Layout() {
  const navigate = useNavigate()
  const [user, setUser]             = useState(null)
  const [resendSent, setResendSent] = useState(false)

  useEffect(() => {
    api.me().then(setUser).catch(() => {
      localStorage.removeItem('token')
      navigate('/login')
    })
  }, [])

  const handleLogout = async () => {
    try { await api.logout() } catch {}
    localStorage.removeItem('token')
    navigate('/login')
  }

  const handleResend = async () => {
    if (!user) return
    try {
      await fetch(`${API}/auth/resend-verification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: user.email })
      })
      setResendSent(true)
    } catch {}
  }

  const initials = user
    ? user.name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
    : '?'

  const navLink = (to, Icon, label) => (
    <NavLink to={to} className={({ isActive }) => 'nav-link' + (isActive ? ' active' : '')}>
      <Icon size={16} className="nav-icon" />
      {label}
    </NavLink>
  )

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-logo">
          <h1>Saltern<span>IQ</span></h1>
          <span>Land Suitability System</span>
        </div>

        <nav className="sidebar-nav">
          <p className="nav-section">Main</p>
          {navLink('/app/dashboard', LayoutDashboard, 'Dashboard')}

          <p className="nav-section">Predictions</p>
          {navLink('/app/predict',     FlaskConical, 'Manual Predict')}
          {navLink('/app/geo-predict', MapPin,       'Geo Predict')}

          <p className="nav-section">Records</p>
          {navLink('/app/history', History, 'History')}

          {user?.is_admin && (
            <>
              <p className="nav-section">System</p>
              {navLink('/app/admin', Crown, 'Admin Panel')}
            </>
          )}
        </nav>

        <div className="sidebar-footer">
          <div className="user-pill">
            <div className="user-avatar">{initials}</div>
            <div className="user-info">
              <div className="user-name">{user?.name || '—'}</div>
              <div className="user-email">{user?.email || '—'}</div>
            </div>
            <button className="logout-btn" onClick={handleLogout} title="Sign out">
              <LogOut size={15} />
            </button>
          </div>
        </div>
      </aside>

      <main className="main-content">
        {user && !user.verified && (
          <div className="verify-banner">
            <div className="verify-banner-left">
              <Mail size={15} />
              <span><strong>Verify your email address</strong> — check your inbox for a verification link.</span>
            </div>
            {resendSent
              ? <span className="verify-sent">Sent!</span>
              : (
                <button className="verify-resend" onClick={handleResend}>
                  Resend email
                </button>
              )}
          </div>
        )}

        <Outlet />
      </main>
    </div>
  )
}
