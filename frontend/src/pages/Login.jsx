import { useState } from 'react'
import { useAuth } from '../auth.jsx'

export default function Login() {
  const { entrar } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [verClave, setVerClave] = useState(false)
  const [error, setError] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function enviar(evento) {
    evento.preventDefault()
    setError('')
    setEnviando(true)
    try {
      await entrar(email.trim().toLowerCase(), password)
    } catch (e) {
      setError(e.message)
      setEnviando(false)
    }
  }

  return (
    <div className="login-pantalla">
      <form className="login-caja" onSubmit={enviar}>
        <div className="login-marca">
          <div className="login-logo" aria-hidden="true">CP</div>
          <h1>Cuadre POS</h1>
          <p>Punto de venta e inventario</p>
        </div>

        {error && <p className="aviso aviso-error">{error}</p>}

        <label className="campo">
          <span>Correo</span>
          <input
            type="email"
            autoComplete="username"
            placeholder="usuario@empresa.co"
            required
            autoFocus
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </label>

        <label className="campo">
          <span>Contraseña</span>
          <div className="campo-clave">
            <input
              type={verClave ? 'text' : 'password'}
              autoComplete="current-password"
              placeholder="••••••••"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <button
              type="button"
              className="btn-texto"
              onClick={() => setVerClave((v) => !v)}
            >
              {verClave ? 'Ocultar' : 'Ver'}
            </button>
          </div>
        </label>

        <button type="submit" className="btn btn-primario btn-ancho" disabled={enviando}>
          {enviando ? 'Entrando…' : 'Entrar'}
        </button>

        <p className="login-pie">
          ¿Olvidaste la contraseña? Pídele a un administrador que la restablezca.
        </p>
      </form>
    </div>
  )
}
