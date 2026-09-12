import { useCallback, useEffect, useState } from 'react'
import { api } from '../api.js'

const TIPOS_DOC = ['CC', 'NIT', 'CE', 'TI', 'PAS']

const VACIO = {
  tipo_doc: 'CC',
  num_doc: '',
  nombre: '',
  email: '',
  telefono: '',
  direccion: '',
}

export default function Clientes() {
  const [clientes, setClientes] = useState([])
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
      const lista = await api.listarClientes({
        buscar: busqueda || undefined,
        incluirInactivos,
      })
      setClientes(lista)
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

  function abrirEdicion(c) {
    setFormulario({
      tipo_doc: c.tipo_doc,
      num_doc: c.num_doc,
      nombre: c.nombre,
      email: c.email ?? '',
      telefono: c.telefono ?? '',
      direccion: c.direccion ?? '',
    })
    setEditandoId(c.id)
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
    try {
      if (editandoId) {
        await api.actualizarCliente(editandoId, {
          nombre: formulario.nombre.trim(),
          email: formulario.email.trim() || null,
          telefono: formulario.telefono.trim() || null,
          direccion: formulario.direccion.trim() || null,
        })
      } else {
        await api.crearCliente({
          tipo_doc: formulario.tipo_doc,
          num_doc: formulario.num_doc.trim(),
          nombre: formulario.nombre.trim(),
          email: formulario.email.trim() || null,
          telefono: formulario.telefono.trim() || null,
          direccion: formulario.direccion.trim() || null,
        })
      }
      cerrarPanel()
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function alternarActivo(c) {
    try {
      if (c.activo) {
        await api.desactivarCliente(c.id)
      } else {
        await api.reactivarCliente(c.id)
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
          <h2>Clientes</h2>
          <p className="sutil">A quién se le vende</p>
        </div>
        <button className="btn btn-primario" onClick={abrirNuevo}>
          + Nuevo cliente
        </button>
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}

      <div className="barra-filtros">
        <input
          className="buscador"
          type="search"
          placeholder="Buscar por nombre o documento…"
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
              <th>Documento</th>
              <th>Cliente</th>
              <th>Teléfono</th>
              <th>Correo</th>
              <th>Dirección</th>
              <th className="derecha">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {cargando && (
              <tr>
                <td colSpan={6} className="celda-vacia">
                  Cargando…
                </td>
              </tr>
            )}

            {!cargando &&
              clientes.map((c) => (
                <tr key={c.id} className={c.activo ? '' : 'fila-inactiva'}>
                  <td className="mono">
                    {c.tipo_doc} {c.num_doc}
                  </td>
                  <td>
                    <strong>{c.nombre}</strong>
                    {!c.activo && <span className="etiqueta gris">inactivo</span>}
                  </td>
                  <td className="sutil">{c.telefono || '—'}</td>
                  <td className="sutil">{c.email || '—'}</td>
                  <td className="sutil">{c.direccion || '—'}</td>
                  <td className="derecha acciones">
                    <button className="btn btn-suave" onClick={() => abrirEdicion(c)}>
                      Editar
                    </button>
                    <button
                      className={c.activo ? 'btn btn-peligro' : 'btn btn-suave'}
                      onClick={() => alternarActivo(c)}
                    >
                      {c.activo ? 'Desactivar' : 'Reactivar'}
                    </button>
                  </td>
                </tr>
              ))}

            {!cargando && clientes.length === 0 && (
              <tr>
                <td colSpan={6} className="celda-vacia">
                  No hay clientes que coincidan.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {panelAbierto && (
        <div className="fondo-modal" onClick={cerrarPanel}>
          <form className="modal" onClick={(e) => e.stopPropagation()} onSubmit={guardar}>
            <h3>{editandoId ? 'Editar cliente' : 'Nuevo cliente'}</h3>

            <div className="rejilla-form">
              <label className="campo">
                <span>Tipo de documento</span>
                <select
                  required
                  disabled={!!editandoId}
                  {...campo('tipo_doc')}
                >
                  {TIPOS_DOC.map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>
              </label>

              <label className="campo">
                <span>Número de documento</span>
                <input
                  required
                  maxLength={20}
                  className="mono-entrada"
                  disabled={!!editandoId}
                  {...campo('num_doc')}
                />
              </label>

              <label className="campo campo-ancho">
                <span>Nombre</span>
                <input required maxLength={150} {...campo('nombre')} />
              </label>

              <label className="campo">
                <span>Teléfono</span>
                <input maxLength={30} {...campo('telefono')} />
              </label>

              <label className="campo">
                <span>Correo</span>
                <input type="email" maxLength={120} {...campo('email')} />
              </label>

              <label className="campo campo-ancho">
                <span>Dirección</span>
                <input maxLength={200} {...campo('direccion')} />
              </label>
            </div>

            <div className="modal-pie">
              <button type="button" className="btn btn-suave" onClick={cerrarPanel}>
                Cancelar
              </button>
              <button type="submit" className="btn btn-primario">
                {editandoId ? 'Guardar cambios' : 'Crear cliente'}
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  )
}
