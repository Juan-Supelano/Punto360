import { useCallback, useEffect, useState } from 'react'
import { api } from '../api.js'
import { useAuth } from '../auth.jsx'

const VACIO = { nit: '', nombre: '', contacto: '', telefono: '', email: '' }

export default function Proveedores() {
  const { usuario } = useAuth()
  const esAdmin = usuario?.rol === 'ADMIN'

  const [proveedores, setProveedores] = useState([])
  const [texto, setTexto] = useState('')
  const [busqueda, setBusqueda] = useState('')
  const [incluirInactivos, setIncluirInactivos] = useState(false)

  const [formulario, setFormulario] = useState(VACIO)
  const [editandoId, setEditandoId] = useState(null)
  const [panelAbierto, setPanelAbierto] = useState(false)

  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)

  useEffect(() => {
    const t = setTimeout(() => setBusqueda(texto), 300)
    return () => clearTimeout(t)
  }, [texto])

  const cargar = useCallback(async () => {
    setCargando(true)
    try {
      const lista = await api.listarProveedores({
        buscar: busqueda || undefined,
        incluirInactivos,
      })
      setProveedores(lista)
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }, [busqueda, incluirInactivos])

  useEffect(() => {
    cargar()
  }, [cargar])

  function abrirNuevo() {
    setFormulario(VACIO)
    setEditandoId(null)
    setPanelAbierto(true)
    setError('')
  }

  function abrirEdicion(p) {
    setFormulario({
      nit: p.nit,
      nombre: p.nombre,
      contacto: p.contacto ?? '',
      telefono: p.telefono ?? '',
      email: p.email ?? '',
    })
    setEditandoId(p.id)
    setPanelAbierto(true)
    setError('')
  }

  function cerrarPanel() {
    setPanelAbierto(false)
    setEditandoId(null)
    setFormulario(VACIO)
  }

  async function guardar(evento) {
    evento.preventDefault()
    const datos = {
      nit: formulario.nit.trim(),
      nombre: formulario.nombre.trim(),
      contacto: formulario.contacto.trim() || null,
      telefono: formulario.telefono.trim() || null,
      email: formulario.email.trim() || null,
    }
    try {
      if (editandoId) {
        await api.actualizarProveedor(editandoId, datos)
      } else {
        await api.crearProveedor(datos)
      }
      cerrarPanel()
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function alternarActivo(p) {
    try {
      if (p.activo) {
        await api.desactivarProveedor(p.id)
      } else {
        await api.reactivarProveedor(p.id)
      }
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  const campo = (nombre) => ({
    value: formulario[nombre],
    onChange: (e) => setFormulario({ ...formulario, [nombre]: e.target.value }),
  })

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Proveedores</h2>
          <p className="sutil">A quién se le compra la mercancía</p>
        </div>
        {esAdmin && (
          <button className="btn btn-primario" onClick={abrirNuevo}>
            + Nuevo proveedor
          </button>
        )}
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}

      <div className="barra-filtros">
        <input
          className="buscador"
          type="search"
          placeholder="Buscar por nombre o NIT…"
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
              <th>NIT</th>
              <th>Proveedor</th>
              <th>Contacto</th>
              <th>Teléfono</th>
              <th>Correo</th>
              {esAdmin && <th className="derecha">Acciones</th>}
            </tr>
          </thead>
          <tbody>
            {cargando && (
              <tr>
                <td colSpan={esAdmin ? 6 : 5} className="celda-vacia">
                  Cargando…
                </td>
              </tr>
            )}

            {!cargando &&
              proveedores.map((p) => (
                <tr key={p.id} className={p.activo ? '' : 'fila-inactiva'}>
                  <td className="mono">{p.nit}</td>
                  <td>
                    <strong>{p.nombre}</strong>
                    {!p.activo && <span className="etiqueta gris">inactivo</span>}
                  </td>
                  <td className="sutil">{p.contacto || '—'}</td>
                  <td className="sutil">{p.telefono || '—'}</td>
                  <td className="sutil">{p.email || '—'}</td>
                  {esAdmin && (
                    <td className="derecha acciones">
                      <button className="btn btn-suave" onClick={() => abrirEdicion(p)}>
                        Editar
                      </button>
                      <button
                        className={p.activo ? 'btn btn-peligro' : 'btn btn-suave'}
                        onClick={() => alternarActivo(p)}
                      >
                        {p.activo ? 'Desactivar' : 'Reactivar'}
                      </button>
                    </td>
                  )}
                </tr>
              ))}

            {!cargando && proveedores.length === 0 && (
              <tr>
                <td colSpan={esAdmin ? 6 : 5} className="celda-vacia">
                  No hay proveedores que coincidan.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {panelAbierto && (
        <div className="fondo-modal" onClick={cerrarPanel}>
          <form
            className="modal"
            onClick={(e) => e.stopPropagation()}
            onSubmit={guardar}
          >
            <h3>{editandoId ? 'Editar proveedor' : 'Nuevo proveedor'}</h3>

            <div className="rejilla-form">
              <label className="campo">
                <span>NIT</span>
                <input required maxLength={20} className="mono-entrada" {...campo('nit')} />
              </label>

              <label className="campo campo-ancho">
                <span>Nombre o razón social</span>
                <input required maxLength={150} {...campo('nombre')} />
              </label>

              <label className="campo">
                <span>Contacto</span>
                <input maxLength={120} {...campo('contacto')} />
              </label>

              <label className="campo">
                <span>Teléfono</span>
                <input maxLength={30} {...campo('telefono')} />
              </label>

              <label className="campo">
                <span>Correo</span>
                <input type="email" maxLength={120} {...campo('email')} />
              </label>
            </div>

            <div className="modal-pie">
              <button type="button" className="btn btn-suave" onClick={cerrarPanel}>
                Cancelar
              </button>
              <button type="submit" className="btn btn-primario">
                {editandoId ? 'Guardar cambios' : 'Crear proveedor'}
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  )
}
