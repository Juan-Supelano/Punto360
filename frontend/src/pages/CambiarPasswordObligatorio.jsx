import { useState } from 'react'
import { api } from '../api.js'
import { useAuth } from '../auth.jsx'

const VACIO = { password_actual: '', password_nueva: '', confirmar: '' }

export default function CambiarPasswordObligatorio() {
  const { usuario, salir, refrescarUsuario } = useAuth()
  const [formulario, setFormulario] = useState(VACIO)
  const [verClaves, setVerClaves] = useState(false)
  const [error, setError] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function enviar(evento) {
    evento.preventDefault()
    setError('')

    if (formulario.password_nueva !== formulario.confirmar) {
      setError('La confirmación no coincide con la contraseña nueva')
      return
    }
    if (formulario.password_nueva === formulario.password_actual) {
      setError('La contraseña nueva debe ser distinta de la temporal')
      return
    }

    setEnviando(true)
    try {
      const actualizado = await api.cambiarPassword({
        password_actual: formulario.password_actual,
        password_nueva: formulario.password_nueva,
      })
      refrescarUsuario(actualizado)
    } catch (e) {
      setError(e.message)
      setEnviando(false)
    }
  }

  return (
    <div className="login-pantalla">
      <form className="login-caja" onSubmit={enviar}>
        <div className="login-marca">
          <div className="login-logo" aria-hidden="true">
            {usuario?.nombre?.[0]?.toUpperCase() || '!'}
          </div>
          <h1>Cambia tu contraseña</h1>
          <p>
            Hola {usuario?.nombre}. Tu contraseña es temporal: elige una nueva
            antes de seguir usando el sistema.
          </p>
        </div>

        {error && <p className="aviso aviso-error">{error}</p>}

        <label className="campo">
          <span>Contraseña temporal</span>
          <div className="campo-clave">
            <input
              type={verClaves ? 'text' : 'password'}
              autoComplete="current-password"
              required
              autoFocus
              value={formulario.password_actual}
              onChange={(e) =>
                setFormulario({ ...formulario, password_actual: e.target.value })
              }
            />
          </div>
        </label>

        <label className="campo">
          <span>Contraseña nueva</span>
          <div className="campo-clave">
            <input
              type={verClaves ? 'text' : 'password'}
              autoComplete="new-password"
              minLength={8}
              placeholder="Mínimo 8 caracteres"
              required
              value={formulario.password_nueva}
              onChange={(e) =>
                setFormulario({ ...formulario, password_nueva: e.target.value })
              }
            />
          </div>
        </label>

        <label className="campo">
          <span>Confirmar contraseña nueva</span>
          <div className="campo-clave">
            <input
              type={verClaves ? 'text' : 'password'}
              autoComplete="new-password"
              minLength={8}
              required
              value={formulario.confirmar}
              onChange={(e) => setFormulario({ ...formulario, confirmar: e.target.value })}
            />
            <button
              type="button"
              className="btn-texto"
              onClick={() => setVerClaves((v) => !v)}
            >
              {verClaves ? 'Ocultar' : 'Ver'}
            </button>
          </div>
        </label>

        <button type="submit" className="btn btn-primario btn-ancho" disabled={enviando}>
          {enviando ? 'Guardando…' : 'Cambiar contraseña y continuar'}
        </button>

        <p className="login-pie">
          ¿No eres tú? <button type="button" className="btn-texto" onClick={salir}>Cerrar sesión</button>
        </p>
      </form>
    </div>
  )
}
