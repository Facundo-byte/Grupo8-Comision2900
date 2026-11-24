#!/usr/bin/env node
/**
 * Ejecuta los scripts SQL del TP en orden para dejar la base
 * MundialDeFutbol lista (tablas, ABMs, SPs, seeds, datos extra y reportes).
 *
 * Uso:
 *   node scripts/run-all.js
 *   node scripts/run-all.js --skip-reset
 *   node scripts/run-all.js --db MundialDeFutbol --container mssql
 *   node scripts/run-all.js --continue-on-error
 *
 * Requiere: Docker, contenedor SQL Server corriendo, Node.js.
 */
const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const args = process.argv.slice(2);

function getArg(name, def) {
  const i = args.indexOf(name);
  if (i === -1) return def;
  return args[i + 1] && !args[i + 1].startsWith("--") ? args[i + 1] : def;
}
const hasFlag = (name) => args.includes(name);

const DB = getArg("--db", process.env.MSSQL_DB || "MundialDeFutbol");
const CONTAINER = getArg("--container", process.env.MSSQL_CONTAINER || "mssql");
const SA_PASSWORD = getArg(
  "--password",
  process.env.MSSQL_SA_PASSWORD || "superAdmin_0",
);
const SQLCMD = "/opt/mssql-tools18/bin/sqlcmd";
const SKIP_RESET = hasFlag("--skip-reset");
const CONTINUE_ON_ERROR = hasFlag("--continue-on-error");

function sh(cmd, cmdArgs, opts = {}) {
  const r = spawnSync(cmd, cmdArgs, { stdio: "inherit", ...opts });
  if (r.error) throw r.error;
  return r.status ?? 1;
}

function sqlcmd(db, sql) {
  const status = sh("docker", [
    "exec",
    CONTAINER,
    SQLCMD,
    "-C",
    "-S",
    "localhost",
    "-U",
    "sa",
    "-P",
    SA_PASSWORD,
    "-d",
    db,
    "-Q",
    sql,
  ]);
  if (status !== 0) throw new Error(`sqlcmd falló (db=${db})`);
}

function runFile(fileRel, db = DB) {
  const abs = path.resolve(ROOT, fileRel);
  if (!fs.existsSync(abs)) throw new Error(`No existe: ${abs}`);
  const base = path.basename(abs);
  const tmp = `/tmp/${Date.now()}-${base}`;
  console.log(`\n==> ${fileRel}`);
  let status = sh("docker", ["cp", abs, `${CONTAINER}:${tmp}`]);
  if (status !== 0) throw new Error(`docker cp falló: ${fileRel}`);
  status = sh("docker", [
    "exec",
    CONTAINER,
    SQLCMD,
    "-C",
    "-S",
    "localhost",
    "-U",
    "sa",
    "-P",
    SA_PASSWORD,
    "-d",
    db,
    "-f",
    "65001",
    "-i",
    tmp,
  ]);
  // limpieza best-effort
  spawnSync("docker", ["exec", CONTAINER, "rm", "-f", tmp], {
    stdio: "ignore",
  });
  if (status !== 0) {
    const msg = `Error ejecutando ${fileRel} (exit=${status})`;
    if (CONTINUE_ON_ERROR) {
      console.warn(`⚠ ${msg} -- continuo por --continue-on-error`);
      return;
    }
    throw new Error(msg);
  }
}

function listSql(dir, filterFn = null) {
  const abs = path.resolve(ROOT, dir);
  return fs
    .readdirSync(abs)
    .filter((f) => f.toLowerCase().endsWith(".sql"))
    .filter((f) => (filterFn ? filterFn(f) : true))
    .sort((a, b) => a.localeCompare(b, "es"))
    .map((f) => path.join(dir, f));
}

function main() {
  console.log("=== TP Mundial de Fútbol - carga completa ===");
  console.log(`DB=${DB} CONTAINER=${CONTAINER} SKIP_RESET=${SKIP_RESET}`);

  if (!SKIP_RESET) {
    console.log("\n==> Reset de base");
    sqlcmd(
      "master",
      `
IF DB_ID(N'${DB}') IS NOT NULL
BEGIN
    ALTER DATABASE [${DB}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [${DB}];
END;
CREATE DATABASE [${DB}];
`,
    );
  }

  // 01-02: esquema y tablas
  runFile("01_Bdd_Esquema.sql", "master");
  runFile("02_tablas_creacion.sql", DB);

  // 03-23: ABMs
  for (const f of listSql("ABMs")) runFile(f, DB);

  // 24-27: SPs de negocio
  for (const f of [
    "SPs/24_SP_Designacion_Arbitral.sql",
    "SPs/25_SP_Reglas_Negocio.sql",
    "SPs/26_SP_Acumulacion_Tarjetas.sql",
    "SPs/27_SP_Priorizacion_Publicidad.sql",
    "SPs/53_SP_Importacion_CSV_V2.sql",
    "SPs/64_SP_Importacion_XML.sql",
  ])
    runFile(f, DB);

  // 28-32: seeds (30 se ejecuta antes y después de 31, según README)
  for (const f of [
    "seeds/28_seed_selecciones.sql",
    "seeds/29_seed_convocados_jugadores.sql",
    "seeds/30_seed_arbitros_infra.sql",
    "seeds/31_seed_partidos.sql",
    "seeds/30_seed_arbitros_infra.sql", // bis
    "seeds/32_seed_posiciones_y_esquemas.sql",
  ])
    runFile(f, DB);

  for (const f of [
    "Reportes/57_Convocados_Por_Seleccion.sql",
    "Reportes/58_DesignacionArbitral.sql",
    "Reportes/59_Goleadores.sql",
    "Reportes/60_Matriz_PrimeTime.sql",
    "Reportes/61_Tarjetas.sql",
  ])
    runFile(f, DB);

  runFile("56_CreacionDatos.sql", DB);

  // Datos extra para enriquecer dashboards
  if (fs.existsSync(path.resolve(ROOT, "CreacionDatos.sql"))) {
    runFile("CreacionDatos.sql", DB);
  } else {
    console.warn("⚠ No se encontró CreacionDatos.sql, se omite.");
  }

  // Entrega 7: reportes
  if (fs.existsSync(path.resolve(ROOT, "Reportes"))) {
    for (const f of listSql("Reportes")) runFile(f, DB);
  }

  console.log("\n✅ Carga completa finalizada.");
  console.log(
    "Verificá con: docker exec mssql /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P superAdmin_0 -d " +
      DB +
      " -Q \"SET NOCOUNT ON; SELECT 'Sede',COUNT(*) FROM Mundial.Sede UNION ALL SELECT 'Arbitro',COUNT(*) FROM Mundial.Arbitro UNION ALL SELECT 'Partido',COUNT(*) FROM Mundial.Partido UNION ALL SELECT 'Gol',COUNT(*) FROM Mundial.Gol;\"",
  );
}

try {
  main();
} catch (err) {
  console.error(`\n❌ ${err.message}`);
  process.exit(1);
}
