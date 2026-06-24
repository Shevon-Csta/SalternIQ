import { useEffect, useState } from 'react'
import { useSearchParams, Link } from 'react-router-dom'
import { CheckCircle, XCircle, Waves } from 'lucide-react'

export default function VerifyEmail() {
  const [params]  = useSearchParams()
  const [status, setStatus] = useState('loading')
  const [msg, setMsg]       = useState('')

  useEffect(() => {
    const token = params.get('token')
    if (!token) { setStatus('error'); setMsg('No verification token found in URL.'); return }

    fetch(`/auth/verify/${token}`)
      .then(async r => {
        const d = await r.json()
        if (r.ok) { setStatus('success'); setMsg(d.message) }
        else      { setStatus('error');   setMsg(d.detail)  }
      })
      .catch(() => { setStatus('error'); setMsg('Network error — please try again.') })
  }, [])

  return (
    <div className="auth-wrap" style={{ alignItems: 'center', justifyContent: 'center', background: '#0c1821' }}>
      <div style={{
        background: '#fff',
        borderRadius: 14,
        padding: '44px 40px',
        width: '100%',
        maxWidth: 380,
        textAlign: 'center',
        boxShadow: '0 20px 60px rgba(0,0,0,0.3)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 28, fontWeight: 700, fontSize: 17 }}>
          <Waves size={22} strokeWidth={1.8} style={{ color: '#0d8a8a' }} />
          <span>SalternIQ</span>
        </div>

        {status === 'loading' && (
          <>
            <div className="spinner" style={{ margin: '0 auto 16px' }} />
            <p style={{ color: 'var(--text-muted)' }}>Verifying your email…</p>
          </>
        )}

        {status === 'success' && (
          <>
            <CheckCircle size={48} strokeWidth={1.4} style={{ color: 'var(--success)', marginBottom: 12 }} />
            <h2 style={{ marginBottom: 8, letterSpacing: '-0.02em' }}>Email verified</h2>
            <p style={{ color: 'var(--text-muted)', marginBottom: 24, fontSize: 14 }}>
              Your account is now active. You can sign in below.
            </p>
            <Link to="/login" className="btn btn-primary btn-full">Go to Sign In</Link>
          </>
        )}

        {status === 'error' && (
          <>
            <XCircle size={48} strokeWidth={1.4} style={{ color: 'var(--danger)', marginBottom: 12 }} />
            <h2 style={{ marginBottom: 8, letterSpacing: '-0.02em' }}>Verification failed</h2>
            <div className="error-msg" style={{ textAlign: 'left', marginBottom: 20 }}>{msg}</div>
            <Link to="/login" className="btn btn-primary btn-full">Back to Sign In</Link>
          </>
        )}
      </div>
    </div>
  )
}
