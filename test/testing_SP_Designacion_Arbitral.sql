/* =============================================================
   Universidad Nacional de La Matanza
   Materia: 3641 - Bases de Datos Aplicada
   Trabajo Práctico: Sistema de Registro y Gestión del Mundial de Fútbol
   Entrega 5 - Base de Datos
   Grupo: 8
   Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis,
                Gonzalo Daniel Cardozo, Thiago Dal Secco
   Fecha: 10/11/2026

   Objetivo:
     Testing del script SPs/20_SP_Designacion_Arbitral.sql (relación 1:1).
     Sección A: casos exitosos (designación válida y designación
                descartada por conflicto de nacionalidad, que queda
                registrada como historial).
     Sección B: casos que NO cumplen las validaciones.

   Estrategia:
     Se libera la terna activa de un partido ya cargado (respaldada en
     una tabla temporal) y al final se restaura, para no alterar el seed.

   Requiere: tablas_creacion.sql, seeds/seed_integrante3.sql y los
   seeds de los Integrantes 1 y 2.
   ============================================================= */

/* Opciones ANSI obligatorias: el índice filtrado de Terna_Arbitral exige
   QUOTED_IDENTIFIER ON (también al crear los SP desde sqlcmd, que viene OFF). */
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SET NOCOUNT ON;
GO

/* =================================================================
   PREPARACIÓN
   ================================================================= */
IF OBJECT_ID(N'tempdb..#ctx') IS NOT NULL       DROP TABLE #ctx;
IF OBJECT_ID(N'tempdb..#respaldo') IS NOT NULL  DROP TABLE #respaldo;

CREATE TABLE #ctx
(
    id_partido INT,
    max_terna  INT,
    a1 INT, a2 INT, a3 INT, a4 INT, a5 INT, a6 INT,
    conflicto INT
);

CREATE TABLE #respaldo
(
    id_terna             INT,
    id_partido           INT,
    id_arbitro_principal INT,
    id_asistente_1       INT,
    id_asistente_2       INT,
    id_cuarto_arbitro    INT,
    id_arbitro_var       INT,
    fecha_designacion    DATETIME2(0)
);

DECLARE @id_partido INT;
DECLARE @sel_local INT, @sel_visitante INT;
DECLARE @pais_local INT, @pais_visitante INT;

SELECT TOP 1 @id_partido = t.id_partido
FROM Mundial.Terna_Arbitral AS t
WHERE t.estado = N'Activa'
ORDER BY t.id_partido;

IF @id_partido IS NULL
    THROW 50000, N'No hay ternas activas. Ejecutar seeds/seed_integrante3.sql y los seeds de los Integrantes 1 y 2.', 1;

INSERT INTO #respaldo
SELECT id_terna, id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
       id_cuarto_arbitro, id_arbitro_var, fecha_designacion
FROM Mundial.Terna_Arbitral
WHERE id_partido = @id_partido AND estado = N'Activa';

DELETE FROM Mundial.Terna_Arbitral
WHERE id_partido = @id_partido AND estado = N'Activa';

SELECT @sel_local = id_seleccion_local, @sel_visitante = id_seleccion_visitante
FROM Mundial.Partido WHERE id_partido = @id_partido;

SELECT @pais_local = id_pais FROM Mundial.Seleccion WHERE id_seleccion = @sel_local;
SELECT @pais_visitante = id_pais FROM Mundial.Seleccion WHERE id_seleccion = @sel_visitante;

DECLARE @a1 INT, @a2 INT, @a3 INT, @a4 INT, @a5 INT, @a6 INT;
DECLARE @conflicto INT;

DECLARE @arbs TABLE (n INT IDENTITY(1,1), id_arbitro INT);
INSERT INTO @arbs (id_arbitro)
SELECT TOP (6) a.id_arbitro
FROM Mundial.Arbitro AS a
WHERE a.habilitado = 1
  AND a.id_pais NOT IN (@pais_local, @pais_visitante)
ORDER BY a.id_arbitro;

IF (SELECT COUNT(*) FROM @arbs) < 6
    THROW 50000, N'No hay 6 árbitros habilitados sin conflicto de nacionalidad. Revisar el seed.', 1;

SELECT @a1 = id_arbitro FROM @arbs WHERE n = 1;
SELECT @a2 = id_arbitro FROM @arbs WHERE n = 2;
SELECT @a3 = id_arbitro FROM @arbs WHERE n = 3;
SELECT @a4 = id_arbitro FROM @arbs WHERE n = 4;
SELECT @a5 = id_arbitro FROM @arbs WHERE n = 5;
SELECT @a6 = id_arbitro FROM @arbs WHERE n = 6;

SELECT TOP 1 @conflicto = a.id_arbitro
FROM Mundial.Arbitro AS a
WHERE a.habilitado = 1
  AND a.id_pais IN (@pais_local, @pais_visitante)
  AND a.id_arbitro NOT IN (@a1, @a2, @a3, @a4, @a5, @a6)
ORDER BY a.id_arbitro;

INSERT INTO #ctx (id_partido, max_terna, a1, a2, a3, a4, a5, a6, conflicto)
VALUES (@id_partido, ISNULL((SELECT MAX(id_terna) FROM Mundial.Terna_Arbitral), 0),
        @a1, @a2, @a3, @a4, @a5, @a6, @conflicto);

PRINT N'Partido de prueba: ' + CONVERT(VARCHAR(10), @id_partido) + N'.';
GO

/* =================================================================
   SECCIÓN A — CASOS EXITOSOS
   ================================================================= */
PRINT N'================ SECCIÓN A: CASOS EXITOSOS ================';
GO

DECLARE @id_partido INT, @a1 INT, @a2 INT, @a3 INT, @a4 INT, @a5 INT, @a6 INT;
DECLARE @conflicto INT, @id_terna INT, @advertencia NVARCHAR(400);

SELECT @id_partido = id_partido, @a1 = a1, @a2 = a2, @a3 = a3,
       @a4 = a4, @a5 = a5, @a6 = a6, @conflicto = conflicto
FROM #ctx;

/* A1. Designación válida: la terna queda activa */
EXEC Mundial.Designacion_Arbitral_Asignar
     @id_partido = @id_partido,
     @id_arbitro_principal = @a1,
     @id_asistente_1 = @a2,
     @id_asistente_2 = @a3,
     @id_cuarto_arbitro = @a4,
     @id_arbitro_var = @a5,
     @id_terna = @id_terna OUTPUT,
     @advertencia = @advertencia OUTPUT;

SELECT prueba = N'A1 Designación válida', id_terna = @id_terna, estado,
       id_arbitro_principal, id_asistente_1, id_asistente_2,
       id_cuarto_arbitro, id_arbitro_var
FROM Mundial.Terna_Arbitral
WHERE id_terna = @id_terna;

PRINT N'A1 advertencia devuelta: ' + ISNULL(@advertencia, N'(ninguna)');

/* Se libera la terna para poder probar la designación con conflicto */
DELETE FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna;

/* A2. Designación con conflicto de nacionalidad: se registra como
       descartada (historial) y el SP informa el rechazo. */
IF @conflicto IS NULL
    PRINT N'A2 OMITIDO: no hay árbitro del país de las selecciones del partido.';
ELSE
BEGIN
    BEGIN TRY
        EXEC Mundial.Designacion_Arbitral_Asignar
             @id_partido = @id_partido,
             @id_arbitro_principal = @conflicto,
             @id_asistente_1 = @a2,
             @id_asistente_2 = @a3,
             @id_cuarto_arbitro = @a4,
             @id_arbitro_var = @a5,
             @id_terna = @id_terna OUTPUT,
             @advertencia = @advertencia OUTPUT;
    END TRY
    BEGIN CATCH
        PRINT N'A2 (esperado: rechazo por conflicto) -> ' + ERROR_MESSAGE();
    END CATCH

    SELECT prueba = N'A2 Designación descartada registrada como historial',
           id_terna, estado, motivo_descarte
    FROM Mundial.Terna_Arbitral
    WHERE id_partido = @id_partido
      AND estado = N'Descartada';
END
GO

/* =================================================================
   SECCIÓN B — CASOS QUE NO CUMPLEN
   ================================================================= */
PRINT N'============ SECCIÓN B: CASOS QUE NO CUMPLEN ==============';
GO

DECLARE @id_partido INT, @a1 INT, @a2 INT, @a3 INT, @a4 INT, @a5 INT, @a6 INT;
DECLARE @conflicto INT, @id_terna INT, @advertencia NVARCHAR(400);

SELECT @id_partido = id_partido, @a1 = a1, @a2 = a2, @a3 = a3,
       @a4 = a4, @a5 = a5, @a6 = a6, @conflicto = conflicto
FROM #ctx;

/* B1. Partido inexistente */
BEGIN TRY
    EXEC Mundial.Designacion_Arbitral_Asignar
         @id_partido = 999999,
         @id_arbitro_principal = @a1,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @id_terna = @id_terna OUTPUT;
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: partido inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B2. Árbitros repetidos y rol inexistente */
BEGIN TRY
    EXEC Mundial.Designacion_Arbitral_Asignar
         @id_partido = @id_partido,
         @id_arbitro_principal = @a1,
         @id_asistente_1 = @a1,
         @id_asistente_2 = 999999,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @id_terna = @id_terna OUTPUT;
END TRY
BEGIN CATCH
    PRINT N'B2 (esperado: repetidos + rol inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B3. Árbitro inhabilitado */
DECLARE @id_pais INT, @id_conf INT, @id_inhab INT;
SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;
SELECT TOP 1 @id_conf = id_confederacion FROM Mundial.Confederacion ORDER BY id_confederacion;

BEGIN TRY
    EXEC Mundial.Arbitro_Alta
         @nombre = N'Test',
         @apellido = N'PruebaDesignacion',
         @fecha_nacimiento = '1987-07-07',
         @id_pais = @id_pais,
         @id_confederacion = @id_conf,
         @categoria = N'FIFA',
         @habilitado = 0,
         @id_arbitro = @id_inhab OUTPUT;

    EXEC Mundial.Designacion_Arbitral_Asignar
         @id_partido = @id_partido,
         @id_arbitro_principal = @id_inhab,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @id_terna = @id_terna OUTPUT;
END TRY
BEGIN CATCH
    PRINT N'B3 (esperado: árbitro principal inhabilitado) -> ' + ERROR_MESSAGE();
END CATCH

EXEC Mundial.Arbitro_Baja @id_arbitro = @id_inhab;

/* B4. El partido ya tiene una terna activa */
EXEC Mundial.Designacion_Arbitral_Asignar
     @id_partido = @id_partido,
     @id_arbitro_principal = @a1,
     @id_asistente_1 = @a2,
     @id_asistente_2 = @a3,
     @id_cuarto_arbitro = @a4,
     @id_arbitro_var = @a5,
     @id_terna = @id_terna OUTPUT;

BEGIN TRY
    EXEC Mundial.Designacion_Arbitral_Asignar
         @id_partido = @id_partido,
         @id_arbitro_principal = @a6,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @id_terna = @id_terna OUTPUT;
END TRY
BEGIN CATCH
    PRINT N'B4 (esperado: ya existe una terna activa) -> ' + ERROR_MESSAGE();
END CATCH

DELETE FROM Mundial.Terna_Arbitral
WHERE id_partido = @id_partido AND estado = N'Activa';
GO

/* =================================================================
   RESTAURACIÓN del estado original del partido
   ================================================================= */
PRINT N'============ RESTAURACIÓN DEL ESTADO ORIGINAL ==============';
GO

DECLARE @id_partido INT;

IF OBJECT_ID(N'tempdb..#ctx') IS NULL OR OBJECT_ID(N'tempdb..#respaldo') IS NULL
BEGIN
    PRINT N'No hay datos de la preparación en esta sesión: no se restaura nada.';
END
ELSE
BEGIN
    DECLARE @max_terna INT;

    SELECT @id_partido = id_partido, @max_terna = max_terna FROM #ctx;

    /* Se eliminan SOLO las ternas generadas por el testing (las que
       tienen id mayor al máximo previo) y se restaura la original. */
    DELETE FROM Mundial.Terna_Arbitral
    WHERE id_partido = @id_partido
      AND id_terna > @max_terna;

    INSERT INTO Mundial.Terna_Arbitral
        (id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
         id_cuarto_arbitro, id_arbitro_var, estado, motivo_descarte)
    SELECT id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
           id_cuarto_arbitro, id_arbitro_var, N'Activa', NULL
    FROM #respaldo;

    PRINT N'Estado original restaurado para el partido ' + CONVERT(VARCHAR(10), @id_partido) + N'.';

    DROP TABLE #ctx;
    DROP TABLE #respaldo;
END
GO
