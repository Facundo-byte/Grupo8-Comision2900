const express = require('express');
const sql = require('mssql');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT || 3001);

const dbConfig = {
  user: process.env.DB_USER || 'sa',
  password: process.env.DB_PASSWORD || 'superAdmin_0',
  server: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 1433),
  database: process.env.DB_NAME || 'MundialDeFutbol',
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
  pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
};

let poolPromise;
function getPool() {
  if (!poolPromise) {
    poolPromise = sql.connect(dbConfig).catch((err) => {
      poolPromise = undefined;
      throw err;
    });
  }
  return poolPromise;
}

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function sqlError(res, err) {
  const message = err?.originalError?.info?.message || err?.message || 'Error inesperado';
  const status = /validacion|no existe|ya existe|invalido/i.test(message) ? 400 : 500;
  return res.status(status).json({ ok: false, error: message });
}

app.get('/api/health', async (_req, res) => {
  try {
    const pool = await getPool();
    await pool.request().query('SELECT 1 AS ok');
    res.json({ ok: true });
  } catch (err) {
    sqlError(res, err);
  }
});

app.get('/api/listas', async (_req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT lc.id_lista, lc.id_seleccion, p.nombre AS seleccion
      FROM Mundial.ListaConvocados lc
      JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
      JOIN Mundial.Pais p ON p.id_pais = s.id_pais
      ORDER BY p.nombre, lc.id_lista;
    `);
    res.json(result.recordset);
  } catch (err) {
    sqlError(res, err);
  }
});

app.get('/api/jugadores', async (req, res) => {
  try {
    const pool = await getPool();
    const q = (req.query.q || '').toString().trim();
    const request = pool.request();
    let where = '';
    if (q) {
      request.input('q', sql.VarChar(100), `%${q}%`);
      where = `WHERE j.nombre LIKE @q OR j.apellido LIKE @q OR j.club LIKE @q OR p.nombre LIKE @q`;
    }
    const result = await request.query(`
      SELECT j.id_jugador, j.id_lista_convocados, p.nombre AS seleccion,
             j.nombre, j.apellido, j.dorsal, j.club
      FROM Mundial.Jugador j
      JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
      JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
      JOIN Mundial.Pais p ON p.id_pais = s.id_pais
      ${where}
      ORDER BY p.nombre, j.apellido, j.nombre;
    `);
    res.json(result.recordset);
  } catch (err) {
    sqlError(res, err);
  }
});

app.post('/api/jugadores', async (req, res) => {
  const { id_lista_convocados, nombre, apellido, dorsal, club } = req.body || {};
  try {
    const pool = await getPool();
    await pool.request()
      .input('IDListaConvocados', sql.Int, id_lista_convocados)
      .input('Nombre', sql.VarChar(50), nombre)
      .input('Apellido', sql.VarChar(50), apellido)
      .input('Dorsal', sql.Int, dorsal)
      .input('Club', sql.VarChar(50), club)
      .execute('MfSPabm.altaJugador');
    res.status(201).json({ ok: true, message: 'Jugador creado exitosamente.' });
  } catch (err) {
    sqlError(res, err);
  }
});

app.put('/api/jugadores/:id', async (req, res) => {
  const id = Number(req.params.id);
  const { id_lista_convocados, nombre, apellido, dorsal, club } = req.body || {};
  try {
    const pool = await getPool();
    await pool.request()
      .input('IDJugador', sql.Int, id)
      .input('IDListaConvocados', sql.Int, id_lista_convocados)
      .input('Nombre', sql.VarChar(50), nombre)
      .input('Apellido', sql.VarChar(50), apellido)
      .input('Dorsal', sql.Int, dorsal)
      .input('Club', sql.VarChar(50), club)
      .execute('MfSPabm.modificacionJugador');
    res.json({ ok: true, message: 'Jugador modificado exitosamente.' });
  } catch (err) {
    sqlError(res, err);
  }
});

app.delete('/api/jugadores/:id', async (req, res) => {
  const id = Number(req.params.id);
  const { motivo } = req.body || {};
  try {
    const pool = await getPool();
    // El SP actual solo hace baja por ID; registramos motivo en respuesta/auditoría simple.
    await pool.request()
      .input('IDJugador', sql.Int, id)
      .execute('MfSPabm.bajaJugador');
    res.json({ ok: true, message: 'Jugador eliminado exitosamente.', motivo: motivo || null });
  } catch (err) {
    sqlError(res, err);
  }
});

app.listen(PORT, () => {
  console.log(`ABM Jugador escuchando en http://localhost:${PORT}`);
});
