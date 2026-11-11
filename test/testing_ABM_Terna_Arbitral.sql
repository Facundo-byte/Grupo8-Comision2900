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
     Testing del script ABMs/19_ABM_Terna_Arbitral.sql (relación 1:1).
     Sección A: casos exitosos (con evidencia de los datos).
     Sección B: casos que NO cumplen las validaciones (se muestra el
                mensaje agrupado que devuelve cada SP).

   Estrategia:
     Se toma un partido ya cargado y se libera su terna activa (queda
     respaldada en una tabla temporal). Al final del script se restaura,
     de modo que el seed no queda alterado y el script es re-ejecutable.

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
   PREPARACIÓN: partido de prueba, árbitros y respaldo de la terna
   ================================================================= */
IF OBJECT_ID(N'tempdb..#ctx') IS NOT NULL       DROP TABLE #ctx;
IF OBJECT_ID(N'tempdb..#respaldo') IS NOT NULL  DROP TABLE #respaldo;

CREATE TABLE #ctx
(
    id_partido INT,
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

/* Respaldo y liberación de la terna activa del partido elegido */
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

INSERT INTO #ctx (id_partido, a1, a2, a3, a4, a5, a6, conflicto)
VALUES (@id_partido, @a1, @a2, @a3, @a4, @a5, @a6, @conflicto);

PRINT N'Partido de prueba: ' + CONVERT(VARCHAR(10), @id_partido)
    + N'. Terna original respaldada y liberada para el testing.';
GO

/* =================================================================
   SECCIÓN A — CASOS EXITOSOS
   ================================================================= */
PRINT N'================ SECCIÓN A: CASOS EXITOSOS ================';
GO

DECLARE @id_partido INT, @a1 INT, @a2 INT, @a3 INT, @a4 INT, @a5 INT, @a6 INT;
DECLARE @id_terna_nueva INT;

SELECT @id_partido = id_partido, @a1 = a1, @a2 = a2, @a3 = a3,
       @a4 = a4, @a5 = a5, @a6 = a6
FROM #ctx;

/* A1. Alta de una terna activa completa */
EXEC Mundial.Terna_Arbitral_Alta
     @id_partido = @id_partido,
     @id_arbitro_principal = @a1,
     @id_asistente_1 = @a2,
     @id_asistente_2 = @a3,
     @id_cuarto_arbitro = @a4,
     @id_arbitro_var = @a5,
     @estado = N'Activa',
     @id_terna = @id_terna_nueva OUTPUT;

SELECT prueba = N'A1 Alta de terna activa', id_terna = @id_terna_nueva,
       id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
       id_cuarto_arbitro, id_arbitro_var, estado
FROM Mundial.Terna_Arbitral
WHERE id_terna = @id_terna_nueva;

/* A2. Modificación válida (cambia el cuarto árbitro) */
EXEC Mundial.Terna_Arbitral_Modificar
     @id_terna = @id_terna_nueva,
     @id_partido = @id_partido,
     @id_arbitro_principal = @a1,
     @id_asistente_1 = @a2,
     @id_asistente_2 = @a3,
     @id_cuarto_arbitro = @a6,
     @id_arbitro_var = @a5,
     @estado = N'Activa';

SELECT prueba = N'A2 Modificación válida', id_terna, id_cuarto_arbitro, estado
FROM Mundial.Terna_Arbitral
WHERE id_terna = @id_terna_nueva;

/* A3. Baja válida */
EXEC Mundial.Terna_Arbitral_Baja @id_terna = @id_terna_nueva;

SELECT prueba = N'A3 Baja válida (debe devolver 0 filas)',
       filas = COUNT(*)
FROM Mundial.Terna_Arbitral
WHERE id_terna = @id_terna_nueva;
GO

/* =================================================================
   SECCIÓN B — CASOS QUE NO CUMPLEN
   ================================================================= */
PRINT N'============ SECCIÓN B: CASOS QUE NO CUMPLEN ==============';
GO

DECLARE @id_partido INT, @a1 INT, @a2 INT, @a3 INT, @a4 INT, @a5 INT, @a6 INT;
DECLARE @conflicto INT;
DECLARE @id_terna_aux INT;

SELECT @id_partido = id_partido, @a1 = a1, @a2 = a2, @a3 = a3,
       @a4 = a4, @a5 = a5, @a6 = a6, @conflicto = conflicto
FROM #ctx;

/* B1. Dos roles con el mismo árbitro y un id inexistente */
BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Alta
         @id_partido = @id_partido,
         @id_arbitro_principal = @a1,
         @id_asistente_1 = @a1,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = 999999,
         @id_arbitro_var = @a5;
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: árbitros repetidos + rol con id inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B2. Árbitro nulo */
BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Alta
         @id_partido = @id_partido,
         @id_arbitro_principal = NULL,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5;
END TRY
BEGIN CATCH
    PRINT N'B2 (esperado: falta el id del árbitro principal) -> ' + ERROR_MESSAGE();
END CATCH

/* B3. Estado inválido y motivo informado en una terna no descartada */
BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Alta
         @id_partido = @id_partido,
         @id_arbitro_principal = @a1,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @estado = N'Finalizada',
         @motivo_descarte = N'No corresponde';
END TRY
BEGIN CATCH
    PRINT N'B3 (esperado: estado inválido + motivo con estado no descartado) -> ' + ERROR_MESSAGE();
END CATCH

/* B4. Terna descartada sin motivo */
BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Alta
         @id_partido = @id_partido,
         @id_arbitro_principal = @a1,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @estado = N'Descartada';
END TRY
BEGIN CATCH
    PRINT N'B4 (esperado: descartada sin motivo) -> ' + ERROR_MESSAGE();
END CATCH

/* B5. Conflicto de nacionalidad en una terna activa */
IF @conflicto IS NULL
    PRINT N'B5 OMITIDO: no hay árbitro del país de las selecciones del partido.';
ELSE
BEGIN
    BEGIN TRY
        EXEC Mundial.Terna_Arbitral_Alta
             @id_partido = @id_partido,
             @id_arbitro_principal = @conflicto,
             @id_asistente_1 = @a2,
             @id_asistente_2 = @a3,
             @id_cuarto_arbitro = @a4,
             @id_arbitro_var = @a5,
             @estado = N'Activa';
    END TRY
    BEGIN CATCH
        PRINT N'B5 (esperado: conflicto de nacionalidad) -> ' + ERROR_MESSAGE();
    END CATCH
END

/* B6. Segunda terna activa para el mismo partido */
EXEC Mundial.Terna_Arbitral_Alta
     @id_partido = @id_partido,
     @id_arbitro_principal = @a1,
     @id_asistente_1 = @a2,
     @id_asistente_2 = @a3,
     @id_cuarto_arbitro = @a4,
     @id_arbitro_var = @a5,
     @estado = N'Activa',
     @id_terna = @id_terna_aux OUTPUT;

BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Alta
         @id_partido = @id_partido,
         @id_arbitro_principal = @a6,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @estado = N'Activa';
END TRY
BEGIN CATCH
    PRINT N'B6 (esperado: el partido ya tiene terna activa) -> ' + ERROR_MESSAGE();
END CATCH

EXEC Mundial.Terna_Arbitral_Baja @id_terna = @id_terna_aux;

/* B7. Partido inexistente */
BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Alta
         @id_partido = 999999,
         @id_arbitro_principal = @a1,
         @id_asistente_1 = @a2,
         @id_asistente_2 = @a3,
         @id_cuarto_arbitro = @a4,
         @id_arbitro_var = @a5,
         @estado = N'Activa';
END TRY
BEGIN CATCH
    PRINT N'B7 (esperado: partido inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B8. Baja de una terna inexistente */
BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Baja @id_terna = 999999;
END TRY
BEGIN CATCH
    PRINT N'B8 (esperado: terna inexistente) -> ' + ERROR_MESSAGE();
END CATCH
GO

/* =================================================================
   RESTAURACIÓN de la terna original del partido usado en el testing
   ================================================================= */
PRINT N'============ RESTAURACIÓN DE LA TERNA ORIGINAL =============';
GO

DECLARE @id_partido INT;

IF OBJECT_ID(N'tempdb..#ctx') IS NULL OR OBJECT_ID(N'tempdb..#respaldo') IS NULL
BEGIN
    PRINT N'No hay datos de la preparación en esta sesión: no se restaura nada.';
END
ELSE
BEGIN
    SELECT @id_partido = id_partido FROM #ctx;

    IF NOT EXISTS (
        SELECT 1 FROM Mundial.Terna_Arbitral
        WHERE id_partido = @id_partido AND estado = N'Activa'
    )
    BEGIN
        INSERT INTO Mundial.Terna_Arbitral
            (id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
             id_cuarto_arbitro, id_arbitro_var, estado, motivo_descarte)
        SELECT id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
               id_cuarto_arbitro, id_arbitro_var, N'Activa', NULL
        FROM #respaldo;

        PRINT N'Terna original restaurada para el partido ' + CONVERT(VARCHAR(10), @id_partido) + N'.';
    END
    ELSE
        PRINT N'No fue necesario restaurar (el partido ya tiene terna activa).';

    DROP TABLE #ctx;
    DROP TABLE #respaldo;
END
GO
