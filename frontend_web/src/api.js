// In dev: empty string → Vite proxy forwards to localhost:8000
// In production: VITE_API_URL = https://your-app.onrender.com
const BASE = import.meta.env.VITE_API_URL || ''

function getToken() {
  return localStorage.getItem('token')
}

function authHeaders() {
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${getToken()}`
  }
}

async function req(method, path, body) {
  const res = await fetch(BASE + path, {
    method,
    headers: body !== undefined ? authHeaders() : { 'Authorization': `Bearer ${getToken()}` },
    body: body !== undefined ? JSON.stringify(body) : undefined
  })
  const data = await res.json()
  if (!res.ok) throw new Error(data.detail || 'Request failed')
  return data
}

export const api = {
  register: (body) => fetch(BASE + '/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }).then(async r => { const d = await r.json(); if (!r.ok) throw new Error(d.detail); return d }),

  login: (body) => fetch(BASE + '/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }).then(async r => { const d = await r.json(); if (!r.ok) throw new Error(d.detail); return d }),

  logout: () => req('POST', '/auth/logout'),
  me: () => req('GET', '/auth/me'),

  predict: (body) => req('POST', '/predict', body),
  geoPredict: (body) => req('POST', '/predict/geo', body),

  history: () => req('GET', '/history'),
  stats: () => req('GET', '/dashboard/stats'),

  admin: {
    stats:      ()         => req('GET',    '/admin/stats'),
    users:      ()         => req('GET',    '/admin/users'),
    deleteUser: (id)       => req('DELETE', `/admin/users/${id}`),
  }
}
