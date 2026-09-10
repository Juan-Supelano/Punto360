import { useEffect, useState } from 'react'
import { api } from '../api.js'

const VACIO = {
  codigo: '',
  nombre: '',
  precio_venta: '',
  stock: '',
  categoria_id: '',
}

const pesos = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0,
})

export default function Productos() {
  const [productos, setProductos] = useState([])
  const [categorias, setCategorias] = useState([])
  const [filtro, setFiltro] = useState('')
  const [formulario, setFormulario] = useState(VACIO)
  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)

  async function cargar() {
    setCargando(true)
    try {
      const [listaProductos, listaCategorias] = await Promise.all([
        api.listarProductos(filtro || undefined),
        api.listarCategorias(),
      ])
      setProductos(listaProductos)
      setCategorias(listaCategorias)
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }

  useEffect(() => {
    cargar()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filtro])

  async function guardar(evento) {
    evento.preventDefault()
    try {
      await api.crearProducto({
        codigo: formulario.codigo,
        nombre: formulario.nombre,
        precio_venta: Number(formulario.precio_venta),
        stock: Number(formulario.stock || 0),
        categoria_id: Number(formulario.categoria_id),
      })
      setFormulario(VACIO)
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function desactivar(id) {
    try {
      await api.desactivarProducto(id)
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  return (
    <section>
      <h2>Productos</h2>
      {error && <p className="error">{error}</p>}

      <form onSubmit={guardar} className="tarjeta">
        <input
          placeholder="Código"
          required
          value={formulario.codigo}
          onChange={(e) => setFormulario({ ...formulario, codigo: e.target.value })}
        />
        <input
          placeholder="Nombre"
          required
          value={formulario.nombre}
          onChange={(e) => setFormulario({ ...formulario, nombre: e.target.value })}
        />
        <input
          placeholder="Precio"
          type="number"
          min="1"
          required
          value={formulario.precio_venta}
          onChange={(e) => setFormulario({ ...formulario, precio_venta: e.target.value })}
        />
        <input
          placeholder="Stock"
          type="number"
          min="0"
          value={formulario.stock}
          onChange={(e) => setFormulario({ ...formulario, stock: e.target.value })}
        />
        <select
          required
          value={formulario.categoria_id}
          onChange={(e) => setFormulario({ ...formulario, categoria_id: e.target.value })}
        >
          <option value="">Categoría…</option>
          {categorias.map((c) => (
            <option key={c.id} value={c.id}>
              {c.nombre}
            </option>
          ))}
        </select>
        <button type="submit">Agregar</button>
      </form>

      <div className="barra">
        <label>
          Filtrar por categoría:{' '}
          <select value={filtro} onChange={(e) => setFiltro(e.target.value)}>
            <option value="">Todas</option>
            {categorias.map((c) => (
              <option key={c.id} value={c.id}>
                {c.nombre}
              </option>
            ))}
          </select>
        </label>
      </div>

      {cargando ? (
        <p>Cargando…</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Código</th>
              <th>Nombre</th>
              <th>Categoría</th>
              <th className="derecha">Precio</th>
              <th className="derecha">Stock</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {productos.map((p) => (
              <tr key={p.id}>
                <td>{p.codigo}</td>
                <td>{p.nombre}</td>
                <td>{p.categoria.nombre}</td>
                <td className="derecha">{pesos.format(Number(p.precio_venta))}</td>
                <td className="derecha">{p.stock}</td>
                <td>
                  <button className="peligro" onClick={() => desactivar(p.id)}>
                    Desactivar
                  </button>
                </td>
              </tr>
            ))}
            {productos.length === 0 && (
              <tr>
                <td colSpan="6">No hay productos para mostrar.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </section>
  )
}
