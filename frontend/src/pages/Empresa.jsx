import { useEffect, useState } from 'react'
import { api } from '../api.js'
import { useAuth } from '../auth.jsx'

const CAMPOS = [
  ['razon_social', 'Razón social', true],
  ['nombre_comercial', 'Nombre comercial', false],
  ['nit', 'NIT', true],
  ['direccion', 'Dirección', false],
  ['ciudad', 'Ciudad', false],
  ['telefono', 'Teléfono', false],
  ['email', 'Correo', false],
  ['logo_url', 'URL del logo', false],
]

export default function Empresa() {
  const { usuario, refrescarComercio } = useAuth()
  const esAdmin = usuario?.rol === 'ADMIN'

  const [datos, setDatos] = useState(null)
  const [error, setError] = useState('')
  const [guardado, setGuardado] = useState(false)

  useEffect(() => {
    api
      .verComercio()
      .then((c) => setDatos(c))
      .catch((e) => setError(e.message))
  }, [])

  async function guardar(evento) {
    evento.preventDefault()
    setError('')
    setGuardado(false)
    try {
      const cambios = Object.fromEntries(
        CAMPOS.map(([clave]) => [clave, datos[clave] || null]),
      )
      const actualizado = await api.actualizarComercio(cambios)
      setDatos(actualizado)
      refrescarComercio(actualizado)
      setGuardado(true)
    } catch (e) {
      setError(e.message)
    }
  }

  if (error && !datos) return <p className="aviso aviso-error">{error}</p>
  if (!datos) return <p>Cargando…</p>

  return (
    <section>
      <div className="titulo-vista">
        <div>
          <h2>Mi empresa</h2>
          <p className="sutil">
            Estos datos salen en el encabezado y en las facturas del POS
          </p>
        </div>
      </div>

      {error && <p className="aviso aviso-error">{error}</p>}
      {guardado && <p className="aviso aviso-ok">Datos actualizados.</p>}
      {!esAdmin && (
        <p className="aviso">Solo un usuario con rol ADMIN puede editar esta información.</p>
      )}

      <div className="empresa-doble">
        <form className="tarjeta rejilla-form" onSubmit={guardar}>
          {CAMPOS.map(([clave, etiqueta, obligatorio]) => (
            <label key={clave} className="campo">
              <span>
                {etiqueta}
                {obligatorio && ' *'}
              </span>
              <input
                required={obligatorio}
                disabled={!esAdmin}
                value={datos[clave] ?? ''}
                onChange={(e) => setDatos({ ...datos, [clave]: e.target.value })}
              />
            </label>
          ))}

          {esAdmin && (
            <div className="modal-pie campo-completo">
              <button type="submit" className="btn btn-primario">
                Guardar cambios
              </button>
            </div>
          )}
        </form>

        <aside className="tarjeta vista-previa">
          <span className="dato-etiqueta">Vista previa</span>
          <div className="previa-marca">
            {datos.logo_url ? (
              <img src={datos.logo_url} alt="Logo" />
            ) : (
              <div className="previa-sinlogo">sin logo</div>
            )}
            <div>
              <strong>{datos.nombre_comercial || datos.razon_social}</strong>
              <div className="sutil">NIT {datos.nit}</div>
            </div>
          </div>
          <p className="sutil">
            {[datos.direccion, datos.ciudad].filter(Boolean).join(' · ') || 'Sin dirección'}
          </p>
          <p className="sutil">
            {[datos.telefono, datos.email].filter(Boolean).join(' · ') || 'Sin contacto'}
          </p>
          <p className="nota">
            El logo se guarda como URL, no como archivo. Sube la imagen al bucket de
            Cloud Storage y pega aquí su dirección pública.
          </p>
        </aside>
      </div>
    </section>
  )
}
