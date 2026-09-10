import { useState } from 'react'
import { useAuth } from './auth.jsx'
import Categorias from './pages/Categorias.jsx'
import Empresa from './pages/Empresa.jsx'
import Login from './pages/Login.jsx'
import Productos from './pages/Productos.jsx'

const VISTAS = [
  { clave: 'productos', titulo: 'Productos', icono: '▦' },
  { clave: 'categorias', titulo: 'Categorías', icono: '☰' },
  { clave: 'empresa', titulo: 'Mi empresa', icono: '⌂' },
]

function iniciales(nombre = '') {
  return nombre
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0].toUpperCase())
    .join('')
}

export default function App() {
  const { usuario, verificando, salir } = useAuth()
  const [vista, setVista] = useState('productos')

  if (verificando) {
    return <div className="pantalla-carga">Cargando…</div>
  }

  if (!usuario) {
    return <Login />
  }

  const comercio = usuario.comercio

  return (
    <div className="disposicion">
      <aside className="lateral">
        <div className="lateral-marca">
          {comercio?.logo_url ? (
            <img className="marca-logo" src={comercio.logo_url} alt="" />
          ) : (
            <div className="marca-logo marca-logo-texto">
              {iniciales(comercio?.nombre_visible) || 'CP'}
            </div>
          )}
          <div className="marca-texto">
            <strong>{comercio?.nombre_visible || 'Cuadre POS'}</strong>
            <span className="sutil">NIT {comercio?.nit}</span>
          </div>
        </div>

        <nav className="lateral-nav">
          {VISTAS.map((v) => (
            <button
              key={v.clave}
              className={vista === v.clave ? 'nav-item activo' : 'nav-item'}
              onClick={() => setVista(v.clave)}
            >
              <span className="nav-icono" aria-hidden="true">
                {v.icono}
              </span>
              {v.titulo}
            </button>
          ))}
        </nav>

        <div className="lateral-pie">
          <div className="usuario-chip">
            <div className="avatar">{iniciales(usuario.nombre)}</div>
            <div className="usuario-texto">
              <strong>{usuario.nombre}</strong>
              <span className="sutil">{usuario.rol}</span>
            </div>
          </div>
          <button className="btn btn-suave btn-ancho" onClick={salir}>
            Cerrar sesión
          </button>
        </div>
      </aside>

      <main className="contenido">
        {vista === 'productos' && <Productos />}
        {vista === 'categorias' && <Categorias />}
        {vista === 'empresa' && <Empresa />}
      </main>
    </div>
  )
}
