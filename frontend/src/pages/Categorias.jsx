import { useCallback, useEffect, useState } from 'react'
import { api } from '../api.js'
import { useAuth } from '../auth.jsx'

const VACIO = { nombre: '', descripcion: '', prefijo_sku: '' }

export default function Categorias() {
  const { usuario } = useAuth()
  const esAdmin = usuario?.rol === 'ADMIN'

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
      prefijo_sku: formulario.prefijo_sku.trim().toUpperCase(),
    }
    try {
      if (editandoId) {
        await api.actualizarCategoria(editandoId, datos)
      } else {
        await api.crearCategoria(datos)
      }
      cancelar()
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  function editar(c) {
    setEditandoId(c.id)
    setFormulario({
      nombre: c.nombre,
      descripcion: c.descripcion ?? '',
      prefijo_sku: c.prefijo_sku,
    })
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
          <p className="sutil">
            Cada categoría define el prefijo con el que se numeran los SKU de sus productos
          </p>
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

      {esAdmin ? (
        <form className="tarjeta form-categoria" onSubmit={guardar}>
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

          <label className="campo">
            <span>Prefijo SKU *</span>
            <input
              required
              minLength={2}
              maxLength={5}
              placeholder="BEB"
              pattern="[A-Za-z0-9]{2,5}"
              title="Entre 2 y 5 caracteres: letras sin tilde y números"
              className="mono-entrada"
              value={formulario.prefijo_sku}
              onChange={(e) =>
                setFormulario({
                  ...formulario,
                  prefijo_sku: e.target.value.toUpperCase(),
                })
              }
            />
            <small className="sutil">
              {formulario.prefijo_sku.length >= 2
                ? `Los productos quedarán como ${formulario.prefijo_sku}-001`
                : 'Tú lo eliges: 2 a 5 letras o números'}
            </small>
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
      ) : (
        <p className="aviso">Solo un usuario con rol ADMIN puede crear o editar categorías.</p>
      )}

      <div className="tabla-envoltura">
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th className="centro">Prefijo</th>
              <th>Descripción</th>
              <th className="centro">Productos activos</th>
              {esAdmin && <th className="derecha">Acciones</th>}
            </tr>
          </thead>
          <tbody>
            {cargando && (
              <tr>
                <td colSpan={esAdmin ? 5 : 4} className="celda-vacia">
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
                  <td className="centro">
                    <span className="etiqueta mono">{c.prefijo_sku}</span>
                  </td>
                  <td className="sutil">{c.descripcion || '—'}</td>
                  <td className="centro">{contar(c.id)}</td>
                  {esAdmin && (
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
                  )}
                </tr>
              ))}

            {!cargando && categorias.length === 0 && (
              <tr>
                <td colSpan={esAdmin ? 5 : 4} className="celda-vacia">
                  Todavía no hay categorías.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {editandoId && (
        <p className="nota">
          Cambiar el prefijo no renumera los productos que ya existen: conservan su SKU
          porque puede estar impreso en etiquetas. El prefijo nuevo aplica a los
          productos que se creen de aquí en adelante.
        </p>
      )}
    </section>
  )
}
