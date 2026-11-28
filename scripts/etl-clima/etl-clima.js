/**
 * ETL standalone - Clima por sede
 *
 * Flujo:
 *   1. Extract: leer sedes con lat/lon desde SQL Server
 *   2. Extract externo: consultar Open-Meteo por sede
 *   3. Transform: normalizar respuesta
 *   4. Load: insertar en Mundial.Clima_Sede
 *
 */

const sql = require("mssql");

const dbConfig = {
  user: process.env.DB_USER || "sa",
  password: process.env.DB_PASSWORD || "superAdmin_0",
  server: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 1433),
  database: process.env.DB_NAME || "MundialDeFutbol",
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
  pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
};

/**
 * @description Query contra mssql
 * @returns {recordset} Respuesta a la query
 */
async function obtenerSedes(pool) {
  const request = pool.request();

  const result = await request.query(`
    SELECT id_sede, nombre_estadio, ciudad, latitud, longitud
    FROM Mundial.Sede
    WHERE latitud IS NOT NULL AND longitud IS NOT NULL
    ORDER BY id_sede;
  `);

  return result.recordset;
}

/**
 * @description Le pega a la API del clima, con manejo de errores HTTP y timeouts
 * @returns {object} Data traida del API
 */
async function consultarClima(sede) {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.search = new URLSearchParams({
    latitude: sede.latitud,
    longitude: sede.longitud,
    current: "temperature_2m,weather_code,wind_speed_10m",
  });

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);

  try {
    const response = await fetch(url, {
      method: "GET",
      signal: controller.signal,
      headers: { Accept: "application/json" },
    });

    if (!response.ok) {
      let detalle = "";
      try {
        const bodyError = await response.text();
        detalle = bodyError ? ` - ${bodyError.slice(0, 200)}` : "";
      } catch {
        // ignorar error leyendo body
      }
      throw new Error(
        `HTTP ${response.status} ${response.statusText}${detalle}`,
      );
    }

    const data = await response.json();
    if (!data || !data.current) {
      throw new Error("Respuesta inválida de Open-Meteo: falta 'current'");
    }
    return data;
  } catch (err) {
    if (err.name === "AbortError") {
      throw new Error("Timeout al consultar Open-Meteo (10s)");
    }
    throw new Error(
      `No se pudo consultar clima para sede ${sede.id_sede} (${sede.nombre_estadio}): ${err.message}`,
    );
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * @description Mapper de variables open-meteo a strings "humanizados"
 * @returns {string} Condicion climatica "humanizada"
 */
function weatherCodeACondicion(code) {
  if (code === null || code === undefined || Number.isNaN(Number(code))) {
    return "Desconocido";
  }

  const c = Number(code);
  const mapa = {
    0: "Despejado",
    1: "Mayormente despejado",
    2: "Parcialmente nublado",
    3: "Nublado",
    45: "Niebla",
    48: "Niebla con escarcha",
    51: "Llovizna ligera",
    53: "Llovizna moderada",
    55: "Llovizna intensa",
    56: "Llovizna helada ligera",
    57: "Llovizna helada intensa",
    61: "Lluvia ligera",
    63: "Lluvia moderada",
    65: "Lluvia intensa",
    66: "Lluvia helada ligera",
    67: "Lluvia helada intensa",
    71: "Nieve ligera",
    73: "Nieve moderada",
    75: "Nieve intensa",
    77: "Granizo fino",
    80: "Chubascos ligeros",
    81: "Chubascos moderados",
    82: "Chubascos violentos",
    85: "Chubascos de nieve ligeros",
    86: "Chubascos de nieve intensos",
    95: "Tormenta",
    96: "Tormenta con granizo leve",
    99: "Tormenta con granizo fuerte",
  };

  return mapa[c] || `Código WMO ${c}`;
}

/**
 * @description Armado de campos
 * @returns {*}
 */
function transformarClima(sede, respuestaApi) {
  const current = respuestaApi?.current;
  if (!current) {
    throw new Error("La respuesta de Open-Meteo no contiene datos current");
  }

  const weatherCode =
    current.weather_code === null || current.weather_code === undefined
      ? null
      : Number(current.weather_code);

  return {
    id_sede: sede.id_sede,
    nombre_estadio: sede.nombre_estadio,
    ciudad: sede.ciudad,
    temperatura_c:
      current.temperature_2m === null || current.temperature_2m === undefined
        ? null
        : Number(current.temperature_2m),
    viento_kmh:
      current.wind_speed_10m === null || current.wind_speed_10m === undefined
        ? null
        : Number(current.wind_speed_10m),
    weather_code: weatherCode,
    condicion: weatherCodeACondicion(weatherCode),
    fuente: "Open-Meteo",
    json_respuesta: JSON.stringify(respuestaApi),
  };
}

/**
 * @description Insert contra mssql
 * @returns {boolean} exito o falla
 */
async function guardarClima(pool, clima) {
  await pool
    .request()
    .input("id_sede", sql.Int, clima.id_sede)
    .input("temperatura_c", sql.Decimal(5, 2), clima.temperatura_c)
    .input("viento_kmh", sql.Decimal(6, 2), clima.viento_kmh)
    .input("weather_code", sql.Int, clima.weather_code)
    .input("condicion", sql.VarChar(60), clima.condicion)
    .input("fuente", sql.VarChar(30), clima.fuente)
    .input("json_respuesta", sql.NVarChar(sql.MAX), clima.json_respuesta)
    .query(`
      INSERT INTO Mundial.Clima_Sede (
        id_sede, fecha_consulta_utc, temperatura_c, viento_kmh,
        weather_code, condicion, fuente, json_respuesta
      )
      VALUES (
        @id_sede, SYSUTCDATETIME(), @temperatura_c, @viento_kmh,
        @weather_code, @condicion, @fuente, @json_respuesta
      );
    `);

  return { inserted: true };
}

/**
 * @description orquestador ETL
 * @returns {*}
 */
async function main() {
  console.log("=== ETL Clima por sede ===");

  let pool;
  const resumen = { total: 0, ok: 0, fail: 0, inserted: 0 };

  try {
    pool = await sql.connect(dbConfig);
    console.log("Conectado a SQL Server");

    const sedes = await obtenerSedes(pool);
    resumen.total = sedes.length;
    console.log(`Sedes a procesar: ${sedes.length}`);

    if (sedes.length === 0) {
      console.warn("No hay sedes con latitud/longitud para procesar.");
      return;
    }

    for (const sede of sedes) {
      const etiqueta = `[${sede.id_sede}] ${sede.nombre_estadio} (${sede.ciudad})`;
      try {
        const respuestaApi = await consultarClima(sede);
        const clima = transformarClima(sede, respuestaApi);
        const result = await guardarClima(pool, clima);

        resumen.ok += 1;
        if (result.inserted) resumen.inserted += 1;
        console.log(
          `OK ${etiqueta}: ${clima.temperatura_c}°C, viento ${clima.viento_kmh} km/h, ${clima.condicion}`,
        );
      } catch (err) {
        resumen.fail += 1;
        console.error(`FAIL ${etiqueta}: ${err.message}`);
        // Continuar con la siguiente sede
      }
    }
  } finally {
    if (pool) {
      await pool.close();
      console.log("Conexión SQL cerrada");
    }
  }

  console.log("=== Resumen ===");
  console.log(resumen);

  if (resumen.fail > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error("ETL falló:", err.message);
  process.exit(1);
});
