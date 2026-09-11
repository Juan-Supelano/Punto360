// Un solo lugar donde vive la direccion de la API.
// Al desplegar en la nube solo se cambia el valor en el archivo .env
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const LLAVE_TOKEN = 'cuadre_pos_token'

export const sesion = {
  leer: () => localStorage.getItem(LLAVE_TOKEN),
  guardar: (token) => localStorage.setItem(LLAVE_TOKEN, token),
  borrar: () => localStorage.removeItem(LLAVE_TOKEN),
}

// Se dispara cuando la API responde 401: la app vuelve al login.
let alExpirar = () => {}
export function cuandoExpireLaSesion(fn) {
  alExpirar = fn
}

async function pedir(ruta, opciones = {}) {
  const token = sesion.leer()
  const cabeceras = { 'Content-Type': 'application/json', ...opciones.headers }
  if (token) cabeceras.Authorization = `Bearer ${token}`

  let respuesta
  try {
    respuesta = await fetch(`${BASE}${ruta}`, { ...opciones, headers: cabeceras })
  } catch {
    throw new Error('No se pudo conectar con la API. ¿Está corriendo uvicorn?')
  }

  if (respuesta.status === 401) {
    sesion.borrar()
    alExpirar()
    throw new Error('La sesión expiró. Vuelve a iniciar sesión.')
  }

  if (!respuesta.ok) {
    let mensaje = `Error ${respuesta.status}`
    try {
      const cuerpo = await respuesta.json()
      if (typeof cuerpo.detail === 'string') {
        mensaje = cuerpo.detail
      } else if (Array.isArray(cuerpo.detail)) {
        // Errores de validación de Pydantic.
        mensaje = cuerpo.detail
          .map((d) => `${d.loc?.slice(1).join('.')}: ${d.msg}`)
          .join(' · ')
      }
    } catch {
      // la respuesta no traía JSON
    }
    throw new Error(mensaje)
  }

  return respuesta.status === 204 ? null : respuesta.json()
}

const cuerpo = (datos) => ({ body: JSON.stringify(datos) })

export const api = {
  // --- Sesión ---------------------------------------------------------------
  login: (email, password) =>
    pedir('/auth/login', { method: 'POST', ...cuerpo({ email, password }) }),
  yo: () => pedir('/auth/yo'),
  verComercio: () => pedir('/auth/comercio'),
  actualizarComercio: (datos) =>
    pedir('/auth/comercio', { method: 'PUT', ...cuerpo(datos) }),

  // --- Categorías -----------------------------------------------------------
  listarCategorias: (incluirInactivas = false) =>
    pedir(`/categorias?incluir_inactivas=${incluirInactivas}`),
  crearCategoria: (datos) =>
    pedir('/categorias', { method: 'POST', ...cuerpo(datos) }),
  actualizarCategoria: (id, datos) =>
    pedir(`/categorias/${id}`, { method: 'PUT', ...cuerpo(datos) }),
  desactivarCategoria: (id) => pedir(`/categorias/${id}`, { method: 'DELETE' }),
  reactivarCategoria: (id) =>
    pedir(`/categorias/${id}/reactivar`, { method: 'POST' }),

  // --- Productos ------------------------------------------------------------
  listarProductos: ({ categoriaId, buscar, soloStockBajo, incluirInactivos } = {}) => {
    const p = new URLSearchParams()
    if (categoriaId) p.set('categoria_id', categoriaId)
    if (buscar) p.set('buscar', buscar)
    if (soloStockBajo) p.set('solo_stock_bajo', 'true')
    if (incluirInactivos) p.set('incluir_inactivos', 'true')
    const cadena = p.toString()
    return pedir(cadena ? `/productos?${cadena}` : '/productos')
  },
  siguienteSku: (categoriaId) =>
    pedir(`/productos/siguiente-sku?categoria_id=${categoriaId}`),
  crearProducto: (datos) => pedir('/productos', { method: 'POST', ...cuerpo(datos) }),
  actualizarProducto: (id, datos) =>
    pedir(`/productos/${id}`, { method: 'PUT', ...cuerpo(datos) }),
  ajustarStock: (id, cantidad) =>
    pedir(`/productos/${id}/stock?cantidad=${cantidad}`, { method: 'PATCH' }),
  desactivarProducto: (id) => pedir(`/productos/${id}`, { method: 'DELETE' }),
  reactivarProducto: (id) => pedir(`/productos/${id}/reactivar`, { method: 'POST' }),
}

export const pesos = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0,
})
