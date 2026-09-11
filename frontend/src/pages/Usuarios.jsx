import { useCallback, useEffect, useState } from 'react'
import { api } from '../api.js'
import { useAuth } from '../auth.jsx'

const VACIO = { email: '', nombre: '', password: '', rol: 'CAJERO' }

const PERMISOS = {
  ADMIN: [
    'Crear, editar y desactivar productos, categorías, proveedores y compras',
    'Crear, editar, activar y desactivar otros usuarios (cajeros y administradores)',
    'Modificar los datos y el logo de la empresa',
    'Ver las ventas de todos los cajeros',
    'Acceso sin restricciones a toda la información del negocio',
  ],
  CAJERO: [
    'Registrar ventas en el punto de venta',
    'Ver y consultar productos, categorías y proveedores (sin poder crearlos ni editarlos)',
    'Ver únicamente sus propias ventas',
    'No puede gestionar usuarios, compras ni los datos de la empresa',
  ],
}

export default function Usuarios() {
  const { usuario } = useAuth()
  const esAdmin = usuario?.rol === 'ADMIN'

  const [usuarios, setUsuarios] = useState([])
  const [texto, setTexto] = useState('')
  const [busqueda, setBusqueda] = useState('')
  const [incluirInactivos, setIncluirInactivos] = useState(false)

  const [formulario, setFormulario] = useState(VACIO)
  const [editandoId, setEditandoId] = useState(null)
  const [panelAbierto, setPanelAbierto] = useState(false)
  const [confirmarPermisos, setConfirmarPermisos] = useState(false)

  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)

  const [reseteando, setReseteando] = useState(null) // id del usuario en proceso
  const [passwordTemporal, setPasswordTemporal] = useState(null) // { email, password_temporal }

  useEffect(() => {
    const t = setTimeout(() => setBusqueda(texto), 300)
    return () => clearTimeout(t)
  }, [texto])

  const cargar = useCallback(async () => {
    setCargando(true)
    try {
      const lista = await api.listarUsuarios({
        buscar: busqueda || undefined,
        incluirInactivos,
      })
      setUsuarios(lista)
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }, [busqueda, incluirInactivos])

  useEffect(() => {
    if (esAdmin) cargar()
  }, [cargar, esAdmin])

  function abrirNuevo() {
    setFormulario(VACIO)
    setEditandoId(null)
    setConfirmarPermisos(false)
    setPanelAbierto(true)
    setError('')
  }

  function abrirEdicion(u) {
    setFormulario({ email: u.email, nombre: u.nombre, password: '', rol: u.rol })
    setEditandoId(u.id)
    setConfirmarPermisos(false)
    setPanelAbierto(true)
    setError('')
  }

  function cerrarPanel() {
    setPanelAbierto(false)
    setEditandoId(null)
    setFormulario(VACIO)
    setConfirmarPermisos(false)
  }

  function cambiarRol(rol) {
    setFormulario({ ...formulario, rol })
    setConfirmarPermisos(false) // si cambia el rol, se reinicia la confirmación
  }

  async function guardar(evento) {
    evento.preventDefault()

    // Crear un ADMIN, o subir a alguien a ADMIN, pide confirmar antes de guardar.
    if (formulario.rol === 'ADMIN' && !confirmarPermisos) {
      setConfirmarPermisos(true)
      return
    }

    try {
      if (editandoId) {
        await api.actualizarUsuario(editandoId, {
          nombre: formulario.nombre.trim(),
          rol: formulario.rol,
        })
      } else {
        await api.crearUsuario({
          email: formulario.email.trim(),
          nombre: formulario.nombre.trim(),
          password: formulario.password,
          rol: formulario.rol,
        })
      }
      cerrarPanel()
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function alternarActivo(u) {
    try {
      if (u.activo) {
        await api.desactivarUsuario(u.id)
      } else {
        await api.reactivarUsuario(u.id)
      }
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function resetearPassword(u) {
    if (!window.confirm(`¿Resetear la contraseña de ${u.nombre}? La contraseña actual dejará de funcionar.`)) {
      return
    }
    setReseteando(u.id)
    setError('')
    try {
      const resultado = await api.resetearPasswordUsuario(u.id)
      setPasswordTemporal(resultado)
      cargar()
    } catch (e) {
      setError(e.message)
    } finally {
      setReseteando(null)
    }
  }

  if (!esAdmin) {
    return (
      <section>
        <h2>Usuarios</h2>
        <p className="aviso">Solo un usuario con rol ADMIN puede ver y gestionar usuarios.</p>
      </section>
    )
  }

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Usuarios</h2>
          <p className="sutil">Cajeros y administradores con acceso al sistema</p>
        </div>
        <button className="btn btn-primario" onClick={abrirNuevo}>
          + Nuevo usuario
        </button>
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}

      <div className="barra-filtros">
        <input
          className="buscador"
          type="search"
          placeholder="Buscar por nombre o correo…"
          value={texto}
          onChange={(e) => setTexto(e.target.value)}
        />
        <label className="check">
          <input
            type="checkbox"
            checked={incluirInactivos}
            onChange={(e) => setIncluirInactivos(e.target.checked)}
          />
          Ver inactivos
        </label>
      </div>

      <div className="tabla-envoltura">
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Correo</th>
              <th>Rol</th>
              <th className="centro">Estado</th>
              <th className="derecha">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {cargando && (
              <tr>
                <td colSpan={5} className="celda-vacia">
                  Cargando…
                </td>
              </tr>
            )}

            {!cargando &&
              usuarios.map((u) => (
                <tr key={u.id} className={u.activo ? '' : 'fila-inactiva'}>
                  <td>
                    <strong>{u.nombre}</strong>
                    {u.id === usuario.id && <span className="etiqueta gris">tú</span>}
                    {!u.activo && <span className="etiqueta gris">inactivo</span>}
                    {u.debe_cambiar_password && (
                      <span className="etiqueta gris" title="Todavía no cambió su contraseña temporal">
                        clave pendiente
                      </span>
                    )}
                  </td>
                  <td className="sutil">{u.email}</td>
                  <td>
                    <span className="etiqueta">
                      {u.rol === 'ADMIN' ? 'Administrador' : 'Cajero'}
                    </span>
                  </td>
                  <td className="centro">{u.activo ? 'Activo' : 'Inactivo'}</td>
                  <td className="derecha acciones">
                    <button className="btn btn-suave" onClick={() => abrirEdicion(u)}>
                      Editar
                    </button>
                    <button
                      className="btn btn-suave"
                      disabled={reseteando === u.id}
                      onClick={() => resetearPassword(u)}
                    >
                      {reseteando === u.id ? 'Reseteando…' : 'Resetear contraseña'}
                    </button>
                    <button
                      className={u.activo ? 'btn btn-peligro' : 'btn btn-suave'}
                      disabled={u.id === usuario.id}
                      title={u.id === usuario.id ? 'No puedes desactivar tu propia cuenta' : ''}
                      onClick={() => alternarActivo(u)}
                    >
                      {u.activo ? 'Desactivar' : 'Reactivar'}
                    </button>
                  </td>
                </tr>
              ))}

            {!cargando && usuarios.length === 0 && (
              <tr>
                <td colSpan={5} className="celda-vacia">
                  No hay usuarios que coincidan.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {panelAbierto && (
        <div className="fondo-modal" onClick={cerrarPanel}>
          <form className="modal" onClick={(e) => e.stopPropagation()} onSubmit={guardar}>
            <h3>{editandoId ? 'Editar usuario' : 'Nuevo usuario'}</h3>

            {error && <p className="aviso aviso-error">{error}</p>}

            <div className="rejilla-form">
              <label className="campo campo-completo">
                <span>Nombre</span>
                <input
                  required
                  maxLength={120}
                  value={formulario.nombre}
                  onChange={(e) => setFormulario({ ...formulario, nombre: e.target.value })}
                />
              </label>

              <label className="campo campo-completo">
                <span>Correo</span>
                <input
                  required
                  type="email"
                  readOnly={!!editandoId}
                  value={formulario.email}
                  onChange={(e) => setFormulario({ ...formulario, email: e.target.value })}
                />
                {editandoId && <small className="sutil">El correo no se puede cambiar.</small>}
              </label>

              {!editandoId && (
                <label className="campo campo-completo">
                  <span>Contraseña</span>
                  <input
                    required
                    type="password"
                    minLength={8}
                    placeholder="Mínimo 8 caracteres"
                    value={formulario.password}
                    onChange={(e) => setFormulario({ ...formulario, password: e.target.value })}
                  />
                </label>
              )}

              <label className="campo campo-completo">
                <span>Rol</span>
                <select value={formulario.rol} onChange={(e) => cambiarRol(e.target.value)}>
                  <option value="CAJERO">Cajero</option>
                  <option value="ADMIN">Administrador</option>
                </select>
                <small className="sutil rol-info">{PERMISOS[formulario.rol].join(' · ')}</small>
              </label>
            </div>

            {confirmarPermisos && (
              <div className="aviso aviso-advertencia">
                <strong>
                  Vas a {editandoId ? 'dar' : 'crear un usuario con'} rol <u>Administrador</u>.
                </strong>{' '}
                Este usuario podrá:
                <ul>
                  {PERMISOS.ADMIN.map((p) => (
                    <li key={p}>{p}</li>
                  ))}
                </ul>
                Presiona <strong>Guardar</strong> de nuevo para confirmar.
              </div>
            )}

            <div className="modal-pie">
              <button type="button" className="btn btn-suave" onClick={cerrarPanel}>
                Cancelar
              </button>
              <button type="submit" className="btn btn-primario">
                Guardar
              </button>
            </div>
          </form>
        </div>
      )}

      {passwordTemporal && (
        <div className="fondo-modal" onClick={() => setPasswordTemporal(null)}>
          <div className="modal modal-angosto" onClick={(e) => e.stopPropagation()}>
            <h3>Contraseña temporal generada</h3>

            <p className="sutil">
              Para <strong>{passwordTemporal.email}</strong>. Cópiala y compártela con el
              usuario ahora: no se va a volver a mostrar.
            </p>

            <div className="aviso aviso-advertencia">
              <strong style={{ fontSize: 18, letterSpacing: '0.05em' }}>
                {passwordTemporal.password_temporal}
              </strong>
            </div>

            <div className="modal-pie">
              <button
                type="button"
                className="btn btn-suave"
                onClick={() => navigator.clipboard?.writeText(passwordTemporal.password_temporal)}
              >
                Copiar
              </button>
              <button
                type="button"
                className="btn btn-primario"
                onClick={() => setPasswordTemporal(null)}
              >
                Listo
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  )
}
