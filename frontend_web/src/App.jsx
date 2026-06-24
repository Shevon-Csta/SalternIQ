import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login       from './pages/Login'
import Register    from './pages/Register'
import Dashboard   from './pages/Dashboard'
import Predict     from './pages/Predict'
import GeoPredict  from './pages/GeoPredict'
import History     from './pages/History'
import VerifyEmail from './pages/VerifyEmail'
import Admin       from './pages/Admin'
import Landing     from './pages/Landing'
import Layout      from './components/Layout'
import './index.css'

function PrivateRoute({ children }) {
  return localStorage.getItem('token') ? children : <Navigate to="/login" replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/"         element={<Landing />} />
        <Route path="/login"    element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/verify"   element={<VerifyEmail />} />
        <Route path="/app" element={<PrivateRoute><Layout /></PrivateRoute>}>
          <Route index element={<Navigate to="/app/dashboard" replace />} />
          <Route path="dashboard"   element={<Dashboard />} />
          <Route path="predict"     element={<Predict />} />
          <Route path="geo-predict" element={<GeoPredict />} />
          <Route path="history"     element={<History />} />
          <Route path="admin"       element={<Admin />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
