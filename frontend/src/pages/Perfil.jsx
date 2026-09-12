import { useState } from 'react'
import { api, urlFoto } from '../api.js'
import { useAuth } from '../auth.jsx'

function iniciales(nombre = '') {
  return nombre
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0].toUpperCase())
    .join('')
}

const CLAVE_VACIA = { password_actual: '', password_nueva: '', confirmar: '' }

export default function Perfil() {
  const { usuario, refrescarUsuario } = useAuth()

  const [nombre, setNombre] = useState(usuario?.nombre || '')
  const [fotoUrl, setFotoUrl] = useState(usuario?.foto_url || '')
  const [errorDatos, setErrorDatos] = useState('')
  const [guardadoDatos, setGuardadoDatos] = useState(false)
  const [guardandoDatos, setGuardandoDatos] = useState(false)

  const [clave, setClave] = useState(CLAVE_VACIA)
  const [errorClave, setErrorClave] = useState('')
  const [claveGuardada, setClaveGuardada] = useState(false)
  const [guardandoClave, setGuardandoClave] = useState(false)

  async function guardarDatos(evento) {
    evento.preventDefault()
    setErrorDatos('')
    setGuardadoDatos(false)
    setGuardandoDatos(true)
    try {
      const actualizado = await api.actualizarPerfil({
        nombre: nombre.trim(),
        foto_url: fotoUrl.trim() || null,
      })
      refrescarUsuario(actualizado)
      setGuardadoDatos(true)
    } catch (e) {
      setErrorDatos(e.message)
    } finally {
      setGuardandoDatos(false)
    }
  }

  async function guardarClave(evento) {
    evento.preventDefault()
    setErrorClave('')
    setClaveGuardada(false)

    if (clave.password_nueva !== clave.confirmar) {
      setErrorClave('La confirmación no coincide con la contraseña nueva')
      return
    }

    setGuardandoClave(true)
    try {
      const actualizado = await api.cambiarPassword({
        password_actual: clave.password_actual,
        password_nueva: clave.password_nueva,
      })
      refrescarUsuario(actualizado)
      setClave(CLAVE_VACIA)
      setClaveGuardada(true)
    } catch (e) {
      setErrorClave(e.message)
    } finally {
      setGuardandoClave(false)
    }
  }

  if (!usuario) return null

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Mi perfil</h2>
          <p className="sutil">Tus datos de acceso al sistema</p>
        </div>
      </div>

      <div className="empresa-doble">
        <div>
          <form className="tarjeta rejilla-form" onSubmit={guardarDatos}>
            {errorDatos && <p className="aviso aviso-error campo-completo">{errorDatos}</p>}
            {guardadoDatos && (
              <p className="aviso aviso-ok campo-completo">Datos actualizados.</p>
            )}

            <label className="campo campo-completo">
              <span>Nombre</span>
              <input
                required
                maxLength={120}
                value={nombre}
                onChange={(e) => setNombre(e.target.value)}
              />
            </label>

            <label className="campo campo-completo">
              <span>URL de la foto</span>
              <input
                type="url"
                maxLength={500}
                placeholder="https://…"
                value={fotoUrl}
                onChange={(e) => setFotoUrl(e.target.value)}
              />
            </label>

            <label className="campo">
              <span>Correo</span>
              <input value={usuario.email} disabled />
              <small className="sutil">El correo no se puede cambiar aquí.</small>
            </label>

            <label className="campo">
              <span>Rol</span>
              <input value={usuario.rol === 'ADMIN' ? 'Administrador' : 'Cajero'} disabled />
              <small className="sutil">Solo un ADMIN puede cambiar tu rol.</small>
            </label>

            <div className="modal-pie campo-completo">
              <button type="submit" className="btn btn-primario" disabled={guardandoDatos}>
                {guardandoDatos ? 'Guardando…' : 'Guardar cambios'}
              </button>
            </div>
          </form>

          <form className="tarjeta rejilla-form" onSubmit={guardarClave}>
            <h3 className="campo-completo" style={{ margin: 0 }}>
              Cambiar contraseña
            </h3>

            {errorClave && <p className="aviso aviso-error campo-completo">{errorClave}</p>}
            {claveGuardada && (
              <p className="aviso aviso-ok campo-completo">Contraseña actualizada.</p>
            )}

            <label className="campo campo-completo">
              <span>Contraseña actual</span>
              <input
                required
                type="password"
                autoComplete="current-password"
                value={clave.password_actual}
                onChange={(e) => setClave({ ...clave, password_actual: e.target.value })}
              />
            </label>

            <label className="campo">
              <span>Contraseña nueva</span>
              <input
                required
                type="password"
                minLength={8}
                placeholder="Mínimo 8 caracteres"
                autoComplete="new-password"
                value={clave.password_nueva}
                onChange={(e) => setClave({ ...clave, password_nueva: e.target.value })}
              />
            </label>

            <label className="campo">
              <span>Confirmar contraseña nueva</span>
              <input
                required
                type="password"
                minLength={8}
                autoComplete="new-password"
                value={clave.confirmar}
                onChange={(e) => setClave({ ...clave, confirmar: e.target.value })}
              />
            </label>

            <div className="modal-pie campo-completo">
              <button type="submit" className="btn btn-primario" disabled={guardandoClave}>
                {guardandoClave ? 'Guardando…' : 'Cambiar contraseña'}
              </button>
            </div>
          </form>
        </div>

        <aside className="tarjeta vista-previa">
          <span className="dato-etiqueta">Foto de perfil</span>
          <div className="previa-marca">
            {fotoUrl ? (
              <img src={urlFoto(fotoUrl)} alt="" />
            ) : (
              <div className="previa-sinlogo">{iniciales(usuario.nombre) || '?'}</div>
            )}
            <div>
              <strong>{usuario.nombre}</strong>
              <div className="sutil">{usuario.rol === 'ADMIN' ? 'Administrador' : 'Cajero'}</div>
            </div>
          </div>

          <p className="nota">
            La foto se guarda como URL, no como archivo. Sube la imagen al bucket de
            Cloud Storage y pega aquí su dirección pública.
          </p>
        </aside>
      </div>
    </section>
  )
}
