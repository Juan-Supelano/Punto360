import { useEffect, useState } from 'react'
import { api } from '../api.js'

const VACIO = { nombre: '', descripcion: '' }

export default function Categorias() {
  const [categorias, setCategorias] = useState([])
  const [formulario, setFormulario] = useState(VACIO)
  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)

  async function cargar() {
    setCargando(true)
    try {
      setCategorias(await api.listarCategorias())
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }

  useEffect(() => {
    cargar()
  }, [])

  async function guardar(evento) {
    evento.preventDefault()
    try {
      await api.crearCategoria({
        nombre: formulario.nombre,
        descripcion: formulario.descripcion || null,
      })
      setFormulario(VACIO)
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function desactivar(id) {
    try {
      await api.desactivarCategoria(id)
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  return (
    <section>
      <h2>Categorías</h2>
      {error && <p className="error">{error}</p>}

      <form onSubmit={guardar} className="tarjeta">
        <input
          placeholder="Nombre"
          required
          value={formulario.nombre}
          onChange={(e) => setFormulario({ ...formulario, nombre: e.target.value })}
        />
        <input
          placeholder="Descripción (opcional)"
          value={formulario.descripcion}
          onChange={(e) => setFormulario({ ...formulario, descripcion: e.target.value })}
        />
        <button type="submit">Agregar</button>
      </form>

      {cargando ? (
        <p>Cargando…</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Nombre</th>
              <th>Descripción</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {categorias.map((c) => (
              <tr key={c.id}>
                <td>{c.id}</td>
                <td>{c.nombre}</td>
                <td>{c.descripcion || '—'}</td>
                <td>
                  <button className="peligro" onClick={() => desactivar(c.id)}>
                    Desactivar
                  </button>
                </td>
              </tr>
            ))}
            {categorias.length === 0 && (
              <tr>
                <td colSpan="4">Todavía no hay categorías.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </section>
  )
}
