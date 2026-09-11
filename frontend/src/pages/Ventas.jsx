import { useCallback, useEffect, useState } from 'react'
import { api, pesos } from '../api.js'
import { useAuth } from '../auth.jsx'

const fechaHora = new Intl.DateTimeFormat('es-CO', {
  day: '2-digit',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
})

function formatear(valor) {
  const d = new Date(valor)
  return Number.isNaN(d.getTime()) ? '—' : fechaHora.format(d)
}

function hoyMenos(dias) {
  const d = new Date()
  d.setDate(d.getDate() - dias)
  return d.toISOString().slice(0, 10)
}

export default function Ventas() {
  const { usuario } = useAuth()
  const esAdmin = usuario?.rol === 'ADMIN'

  const [ventas, setVentas] = useState([])
  const [resumen, setResumen] = useState(null)
  const [porCajero, setPorCajero] = useState([])

  const [desde, setDesde] = useState(hoyMenos(30))
  const [hasta, setHasta] = useState(hoyMenos(0))
  const [filtroCajero, setFiltroCajero] = useState('')
  const [filtroEstado, setFiltroEstado] = useState('')

  const [detalle, setDetalle] = useState(null)
  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)

  const cargar = useCallback(async () => {
    setCargando(true)
    try {
      const peticiones = [
        api.listarVentas({
          usuarioId: filtroCajero || undefined,
          estado: filtroEstado || undefined,
          desde,
          hasta,
        }),
        api.resumenVentas({ desde, hasta }),
      ]
      if (esAdmin) peticiones.push(api.ventasPorCajero({ desde, hasta }))

      const [lista, res, cajeros] = await Promise.all(peticiones)
      setVentas(lista)
      setResumen(res)
      if (esAdmin) setPorCajero(cajeros || [])
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }, [desde, hasta, filtroCajero, filtroEstado, esAdmin])

  useEffect(() => {
    cargar()
  }, [cargar])

  async function verDetalle(id) {
    try {
      setDetalle(await api.verVenta(id))
    } catch (e) {
      setError(e.message)
    }
  }

  async function anular(venta) {
    const motivo = window.prompt(
      `Anular la venta ${venta.numero}. La mercancía vuelve al stock.\n\n¿Motivo? (mínimo 3 caracteres)`,
      '',
    )
    if (motivo === null) return
    if (motivo.trim().length < 3) {
      setError('El motivo de anulación es obligatorio.')
      return
    }
    try {
      await api.anularVenta(venta.id, motivo.trim())
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
          <h2>{esAdmin ? 'Ventas' : 'Mis ventas'}</h2>
          <p className="sutil">
            {esAdmin
              ? 'Todas las ventas registradas por los cajeros'
              : 'Las ventas que has registrado tú'}
          </p>
        </div>
      </div>

      {resumen && (
        <div className="tarjetas-resumen">
          <div className="tarjeta-dato">
            <span className="dato-etiqueta">Ventas pagadas</span>
            <strong className="dato-valor">{resumen.ventas}</strong>
          </div>
          <div className="tarjeta-dato">
            <span className="dato-etiqueta">Total vendido</span>
            <strong className="dato-valor">{pesos.format(Number(resumen.total))}</strong>
          </div>
          <div className="tarjeta-dato">
            <span className="dato-etiqueta">Ticket promedio</span>
            <strong className="dato-valor">
              {pesos.format(Number(resumen.promedio))}
            </strong>
          </div>
          <div className={`tarjeta-dato ${resumen.anuladas ? 'alerta' : ''}`}>
            <span className="dato-etiqueta">Anuladas</span>
            <strong className="dato-valor">{resumen.anuladas}</strong>
          </div>
        </div>
      )}

      {error && <p className="aviso aviso-error">{error}</p>}

      <div className="barra-filtros">
        <label className="campo-inline">
          <span className="sutil">Desde</span>
          <input type="date" value={desde} onChange={(e) => setDesde(e.target.value)} />
        </label>
        <label className="campo-inline">
          <span className="sutil">Hasta</span>
          <input type="date" value={hasta} onChange={(e) => setHasta(e.target.value)} />
        </label>

        {esAdmin && (
          <select
            value={filtroCajero}
            onChange={(e) => setFiltroCajero(e.target.value)}
          >
            <option value="">Todos los cajeros</option>
            {porCajero.map((c) => (
              <option key={c.usuario_id} value={c.usuario_id}>
                {c.nombre}
              </option>
            ))}
          </select>
        )}

        <select value={filtroEstado} onChange={(e) => setFiltroEstado(e.target.value)}>
          <option value="">Todos los estados</option>
          <option value="PAGADA">Pagadas</option>
          <option value="ANULADA">Anuladas</option>
        </select>
      </div>

      {esAdmin && porCajero.length > 0 && (
        <div className="panel-cajeros">
          {porCajero.map((c) => (
            <div key={c.usuario_id} className="tarjeta-dato">
              <span className="dato-etiqueta">{c.nombre}</span>
              <strong className="dato-valor">{pesos.format(Number(c.total))}</strong>
              <span className="sutil">{c.ventas} venta(s)</span>
            </div>
          ))}
        </div>
      )}

      <div className="tabla-envoltura">
        <table>
          <thead>
            <tr>
              <th>Número</th>
              <th>Fecha</th>
              {esAdmin && <th>Cajero</th>}
              <th>Cliente</th>
              <th className="centro">Pago</th>
              <th className="derecha">Total</th>
              <th className="centro">Estado</th>
              <th className="derecha">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {cargando && (
              <tr>
                <td colSpan={esAdmin ? 8 : 7} className="celda-vacia">
                  Cargando…
                </td>
              </tr>
            )}

            {!cargando &&
              ventas.map((v) => (
                <tr key={v.id} className={v.estado === 'ANULADA' ? 'fila-inactiva' : ''}>
                  <td className="mono">{v.numero}</td>
                  <td className="sutil">{formatear(v.fecha)}</td>
                  {esAdmin && <td>{v.usuario?.nombre || '—'}</td>}
                  <td className="sutil">{v.cliente?.nombre || 'Consumidor final'}</td>
                  <td className="centro">
                    <span className="etiqueta">{v.metodo_pago}</span>
                  </td>
                  <td className="derecha">
                    <strong>{pesos.format(Number(v.total))}</strong>
                  </td>
                  <td className="centro">
                    <span
                      className={
                        v.estado === 'ANULADA' ? 'etiqueta gris' : 'etiqueta verde'
                      }
                    >
                      {v.estado}
                    </span>
                  </td>
                  <td className="derecha acciones">
                    <button className="btn btn-suave" onClick={() => verDetalle(v.id)}>
                      Ver
                    </button>
                    {esAdmin && v.estado === 'PAGADA' && (
                      <button className="btn btn-peligro" onClick={() => anular(v)}>
                        Anular
                      </button>
                    )}
                  </td>
                </tr>
              ))}

            {!cargando && ventas.length === 0 && (
              <tr>
                <td colSpan={esAdmin ? 8 : 7} className="celda-vacia">
                  No hay ventas en ese rango de fechas.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {detalle && (
        <div className="fondo-modal" onClick={() => setDetalle(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h3>Venta {detalle.numero}</h3>
            <p className="sutil">
              {formatear(detalle.fecha)} · {detalle.metodo_pago} ·{' '}
              {detalle.cliente?.nombre || 'Consumidor final'} · atendió{' '}
              {detalle.usuario?.nombre || '—'} ·{' '}
              <span
                className={
                  detalle.estado === 'ANULADA' ? 'etiqueta gris' : 'etiqueta verde'
                }
              >
                {detalle.estado}
              </span>
            </p>

            {detalle.estado === 'ANULADA' && (
              <p className="aviso">
                Anulada el {formatear(detalle.anulada_en)}. Motivo: {detalle.motivo_anula}
              </p>
            )}

            <div className="tabla-envoltura" style={{ marginTop: 16 }}>
              <table>
                <thead>
                  <tr>
                    <th>SKU</th>
                    <th>Producto</th>
                    <th className="centro">Cant.</th>
                    <th className="derecha">Precio</th>
                    <th className="derecha">IVA</th>
                    <th className="derecha">Total</th>
                  </tr>
                </thead>
                <tbody>
                  {detalle.items.map((it) => (
                    <tr key={it.id}>
                      <td className="mono">{it.producto.sku}</td>
                      <td>{it.producto.nombre}</td>
                      <td className="centro">{Number(it.cantidad)}</td>
                      <td className="derecha">
                        {pesos.format(Number(it.precio_unitario))}
                      </td>
                      <td className="derecha sutil">
                        {Number(it.iva_pct)}% · {pesos.format(Number(it.iva_linea))}
                      </td>
                      <td className="derecha">{pesos.format(Number(it.total_linea))}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <p className="nota">
              El precio y el IVA de cada línea quedaron congelados al momento de la
              venta: aunque el producto cambie de precio, este comprobante no se mueve.
            </p>

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
              {esAdmin && detalle.estado === 'PAGADA' && (
                <button className="btn btn-peligro" onClick={() => anular(detalle)}>
                  Anular venta
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
