import { useCallback, useEffect, useMemo, useState } from 'react'
import { api, pesos } from '../api.js'

const UNIDADES = ['UND', 'KG', 'LT', 'MT', 'CAJA', 'PAQ']

const VACIO = {
  sku: '',
  nombre: '',
  descripcion: '',
  precio_venta: '',
  costo: '',
  iva_pct: '19',
  stock_actual: '',
  stock_minimo: '',
  unidad_medida: 'UND',
  categoria_id: '',
}

export default function Productos() {
  const [productos, setProductos] = useState([])
  const [categorias, setCategorias] = useState([])
  const [filtroCategoria, setFiltroCategoria] = useState('')
  const [texto, setTexto] = useState('')
  const [busqueda, setBusqueda] = useState('')
  const [soloStockBajo, setSoloStockBajo] = useState(false)
  const [incluirInactivos, setIncluirInactivos] = useState(false)

  const [formulario, setFormulario] = useState(VACIO)
  const [editandoId, setEditandoId] = useState(null)
  const [panelAbierto, setPanelAbierto] = useState(false)

  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(true)

  // Espera 300 ms después de la última tecla antes de consultar la API.
  useEffect(() => {
    const t = setTimeout(() => setBusqueda(texto), 300)
    return () => clearTimeout(t)
  }, [texto])

  const cargar = useCallback(async () => {
    setCargando(true)
    try {
      const [lista, cats] = await Promise.all([
        api.listarProductos({
          categoriaId: filtroCategoria || undefined,
          buscar: busqueda || undefined,
          soloStockBajo,
          incluirInactivos,
        }),
        api.listarCategorias(true),
      ])
      setProductos(lista)
      setCategorias(cats)
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setCargando(false)
    }
  }, [filtroCategoria, busqueda, soloStockBajo, incluirInactivos])

  useEffect(() => {
    cargar()
  }, [cargar])

  const resumen = useMemo(() => {
    const activos = productos.filter((p) => p.activo)
    return {
      total: productos.length,
      bajos: productos.filter((p) => p.stock_bajo && p.activo).length,
      valorInventario: activos.reduce(
        (suma, p) => suma + Number(p.costo) * p.stock_actual,
        0,
      ),
    }
  }, [productos])

  function abrirNuevo() {
    setFormulario({ ...VACIO, categoria_id: categorias[0]?.id ?? '' })
    setEditandoId(null)
    setPanelAbierto(true)
    setError('')
  }

  function abrirEdicion(p) {
    setFormulario({
      sku: p.sku,
      nombre: p.nombre,
      descripcion: p.descripcion ?? '',
      precio_venta: String(p.precio_venta),
      costo: String(p.costo),
      iva_pct: String(p.iva_pct),
      stock_actual: String(p.stock_actual),
      stock_minimo: String(p.stock_minimo),
      unidad_medida: p.unidad_medida,
      categoria_id: String(p.categoria.id),
    })
    setEditandoId(p.id)
    setPanelAbierto(true)
    setError('')
  }

  function cerrarPanel() {
    setPanelAbierto(false)
    setEditandoId(null)
    setFormulario(VACIO)
  }

  async function guardar(evento) {
    evento.preventDefault()
    const datos = {
      sku: formulario.sku.trim(),
      nombre: formulario.nombre.trim(),
      descripcion: formulario.descripcion.trim() || null,
      precio_venta: Number(formulario.precio_venta),
      costo: Number(formulario.costo || 0),
      iva_pct: Number(formulario.iva_pct || 0),
      stock_actual: Number(formulario.stock_actual || 0),
      stock_minimo: Number(formulario.stock_minimo || 0),
      unidad_medida: formulario.unidad_medida,
      categoria_id: Number(formulario.categoria_id),
    }
    try {
      if (editandoId) {
        await api.actualizarProducto(editandoId, datos)
      } else {
        await api.crearProducto(datos)
      }
      cerrarPanel()
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function ajustar(producto, cantidad) {
    try {
      await api.ajustarStock(producto.id, cantidad)
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  async function alternarActivo(producto) {
    try {
      if (producto.activo) {
        await api.desactivarProducto(producto.id)
      } else {
        await api.reactivarProducto(producto.id)
      }
      cargar()
    } catch (e) {
      setError(e.message)
    }
  }

  const campo = (nombre) => ({
    value: formulario[nombre],
    onChange: (e) => setFormulario({ ...formulario, [nombre]: e.target.value }),
  })

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Productos</h2>
          <p className="sutil">Catálogo e inventario del punto de venta</p>
        </div>
        <button className="btn btn-primario" onClick={abrirNuevo}>
          + Nuevo producto
        </button>
      </div>

      <div className="tarjetas-resumen">
        <div className="tarjeta-dato">
          <span className="dato-etiqueta">Productos listados</span>
          <strong className="dato-valor">{resumen.total}</strong>
        </div>
        <div className={`tarjeta-dato ${resumen.bajos ? 'alerta' : ''}`}>
          <span className="dato-etiqueta">Con stock bajo</span>
          <strong className="dato-valor">{resumen.bajos}</strong>
        </div>
        <div className="tarjeta-dato">
          <span className="dato-etiqueta">Valor del inventario (al costo)</span>
          <strong className="dato-valor">{pesos.format(resumen.valorInventario)}</strong>
        </div>
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}

      <div className="barra-filtros">
        <input
          className="buscador"
          type="search"
          placeholder="Buscar por nombre o SKU…"
          value={texto}
          onChange={(e) => setTexto(e.target.value)}
        />
        <select
          value={filtroCategoria}
          onChange={(e) => setFiltroCategoria(e.target.value)}
        >
          <option value="">Todas las categorías</option>
          {categorias.map((c) => (
            <option key={c.id} value={c.id}>
              {c.nombre}
            </option>
          ))}
        </select>
        <label className="check">
          <input
            type="checkbox"
            checked={soloStockBajo}
            onChange={(e) => setSoloStockBajo(e.target.checked)}
          />
          Solo stock bajo
        </label>
        <label className="check">
          <input
            type="checkbox"
            checked={incluirInactivos}
            onChange={(e) => setIncluirInactivos(e.target.checked)}
          />
          Ver inactivos
        </label>
      </div>

      <div className="tabla-envoltura">
        <table>
          <thead>
            <tr>
              <th>SKU</th>
              <th>Producto</th>
              <th>Categoría</th>
              <th className="derecha">Precio</th>
              <th className="derecha">Costo</th>
              <th className="derecha">Margen</th>
              <th className="centro">Stock</th>
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
              productos.map((p) => (
                <tr key={p.id} className={p.activo ? '' : 'fila-inactiva'}>
                  <td className="mono">{p.sku}</td>
                  <td>
                    <strong>{p.nombre}</strong>
                    {!p.activo && <span className="etiqueta gris">inactivo</span>}
                    {p.descripcion && <div className="sutil">{p.descripcion}</div>}
                  </td>
                  <td>
                    <span className="etiqueta">{p.categoria.nombre}</span>
                  </td>
                  <td className="derecha">{pesos.format(Number(p.precio_venta))}</td>
                  <td className="derecha sutil">{pesos.format(Number(p.costo))}</td>
                  <td className="derecha">
                    {p.margen_pct === null ? '—' : `${Number(p.margen_pct).toFixed(0)}%`}
                  </td>
                  <td className="centro">
                    <div className="control-stock">
                      <button
                        className="btn-mini"
                        title="Restar una unidad"
                        onClick={() => ajustar(p, -1)}
                      >
                        −
                      </button>
                      <span className={p.stock_bajo ? 'stock stock-bajo' : 'stock'}>
                        {p.stock_actual} {p.unidad_medida}
                      </span>
                      <button
                        className="btn-mini"
                        title="Sumar una unidad"
                        onClick={() => ajustar(p, 1)}
                      >
                        +
                      </button>
                    </div>
                    {p.stock_bajo && (
                      <div className="sutil">mínimo {p.stock_minimo}</div>
                    )}
                  </td>
                  <td className="derecha acciones">
                    <button className="btn btn-suave" onClick={() => abrirEdicion(p)}>
                      Editar
                    </button>
                    <button
                      className={p.activo ? 'btn btn-peligro' : 'btn btn-suave'}
                      onClick={() => alternarActivo(p)}
                    >
                      {p.activo ? 'Desactivar' : 'Reactivar'}
                    </button>
                  </td>
                </tr>
              ))}

            {!cargando && productos.length === 0 && (
              <tr>
                <td colSpan="8" className="celda-vacia">
                  No hay productos que coincidan con el filtro.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {panelAbierto && (
        <div className="fondo-modal" onClick={cerrarPanel}>
          <form
            className="modal"
            onClick={(e) => e.stopPropagation()}
            onSubmit={guardar}
          >
            <h3>{editandoId ? 'Editar producto' : 'Nuevo producto'}</h3>

            <div className="rejilla-form">
              <label className="campo">
                <span>SKU</span>
                <input required maxLength={40} {...campo('sku')} />
              </label>

              <label className="campo campo-ancho">
                <span>Nombre</span>
                <input required maxLength={150} {...campo('nombre')} />
              </label>

              <label className="campo campo-completo">
                <span>Descripción (opcional)</span>
                <input {...campo('descripcion')} />
              </label>

              <label className="campo">
                <span>Precio de venta</span>
                <input type="number" min="0" step="0.01" required {...campo('precio_venta')} />
              </label>

              <label className="campo">
                <span>Costo</span>
                <input type="number" min="0" step="0.01" {...campo('costo')} />
              </label>

              <label className="campo">
                <span>IVA %</span>
                <input type="number" min="0" max="100" step="0.01" {...campo('iva_pct')} />
              </label>

              <label className="campo">
                <span>Stock actual</span>
                <input type="number" min="0" {...campo('stock_actual')} />
              </label>

              <label className="campo">
                <span>Stock mínimo</span>
                <input type="number" min="0" {...campo('stock_minimo')} />
              </label>

              <label className="campo">
                <span>Unidad</span>
                <select {...campo('unidad_medida')}>
                  {UNIDADES.map((u) => (
                    <option key={u} value={u}>
                      {u}
                    </option>
                  ))}
                </select>
              </label>

              <label className="campo campo-ancho">
                <span>Categoría</span>
                <select required {...campo('categoria_id')}>
                  <option value="">Elige una categoría…</option>
                  {categorias
                    .filter((c) => c.activo)
                    .map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.nombre}
                      </option>
                    ))}
                </select>
              </label>
            </div>

            <div className="modal-pie">
              <button type="button" className="btn btn-suave" onClick={cerrarPanel}>
                Cancelar
              </button>
              <button type="submit" className="btn btn-primario">
                {editandoId ? 'Guardar cambios' : 'Crear producto'}
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  )
}
