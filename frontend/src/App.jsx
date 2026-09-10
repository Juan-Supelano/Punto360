import { useState } from 'react'
import Productos from './pages/Productos.jsx'
import Categorias from './pages/Categorias.jsx'

export default function App() {
  const [vista, setVista] = useState('productos')

  return (
    <div className="contenedor">
      <header>
        <h1>Cuadre POS</h1>
        <nav>
          <button
            className={vista === 'productos' ? 'activo' : ''}
            onClick={() => setVista('productos')}
          >
            Productos
          </button>
          <button
            className={vista === 'categorias' ? 'activo' : ''}
            onClick={() => setVista('categorias')}
          >
            Categorías
          </button>
        </nav>
      </header>

      <main>
        {vista === 'productos' ? <Productos /> : <Categorias />}
      </main>
    </div>
  )
}
