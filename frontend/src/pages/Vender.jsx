import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { api, pesos } from '../api.js'

const METODOS = ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'MIXTO']

export default function Vender() {
  const [productos, setProductos] = useState([])
  const [clientes, setClientes] = useState([])

  const [texto, setTexto] = useState('')
  const [carrito, setCarrito] = useState([])
  const [clienteId, setClienteId] = useState('')
  const [metodoPago, setMetodoPago] = useState('EFECTIVO')
  const [observaciones, setObservaciones] = useState('')
  const [recibido, setRecibido] = useState('')

  const [error, setError] = useState('')
  const [cobrando, setCobrando] = useState(false)
  const [comprobante, setComprobante] = useState(null)

  const buscador = useRef(null)

  const cargar = useCallback(async () => {
    try {
      const [prods, clis] = await Promise.all([
        api.listarProductos(),
        api.listarClientes(),
      ])
      setProductos(prods)
      setClientes(clis)
    } catch (e) {
      setError(e.message)
    }
  }, [])

  useEffect(() => {
    cargar()
  }, [cargar])

  // --- Búsqueda de productos --------------------------------------------------
  const coincidencias = useMemo(() => {
    const q = texto.trim().toLowerCase()
    if (!q) return []
    return productos
      .filter(
        (p) =>
          p.sku.toLowerCase().includes(q) || p.nombre.toLowerCase().includes(q),
      )
      .slice(0, 8)
  }, [texto, productos])

  function agregar(producto) {
    if (producto.stock_actual <= 0) {
      setError(`${producto.nombre} está sin stock.`)
      return
    }
    setError('')
    setCarrito((c) => {
      const existente = c.find((l) => l.producto.id === producto.id)
      if (existente) {
        if (existente.cantidad >= producto.stock_actual) {
          setError(
            `Solo hay ${producto.stock_actual} de ${producto.nombre} en stock.`,
          )
          return c
        }
        return c.map((l) =>
          l.producto.id === producto.id ? { ...l, cantidad: l.cantidad + 1 } : l,
        )
      }
      return [...c, { producto, cantidad: 1 }]
    })
    setTexto('')
    buscador.current?.focus()
  }

  function cambiarCantidad(productoId, cantidad) {
    setCarrito((c) =>
      c.map((l) => {
        if (l.producto.id !== productoId) return l
        const n = Math.max(1, Math.min(Number(cantidad) || 1, l.producto.stock_actual))
        return { ...l, cantidad: n }
      }),
    )
  }

  function quitar(productoId) {
    setCarrito((c) => c.filter((l) => l.producto.id !== productoId))
  }

  function limpiar() {
    setCarrito([])
    setClienteId('')
    setMetodoPago('EFECTIVO')
    setObservaciones('')
    setRecibido('')
    setError('')
  }

  // Enter en el buscador agrega el primer resultado: así se vende sin soltar
  // el teclado, que es como se usa un mostrador de verdad.
  function teclaBuscador(evento) {
    if (evento.key === 'Enter') {
      evento.preventDefault()
      if (coincidencias.length > 0) agregar(coincidencias[0])
    }
  }

  // --- Totales ----------------------------------------------------------------
  const totales = useMemo(() => {
    let subtotal = 0
    let iva = 0
    for (const l of carrito) {
      const sub = Number(l.producto.precio_venta) * l.cantidad
      subtotal += sub
      iva += (sub * Number(l.producto.iva_pct)) / 100
    }
    return { subtotal, iva, total: subtotal + iva }
  }, [carrito])

  const cambio =
    metodoPago === 'EFECTIVO' && recibido !== ''
      ? Number(recibido) - totales.total
      : null

  // --- Cobrar -----------------------------------------------------------------
  async function cobrar() {
    if (carrito.length === 0) return
    setCobrando(true)
    setError('')
    try {
      const venta = await api.crearVenta({
        cliente_id: clienteId ? Number(clienteId) : null,
        metodo_pago: metodoPago,
        observaciones: observaciones.trim() || null,
        items: carrito.map((l) => ({
          producto_id: l.producto.id,
          cantidad: l.cantidad,
        })),
      })
      setComprobante({ venta, recibido: recibido ? Number(recibido) : null })
      limpiar()
      cargar() // el stock cambió
    } catch (e) {
      setError(e.message)
    } finally {
      setCobrando(false)
    }
  }

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Vender</h2>
          <p className="sutil">Busca por nombre o SKU y presiona Enter para agregar</p>
        </div>
        {carrito.length > 0 && (
          <button className="btn btn-suave" onClick={limpiar}>
            Vaciar venta
          </button>
        )}
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}

      <div className="pos">
        {/* ---------- Izquierda: buscador y carrito ---------- */}
        <div className="pos-principal">
          <div className="pos-buscador">
            <input
              ref={buscador}
              type="search"
              autoFocus
              placeholder="Buscar producto…"
              value={texto}
              onChange={(e) => setTexto(e.target.value)}
              onKeyDown={teclaBuscador}
            />
            {coincidencias.length > 0 && (
              <ul className="sugerencias">
                {coincidencias.map((p, i) => (
                  <li key={p.id}>
                    <button
                      type="button"
                      className={i === 0 ? 'sugerencia primera' : 'sugerencia'}
                      onClick={() => agregar(p)}
                      disabled={p.stock_actual <= 0}
                    >
                      <span className="mono">{p.sku}</span>
                      <span className="sug-nombre">{p.nombre}</span>
                      <span className="sug-stock">
                        {p.stock_actual > 0 ? `${p.stock_actual} disp.` : 'sin stock'}
                      </span>
                      <strong>{pesos.format(Number(p.precio_venta))}</strong>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="tabla-envoltura">
            <table>
              <thead>
                <tr>
                  <th>Producto</th>
                  <th className="derecha">Precio</th>
                  <th className="centro">Cantidad</th>
                  <th className="derecha">Subtotal</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {carrito.map((l) => (
                  <tr key={l.producto.id}>
                    <td>
                      <strong>{l.producto.nombre}</strong>
                      <div className="sutil mono">{l.producto.sku}</div>
                    </td>
                    <td className="derecha">
                      {pesos.format(Number(l.producto.precio_venta))}
                      <div className="sutil">IVA {Number(l.producto.iva_pct)}%</div>
                    </td>
                    <td className="centro">
                      <div className="control-stock">
                        <button
                          className="btn-mini"
                          onClick={() => cambiarCantidad(l.producto.id, l.cantidad - 1)}
                        >
                          −
                        </button>
                        <input
                          className="cantidad-pos"
                          type="number"
                          min="1"
                          max={l.producto.stock_actual}
                          value={l.cantidad}
                          onChange={(e) =>
                            cambiarCantidad(l.producto.id, e.target.value)
                          }
                        />
                        <button
                          className="btn-mini"
                          onClick={() => cambiarCantidad(l.producto.id, l.cantidad + 1)}
                        >
                          +
                        </button>
                      </div>
                      <div className="sutil">de {l.producto.stock_actual}</div>
                    </td>
                    <td className="derecha">
                      <strong>
                        {pesos.format(Number(l.producto.precio_venta) * l.cantidad)}
                      </strong>
                    </td>
                    <td className="derecha">
                      <button
                        className="btn-mini"
                        title="Quitar"
                        onClick={() => quitar(l.producto.id)}
                      >
                        ×
                      </button>
                    </td>
                  </tr>
                ))}

                {carrito.length === 0 && (
                  <tr>
                    <td colSpan="5" className="celda-vacia">
                      La venta está vacía. Busca un producto arriba.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* ---------- Derecha: cobro ---------- */}
        <aside className="pos-cobro">
          <div className="tarjeta">
            <label className="campo">
              <span>Cliente (opcional)</span>
              <select value={clienteId} onChange={(e) => setClienteId(e.target.value)}>
                <option value="">Consumidor final</option>
                {clientes.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.nombre} · {c.num_doc}
                  </option>
                ))}
              </select>
            </label>

            <label className="campo">
              <span>Método de pago</span>
              <select
                value={metodoPago}
                onChange={(e) => setMetodoPago(e.target.value)}
              >
                {METODOS.map((m) => (
                  <option key={m} value={m}>
                    {m}
                  </option>
                ))}
              </select>
            </label>

            {metodoPago === 'EFECTIVO' && (
              <label className="campo">
                <span>Recibe</span>
                <input
                  type="number"
                  min="0"
                  step="50"
                  placeholder="0"
                  value={recibido}
                  onChange={(e) => setRecibido(e.target.value)}
                />
              </label>
            )}

            <label className="campo">
              <span>Observaciones</span>
              <input
                placeholder="Opcional"
                value={observaciones}
                onChange={(e) => setObservaciones(e.target.value)}
              />
            </label>

            <div className="cobro-totales">
              <div>
                <span className="sutil">Subtotal</span>
                <strong>{pesos.format(totales.subtotal)}</strong>
              </div>
              <div>
                <span className="sutil">IVA</span>
                <strong>{pesos.format(totales.iva)}</strong>
              </div>
              <div className="cobro-total">
                <span>Total</span>
                <strong>{pesos.format(totales.total)}</strong>
              </div>
              {cambio !== null && (
                <div className={cambio < 0 ? 'cobro-cambio falta' : 'cobro-cambio'}>
                  <span className="sutil">{cambio < 0 ? 'Faltan' : 'Cambio'}</span>
                  <strong>{pesos.format(Math.abs(cambio))}</strong>
                </div>
              )}
            </div>

            <button
              className="btn btn-primario btn-ancho btn-cobrar"
              disabled={carrito.length === 0 || cobrando}
              onClick={cobrar}
            >
              {cobrando ? 'Registrando…' : 'Cobrar'}
            </button>

            <p className="nota">
              Los totales definitivos los calcula el backend con el precio y el IVA
              que tenga cada producto al momento de guardar.
            </p>
          </div>
        </aside>
      </div>

      {/* ---------- Comprobante ---------- */}
      {comprobante && (
        <div className="fondo-modal" onClick={() => setComprobante(null)}>
          <div className="modal modal-angosto" onClick={(e) => e.stopPropagation()}>
            <div className="recibo-cabeza">
              <span className="etiqueta verde">Venta registrada</span>
              <h3>{comprobante.venta.numero}</h3>
              <p className="sutil">
                {comprobante.venta.cliente?.nombre || 'Consumidor final'} ·{' '}
                {comprobante.venta.metodo_pago}
              </p>
            </div>

            <table className="tabla-lineas">
              <tbody>
                {comprobante.venta.items.map((it) => (
                  <tr key={it.id}>
                    <td>
                      {Number(it.cantidad)} × {it.producto.nombre}
                    </td>
                    <td className="derecha">
                      {pesos.format(Number(it.total_linea))}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="cobro-totales">
              <div>
                <span className="sutil">Subtotal</span>
                <strong>{pesos.format(Number(comprobante.venta.subtotal))}</strong>
              </div>
              <div>
                <span className="sutil">IVA</span>
                <strong>{pesos.format(Number(comprobante.venta.total_iva))}</strong>
              </div>
              <div className="cobro-total">
                <span>Total</span>
                <strong>{pesos.format(Number(comprobante.venta.total))}</strong>
              </div>
              {comprobante.recibido !== null && (
                <div className="cobro-cambio">
                  <span className="sutil">Cambio</span>
                  <strong>
                    {pesos.format(
                      comprobante.recibido - Number(comprobante.venta.total),
                    )}
                  </strong>
                </div>
              )}
            </div>

            <div className="modal-pie">
              <button
                className="btn btn-primario"
                onClick={() => {
                  setComprobante(null)
                  buscador.current?.focus()
                }}
              >
                Nueva venta
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  )
}
