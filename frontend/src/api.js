// Un solo lugar donde vive la direccion de la API.
// Al desplegar en la nube solo se cambia el valor en el archivo .env
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'

async function pedir(ruta, opciones = {}) {
  const respuesta = await fetch(`${BASE}${ruta}`, {
    headers: { 'Content-Type': 'application/json' },
    ...opciones,
  })

  if (!respuesta.ok) {
    let mensaje = `Error ${respuesta.status}`
    try {
      const cuerpo = await respuesta.json()
      if (cuerpo.detail) mensaje = cuerpo.detail
    } catch {
      // la respuesta no traia JSON
    }
    throw new Error(mensaje)
  }

  return respuesta.status === 204 ? null : respuesta.json()
}

export const api = {
  listarCategorias: () => pedir('/categorias'),
  crearCategoria: (datos) =>
    pedir('/categorias', { method: 'POST', body: JSON.stringify(datos) }),
  desactivarCategoria: (id) => pedir(`/categorias/${id}`, { method: 'DELETE' }),

  listarProductos: (categoriaId) =>
    pedir(categoriaId ? `/productos?categoria_id=${categoriaId}` : '/productos'),
  crearProducto: (datos) =>
    pedir('/productos', { method: 'POST', body: JSON.stringify(datos) }),
  actualizarProducto: (id, datos) =>
    pedir(`/productos/${id}`, { method: 'PUT', body: JSON.stringify(datos) }),
  desactivarProducto: (id) => pedir(`/productos/${id}`, { method: 'DELETE' }),
}
