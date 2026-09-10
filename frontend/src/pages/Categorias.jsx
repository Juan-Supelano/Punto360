import { useCallback, useEffect, useState } from 'react'
import { api } from '../api.js'

const VACIO = { nombre: '', descripcion: '' }

export default function Categorias() {
  const [categorias, setCategorias] = useState([])
  const [productos, setProductos] = useState([])
  const [incluirInactivas, setIncluirInactivas] = useState(false)
  const [formulario, setFormulario] = useState(VACIO)
  const [editandoId, setEditandoId] = useState(null)
  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)

  const cargar = useCallback(async () => {
    setCargando(true)
    try {
      const [cats, prods] = await Promise.all([
        api.listarCategorias(incluirInactivas),
        api.listarProductos({ incluirInactivos: true }),
      ])
      setCategorias(cats)
      setProductos(prods)
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }, [incluirInactivas])

  useEffect(() => {
    cargar()
  }, [cargar])

  function contar(categoriaId) {
    return productos.filter((p) => p.categoria.id === categoriaId && p.activo).length
  }

  async function guardar(evento) {
    evento.preventDefault()
    const datos = {
      nombre: formulario.nombre.trim(),
      descripcion: formulario.descripcion.trim() || null,
    }
    try {
      if (editandoId) {
        await api.actualizarCategoria(editandoId, datos)
      } else {
        await api.crearCategoria(datos)
      }
      setFormulario(VACIO)
      setEditandoId(null)
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  function editar(c) {
    setEditandoId(c.id)
    setFormulario({ nombre: c.nombre, descripcion: c.descripcion ?? '' })
    setError('')
  }

  function cancelar() {
    setEditandoId(null)
    setFormulario(VACIO)
  }

  async function alternarActiva(c) {
    try {
      if (c.activo) {
        await api.desactivarCategoria(c.id)
      } else {
        await api.reactivarCategoria(c.id)
      }
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Categorías</h2>
          <p className="sutil">Cómo se agrupan los productos del catálogo</p>
        </div>
        <label className="check">
          <input
            type="checkbox"
            checked={incluirInactivas}
            onChange={(e) => setIncluirInactivas(e.target.checked)}
          />
          Ver inactivas
        </label>
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}

      <form className="tarjeta form-linea" onSubmit={guardar}>
        <label className="campo">
          <span>Nombre</span>
          <input
            required
            maxLength={80}
            placeholder="Bebidas"
            value={formulario.nombre}
            onChange={(e) => setFormulario({ ...formulario, nombre: e.target.value })}
          />
        </label>
        <label className="campo campo-ancho">
          <span>Descripción (opcional)</span>
          <input
            placeholder="Gaseosas, jugos, agua…"
            value={formulario.descripcion}
            onChange={(e) =>
              setFormulario({ ...formulario, descripcion: e.target.value })
            }
          />
        </label>
        <div className="form-linea-acciones">
          <button type="submit" className="btn btn-primario">
            {editandoId ? 'Guardar' : 'Agregar'}
          </button>
          {editandoId && (
            <button type="button" className="btn btn-suave" onClick={cancelar}>
              Cancelar
            </button>
          )}
        </div>
      </form>

      <div className="tabla-envoltura">
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Descripción</th>
              <th className="centro">Productos activos</th>
              <th className="derecha">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {cargando && (
              <tr>
                <td colSpan="4" className="celda-vacia">
                  Cargando…
                </td>
              </tr>
            )}

            {!cargando &&
              categorias.map((c) => (
                <tr key={c.id} className={c.activo ? '' : 'fila-inactiva'}>
                  <td>
                    <strong>{c.nombre}</strong>
                    {!c.activo && <span className="etiqueta gris">inactiva</span>}
                  </td>
                  <td className="sutil">{c.descripcion || '—'}</td>
                  <td className="centro">{contar(c.id)}</td>
                  <td className="derecha acciones">
                    <button className="btn btn-suave" onClick={() => editar(c)}>
                      Editar
                    </button>
                    <button
                      className={c.activo ? 'btn btn-peligro' : 'btn btn-suave'}
                      onClick={() => alternarActiva(c)}
                    >
                      {c.activo ? 'Desactivar' : 'Reactivar'}
                    </button>
                  </td>
                </tr>
              ))}

            {!cargando && categorias.length === 0 && (
              <tr>
                <td colSpan="4" className="celda-vacia">
                  Todavía no hay categorías.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}
