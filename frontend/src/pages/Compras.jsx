import { useCallback, useEffect, useMemo, useState } from 'react'
import { api, desglosarIva, pesos } from '../api.js'
import { useAuth } from '../auth.jsx'

const fechaCorta = new Intl.DateTimeFormat('es-CO', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
})

function formatearFecha(valor) {
  const d = new Date(valor)
  return Number.isNaN(d.getTime()) ? '—' : fechaCorta.format(d)
}

export default function Compras() {
  const { usuario } = useAuth()
  const esAdmin = usuario?.rol === 'ADMIN'

  const [compras, setCompras] = useState([])
  const [proveedores, setProveedores] = useState([])
  const [productos, setProductos] = useState([])

  const [filtroProveedor, setFiltroProveedor] = useState('')
  const [filtroEstado, setFiltroEstado] = useState('')

  const [panelAbierto, setPanelAbierto] = useState(false)
  const [proveedorId, setProveedorId] = useState('')
  const [numeroFactura, setNumeroFactura] = useState('')
  const [lineas, setLineas] = useState([])
  // Sin marcar: el costo del proveedor es la base. Es lo más común entre
  // empresas, por eso arranca en false.
  const [costoIncluyeIva, setCostoIncluyeIva] = useState(false)

  const [detalle, setDetalle] = useState(null)
  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)
  const [guardando, setGuardando] = useState(false)

  const cargar = useCallback(async () => {
    setCargando(true)
    try {
      const [listaCompras, listaProv, listaProd] = await Promise.all([
        api.listarCompras({
          proveedorId: filtroProveedor || undefined,
          estado: filtroEstado || undefined,
        }),
        api.listarProveedores(),
        api.listarProductos(),
      ])
      setCompras(listaCompras)
      setProveedores(listaProv)
      setProductos(listaProd)
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }, [filtroProveedor, filtroEstado])

  useEffect(() => {
    cargar()
  }, [cargar])

  const resumen = useMemo(() => {
    const recibidas = compras.filter((c) => c.estado === 'RECIBIDA')
    return {
      cantidad: recibidas.length,
      total: recibidas.reduce((s, c) => s + Number(c.total), 0),
      anuladas: compras.length - recibidas.length,
    }
  }, [compras])

  // --- Formulario de compra ---------------------------------------------------
  function abrirNueva() {
    if (proveedores.length === 0) {
      setError('Primero registra un proveedor.')
      return
    }
    setProveedorId(String(proveedores[0].id))
    setNumeroFactura('')
    setCostoIncluyeIva(false)
    setLineas([{ producto_id: '', cantidad: '1', costo_unitario: '' }])
    setPanelAbierto(true)
    setError('')
  }

  function cerrarPanel() {
    setPanelAbierto(false)
    setLineas([])
  }

  function agregarLinea() {
    setLineas((l) => [...l, { producto_id: '', cantidad: '1', costo_unitario: '' }])
  }

  function quitarLinea(indice) {
    setLineas((l) => l.filter((_, i) => i !== indice))
  }

  function cambiarLinea(indice, campo, valor) {
    setLineas((l) =>
      l.map((linea, i) => {
        if (i !== indice) return linea
        const actualizada = { ...linea, [campo]: valor }
        // Al elegir producto, propone su costo actual como punto de partida.
        if (campo === 'producto_id') {
          const p = productos.find((x) => String(x.id) === String(valor))
          if (p && !linea.costo_unitario) {
            actualizada.costo_unitario = String(p.costo)
          }
        }
        return actualizada
      }),
    )
  }

  const totales = useMemo(() => {
    let subtotal = 0
    let iva = 0
    let total = 0
    for (const linea of lineas) {
      const producto = productos.find((p) => String(p.id) === String(linea.producto_id))
      if (!producto) continue
      const d = desglosarIva(
        linea.costo_unitario || 0,
        linea.cantidad || 0,
        producto.iva_pct,
        costoIncluyeIva,
      )
      subtotal += d.subtotal
      iva += d.iva
      total += d.total
    }
    return { subtotal, iva, total }
  }, [lineas, productos, costoIncluyeIva])

  async function guardar(evento) {
    evento.preventDefault()
    const items = lineas
      .filter((l) => l.producto_id && Number(l.cantidad) > 0)
      .map((l) => ({
        producto_id: Number(l.producto_id),
        cantidad: Number(l.cantidad),
        costo_unitario: Number(l.costo_unitario || 0),
      }))

    if (items.length === 0) {
      setError('Agrega al menos un producto con cantidad mayor a cero.')
      return
    }

    setGuardando(true)
    try {
      await api.crearCompra({
        proveedor_id: Number(proveedorId),
        numero_factura: numeroFactura.trim(),
        costo_incluye_iva: costoIncluyeIva,
        items,
      })
      cerrarPanel()
      cargar()
    } catch (e) {
      setError(e.message)
    } finally {
      setGuardando(false)
    }
  }

  // --- Detalle y anulación ----------------------------------------------------
  async function verDetalle(id) {
    try {
      setDetalle(await api.verCompra(id))
    } catch (e) {
      setError(e.message)
    }
  }

  async function anular(compra) {
    const motivo = window.prompt(
      `Anular la compra ${compra.numero_factura}. El stock que entró se devuelve.\n\n¿Motivo?`,
      '',
    )
    if (motivo === null) return
    try {
      await api.anularCompra(compra.id, motivo || null)
      setDetalle(null)
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Compras</h2>
          <p className="sutil">
            {esAdmin
              ? 'Registrar una compra suma el stock y deja el movimiento en el kardex'
              : 'Consulta de las compras registradas por administración'}
          </p>
        </div>
        {esAdmin && (
          <button className="btn btn-primario" onClick={abrirNueva}>
            + Registrar compra
          </button>
        )}
      </div>

      <div className="tarjetas-resumen">
        <div className="tarjeta-dato">
          <span className="dato-etiqueta">Compras recibidas</span>
          <strong className="dato-valor">{resumen.cantidad}</strong>
        </div>
        <div className="tarjeta-dato">
          <span className="dato-etiqueta">Total comprado</span>
          <strong className="dato-valor">{pesos.format(resumen.total)}</strong>
        </div>
        <div className={`tarjeta-dato ${resumen.anuladas ? 'alerta' : ''}`}>
          <span className="dato-etiqueta">Anuladas</span>
          <strong className="dato-valor">{resumen.anuladas}</strong>
        </div>
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}

      <div className="barra-filtros">
        <select
          value={filtroProveedor}
          onChange={(e) => setFiltroProveedor(e.target.value)}
        >
          <option value="">Todos los proveedores</option>
          {proveedores.map((p) => (
            <option key={p.id} value={p.id}>
              {p.nombre}
            </option>
          ))}
        </select>
        <select value={filtroEstado} onChange={(e) => setFiltroEstado(e.target.value)}>
          <option value="">Todos los estados</option>
          <option value="RECIBIDA">Recibidas</option>
          <option value="ANULADA">Anuladas</option>
        </select>
      </div>

      <div className="tabla-envoltura">
        <table>
          <thead>
            <tr>
              <th>Factura</th>
              <th>Proveedor</th>
              <th>Fecha</th>
              <th className="derecha">Subtotal</th>
              <th className="derecha">IVA</th>
              <th className="derecha">Total</th>
              <th className="centro">Estado</th>
              <th className="derecha">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {cargando && (
              <tr>
                <td colSpan="8" className="celda-vacia">
                  Cargando…
                </td>
              </tr>
            )}

            {!cargando &&
              compras.map((c) => (
                <tr key={c.id} className={c.estado === 'ANULADA' ? 'fila-inactiva' : ''}>
                  <td className="mono">{c.numero_factura}</td>
                  <td>{c.proveedor.nombre}</td>
                  <td className="sutil">{formatearFecha(c.fecha)}</td>
                  <td className="derecha sutil">{pesos.format(Number(c.subtotal))}</td>
                  <td className="derecha sutil">{pesos.format(Number(c.total_iva))}</td>
                  <td className="derecha">
                    <strong>{pesos.format(Number(c.total))}</strong>
                  </td>
                  <td className="centro">
                    <span
                      className={
                        c.estado === 'ANULADA' ? 'etiqueta gris' : 'etiqueta verde'
                      }
                    >
                      {c.estado}
                    </span>
                  </td>
                  <td className="derecha acciones">
                    <button className="btn btn-suave" onClick={() => verDetalle(c.id)}>
                      Ver
                    </button>
                    {esAdmin && c.estado === 'RECIBIDA' && (
                      <button className="btn btn-peligro" onClick={() => anular(c)}>
                        Anular
                      </button>
                    )}
                  </td>
                </tr>
              ))}

            {!cargando && compras.length === 0 && (
              <tr>
                <td colSpan="8" className="celda-vacia">
                  Todavía no hay compras registradas.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* ---------- Registrar compra ---------- */}
      {panelAbierto && (
        <div className="fondo-modal" onClick={cerrarPanel}>
          <form
            className="modal modal-ancho"
            onClick={(e) => e.stopPropagation()}
            onSubmit={guardar}
          >
            <h3>Registrar compra</h3>

            <div className="rejilla-form">
              <label className="campo campo-ancho">
                <span>Proveedor</span>
                <select
                  required
                  value={proveedorId}
                  onChange={(e) => setProveedorId(e.target.value)}
                >
                  {proveedores.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.nombre} ({p.nit})
                    </option>
                  ))}
                </select>
              </label>

              <label className="campo">
                <span>Número de factura</span>
                <input
                  required
                  maxLength={40}
                  className="mono-entrada"
                  placeholder="FV-1024"
                  value={numeroFactura}
                  onChange={(e) => setNumeroFactura(e.target.value.toUpperCase())}
                />
              </label>
            </div>

            <div className="caja-iva">
              <label className="check">
                <input
                  type="checkbox"
                  checked={costoIncluyeIva}
                  onChange={(e) => setCostoIncluyeIva(e.target.checked)}
                />
                Los costos de esta factura ya incluyen IVA
              </label>
              <p className="sutil">
                {costoIncluyeIva
                  ? 'Se guardará la base sin impuesto: el IVA de compra es descontable y no hace parte del valor del inventario.'
                  : 'El costo es la base y el IVA se calcula encima.'}
              </p>
            </div>

            <div className="lineas-compra">
              <div className="lineas-titulo">
                <strong>Productos</strong>
                <button type="button" className="btn btn-suave" onClick={agregarLinea}>
                  + Agregar línea
                </button>
              </div>

              <table className="tabla-lineas">
                <thead>
                  <tr>
                    <th>Producto</th>
                    <th className="centro">Cantidad</th>
                    <th className="derecha">Costo unitario</th>
                    <th className="derecha">Subtotal</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {lineas.map((linea, i) => {
                    const producto = productos.find(
                      (p) => String(p.id) === String(linea.producto_id),
                    )
                    const sub = producto
                      ? desglosarIva(
                          linea.costo_unitario || 0,
                          linea.cantidad || 0,
                          producto.iva_pct,
                          costoIncluyeIva,
                        ).total
                      : 0
                    return (
                      <tr key={i}>
                        <td>
                          <select
                            value={linea.producto_id}
                            onChange={(e) =>
                              cambiarLinea(i, 'producto_id', e.target.value)
                            }
                          >
                            <option value="">Elige un producto…</option>
                            {productos.map((p) => (
                              <option key={p.id} value={p.id}>
                                {p.sku} · {p.nombre}
                              </option>
                            ))}
                          </select>
                          {producto && (
                            <small className="sutil">
                              Stock actual: {producto.stock_actual} {producto.unidad_medida}
                              {' · IVA '}
                              {Number(producto.iva_pct)}%
                            </small>
                          )}
                        </td>
                        <td className="centro">
                          <input
                            type="number"
                            min="1"
                            step="1"
                            value={linea.cantidad}
                            onChange={(e) => cambiarLinea(i, 'cantidad', e.target.value)}
                          />
                        </td>
                        <td className="derecha">
                          <input
                            type="number"
                            min="0"
                            step="0.01"
                            value={linea.costo_unitario}
                            onChange={(e) =>
                              cambiarLinea(i, 'costo_unitario', e.target.value)
                            }
                          />
                        </td>
                        <td className="derecha">{pesos.format(sub)}</td>
                        <td className="derecha">
                          {lineas.length > 1 && (
                            <button
                              type="button"
                              className="btn-mini"
                              title="Quitar línea"
                              onClick={() => quitarLinea(i)}
                            >
                              ×
                            </button>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>

              <div className="totales">
                <div>
                  <span className="sutil">Subtotal</span>
                  <strong>{pesos.format(totales.subtotal)}</strong>
                </div>
                <div>
                  <span className="sutil">IVA</span>
                  <strong>{pesos.format(totales.iva)}</strong>
                </div>
                <div className="total-grande">
                  <span className="sutil">Total</span>
                  <strong>{pesos.format(totales.total)}</strong>
                </div>
              </div>
              <p className="nota">
                Los totales definitivos los calcula el backend con el IVA guardado en
                cada producto. Esto de arriba es una estimación en pantalla.
              </p>
            </div>

            <div className="modal-pie">
              <button type="button" className="btn btn-suave" onClick={cerrarPanel}>
                Cancelar
              </button>
              <button type="submit" className="btn btn-primario" disabled={guardando}>
                {guardando ? 'Guardando…' : 'Registrar compra'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* ---------- Detalle ---------- */}
      {detalle && (
        <div className="fondo-modal" onClick={() => setDetalle(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h3>Compra {detalle.numero_factura}</h3>
            <p className="sutil">
              {detalle.proveedor.nombre} · NIT {detalle.proveedor.nit} ·{' '}
              {formatearFecha(detalle.fecha)} ·{' '}
              <span
                className={
                  detalle.estado === 'ANULADA' ? 'etiqueta gris' : 'etiqueta verde'
                }
              >
                {detalle.estado}
              </span>
            </p>

            <div className="tabla-envoltura" style={{ marginTop: 16 }}>
              <table>
                <thead>
                  <tr>
                    <th>SKU</th>
                    <th>Producto</th>
                    <th className="centro">Cantidad</th>
                    <th className="derecha">Costo</th>
                    <th className="derecha">Subtotal</th>
                  </tr>
                </thead>
                <tbody>
                  {detalle.items.map((it) => (
                    <tr key={it.id}>
                      <td className="mono">{it.producto.sku}</td>
                      <td>{it.producto.nombre}</td>
                      <td className="centro">
                        {Number(it.cantidad)} {it.producto.unidad_medida}
                      </td>
                      <td className="derecha">{pesos.format(Number(it.costo_unitario))}</td>
                      <td className="derecha">{pesos.format(Number(it.subtotal_linea))}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="totales">
              <div>
                <span className="sutil">Subtotal</span>
                <strong>{pesos.format(Number(detalle.subtotal))}</strong>
              </div>
              <div>
                <span className="sutil">IVA</span>
                <strong>{pesos.format(Number(detalle.total_iva))}</strong>
              </div>
              <div className="total-grande">
                <span className="sutil">Total</span>
                <strong>{pesos.format(Number(detalle.total))}</strong>
              </div>
            </div>

            <div className="modal-pie">
              {esAdmin && detalle.estado === 'RECIBIDA' && (
                <button className="btn btn-peligro" onClick={() => anular(detalle)}>
                  Anular compra
                </button>
              )}
              <button className="btn btn-suave" onClick={() => setDetalle(null)}>
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  )
}
