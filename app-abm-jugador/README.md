# ABM Jugador (Entrega 9)

App simple Node.js + Express para gestionar ABM de `Mundial.Jugador`.

## Requisitos
- Node.js 18+
- SQL Server con base `MundialDeFutbol` cargada (scripts del TP / `node scripts/run-all.js`)
- SPs ABM de Jugador instalados: `ABMs/06_CreacionSPabmJugador.sql`

## Ejecutar

```bash
cd Grupo8-Comision2900/app-abm-jugador
npm install
npm start
```

Abrir: <http://localhost:3001>

## Variables de entorno (opcionales)
- `PORT` (default `3001`)
- `DB_HOST` (default `localhost`)
- `DB_PORT` (default `1433`)
- `DB_USER` (default `sa`)
- `DB_PASSWORD` (default `superAdmin_0`)
- `DB_NAME` (default `MundialDeFutbol`)

## Funcionalidad
- **Alta**: llama `MfSPabm.altaJugador`.
- **Modificación**: llama `MfSPabm.modificacionJugador`.
- **Baja**: requiere seleccionar **motivo de baja** en la UI y luego llama `MfSPabm.bajaJugador`.
- Dropdown de lista/selección cargado desde `Mundial.ListaConvocados` + `Seleccion` + `Pais`.
- Búsqueda por nombre, apellido, club o selección.
