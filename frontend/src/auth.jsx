import { createContext, useContext, useEffect, useState } from 'react'
import { api, cuandoExpireLaSesion, sesion } from './api.js'

const Contexto = createContext(null)

export function ProveedorAuth({ children }) {
  const [usuario, setUsuario] = useState(null)
  const [verificando, setVerificando] = useState(true)

  // Al recargar la página, si hay token guardado se valida contra la API.
  useEffect(() => {
    cuandoExpireLaSesion(() => setUsuario(null))

    if (!sesion.leer()) {
      setVerificando(false)
      return
    }
    api
      .yo()
      .then(setUsuario)
      .catch(() => sesion.borrar())
      .finally(() => setVerificando(false))
  }, [])

  async function entrar(email, password) {
    const datos = await api.login(email, password)
    sesion.guardar(datos.access_token)
    setUsuario(datos.usuario)
  }

  function salir() {
    sesion.borrar()
    setUsuario(null)
  }

  function refrescarComercio(comercio) {
    setUsuario((u) => (u ? { ...u, comercio } : u))
  }

  return (
    <Contexto.Provider
      value={{ usuario, verificando, entrar, salir, refrescarComercio }}
    >
      {children}
    </Contexto.Provider>
  )
}

export function useAuth() {
  const valor = useContext(Contexto)
  if (!valor) throw new Error('useAuth debe usarse dentro de ProveedorAuth')
  return valor
}
