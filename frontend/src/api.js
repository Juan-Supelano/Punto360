// Un solo lugar donde vive la direccion de la API.
// Al desplegar en la nube solo se cambia el valor en el archivo .env
// Se exporta porque las paginas la necesitan para armar URLs de archivos
// estaticos (por ejemplo, foto_url que el backend devuelve como ruta relativa).
export const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'

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

// Igual que `pedir`, pero para subir archivos: el navegador arma el
// Content-Type multipart/form-data con el boundary correcto solo si nosotros
// NO lo fijamos a mano.
async function pedirFormData(ruta, formData) {
  const token = sesion.leer()
  const cabeceras = {}
  if (token) cabeceras.Authorization = `Bearer ${token}`

  let respuesta
  try {
    respuesta = await fetch(`${BASE}${ruta}`, {
      method: 'POST',
      headers: cabeceras,
      body: formData,
    })
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

  // --- Proveedores (solo ADMIN) ---------------------------------------------
  listarProveedores: ({ buscar, incluirInactivos } = {}) => {
    const p = new URLSearchParams()
    if (buscar) p.set('buscar', buscar)
    if (incluirInactivos) p.set('incluir_inactivos', 'true')
    const cadena = p.toString()
    return pedir(cadena ? `/proveedores?${cadena}` : '/proveedores')
  },
  crearProveedor: (datos) => pedir('/proveedores', { method: 'POST', ...cuerpo(datos) }),
  actualizarProveedor: (id, datos) =>
    pedir(`/proveedores/${id}`, { method: 'PUT', ...cuerpo(datos) }),
  desactivarProveedor: (id) => pedir(`/proveedores/${id}`, { method: 'DELETE' }),
  reactivarProveedor: (id) => pedir(`/proveedores/${id}/reactivar`, { method: 'POST' }),

  // --- Compras (solo ADMIN) -------------------------------------------------
  listarCompras: ({ proveedorId, estado, desde, hasta } = {}) => {
    const p = new URLSearchParams()
    if (proveedorId) p.set('proveedor_id', proveedorId)
    if (estado) p.set('estado', estado)
    if (desde) p.set('desde', desde)
    if (hasta) p.set('hasta', hasta)
    const cadena = p.toString()
    return pedir(cadena ? `/compras?${cadena}` : '/compras')
  },
  verCompra: (id) => pedir(`/compras/${id}`),
  crearCompra: (datos) => pedir('/compras', { method: 'POST', ...cuerpo(datos) }),
  anularCompra: (id, motivo) =>
    pedir(`/compras/${id}/anular`, { method: 'POST', ...cuerpo({ motivo }) }),

  // --- Clientes -------------------------------------------------------------
  listarClientes: (buscar) =>
    pedir(buscar ? `/clientes?buscar=${encodeURIComponent(buscar)}` : '/clientes'),
  crearCliente: (datos) => pedir('/clientes', { method: 'POST', ...cuerpo(datos) }),

  // --- Ventas ---------------------------------------------------------------
  // El cajero registra; el admin consulta. El backend filtra por rol:
  // un cajero solo recibe sus propias ventas aunque pida las de otro.
  listarVentas: ({ usuarioId, estado, desde, hasta } = {}) => {
    const p = new URLSearchParams()
    if (usuarioId) p.set('usuario_id', usuarioId)
    if (estado) p.set('estado', estado)
    if (desde) p.set('desde', desde)
    if (hasta) p.set('hasta', hasta)
    const cadena = p.toString()
    return pedir(cadena ? `/ventas?${cadena}` : '/ventas')
  },
  resumenVentas: ({ desde, hasta } = {}) => {
    const p = new URLSearchParams()
    if (desde) p.set('desde', desde)
    if (hasta) p.set('hasta', hasta)
    const cadena = p.toString()
    return pedir(cadena ? `/ventas/resumen?${cadena}` : '/ventas/resumen')
  },
  ventasPorCajero: ({ desde, hasta } = {}) => {
    const p = new URLSearchParams()
    if (desde) p.set('desde', desde)
    if (hasta) p.set('hasta', hasta)
    const cadena = p.toString()
    return pedir(cadena ? `/ventas/por-cajero?${cadena}` : '/ventas/por-cajero')
  },
  verVenta: (id) => pedir(`/ventas/${id}`),
  crearVenta: (datos) => pedir('/ventas', { method: 'POST', ...cuerpo(datos) }),
  anularVenta: (id, motivo) =>
    pedir(`/ventas/${id}/anular`, { method: 'POST', ...cuerpo({ motivo }) }),

  // --- Usuarios (solo ADMIN) -------------------------------------------------
  listarUsuarios: ({ buscar, incluirInactivos } = {}) => {
    const p = new URLSearchParams()
    if (buscar) p.set('buscar', buscar)
    if (incluirInactivos) p.set('incluir_inactivos', 'true')
    const cadena = p.toString()
    return pedir(cadena ? `/usuarios?${cadena}` : '/usuarios')
  },
  crearUsuario: (datos) => pedir('/usuarios', { method: 'POST', ...cuerpo(datos) }),
  actualizarUsuario: (id, datos) =>
    pedir(`/usuarios/${id}`, { method: 'PUT', ...cuerpo(datos) }),
  desactivarUsuario: (id) => pedir(`/usuarios/${id}`, { method: 'DELETE' }),
  reactivarUsuario: (id) => pedir(`/usuarios/${id}/reactivar`, { method: 'POST' }),
  resetearPasswordUsuario: (id) =>
    pedir(`/usuarios/${id}/resetear-password`, { method: 'POST' }),

  // --- Perfil propio ----------------------------------------------------------
  verPerfil: () => pedir('/perfil/yo'),
  actualizarPerfil: (datos) => pedir('/perfil/yo', { method: 'PUT', ...cuerpo(datos) }),
  subirFotoPerfil: (archivo) => {
    const formData = new FormData()
    formData.append('archivo', archivo)
    return pedirFormData('/perfil/foto', formData)
  },
  cambiarPassword: (datos) =>
    pedir('/perfil/cambiar-password', { method: 'POST', ...cuerpo(datos) }),
}

// foto_url llega como ruta relativa ("/static/fotos/...") cuando la sirve
// este mismo backend, o como URL completa si el dia de manana se migra a
// Cloud Storage. Esta funcion sirve para los dos casos.
export const urlFoto = (fotoUrl) => {
  if (!fotoUrl) return null
  return fotoUrl.startsWith('http') ? fotoUrl : `${BASE}${fotoUrl}`
}

export const pesos = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0,
})

/**
 * Mismo desglose de IVA que hace el backend, para la vista previa en pantalla.
 *
 * incluyeIva = true: el precio YA trae el impuesto y hay que sacarlo de
 * adentro (1200 = 1008 de base + 192 de IVA).
 * incluyeIva = false: el precio es la base y el IVA se suma encima.
 *
 * El IVA se obtiene restando, no multiplicando, para que subtotal + iva dé
 * exactamente el total y la factura no se descuadre por un peso.
 */
export function desglosarIva(precio, cantidad, ivaPct, incluyeIva) {
  const bruto = Math.round(Number(precio) * Number(cantidad) * 100) / 100
  const tasa = Number(ivaPct) / 100

  if (incluyeIva) {
    const subtotal = Math.round((bruto / (1 + tasa)) * 100) / 100
    return { subtotal, iva: bruto - subtotal, total: bruto }
  }
  const iva = Math.round(bruto * tasa * 100) / 100
  return { subtotal: bruto, iva, total: bruto + iva }
}
