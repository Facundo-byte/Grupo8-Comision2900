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
     Testing del script ABMs/16_ABM_Sede.sql (relación 1:1).
     Sección A: casos exitosos (con evidencia de los datos).
     Sección B: casos que NO cumplen las validaciones (se muestra el
                mensaje agrupado que devuelve cada SP).

   Ejecutar después de tablas_creacion.sql, del seed del módulo y
   de que exista al menos un país en Mundial.Pais.
   El script es re-ejecutable: limpia sus propios datos al comenzar.
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

/* Limpieza de datos de pruebas anteriores */
IF EXISTS (SELECT 1 FROM Mundial.Sede WHERE nombre_estadio = N'Estadio de Prueba')
    DELETE FROM Mundial.Sede WHERE nombre_estadio = N'Estadio de Prueba';
GO

PRINT N'================ SECCIÓN A: CASOS EXITOSOS ================';
GO

DECLARE @id_sede INT;
DECLARE @id_pais INT;

SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;

IF @id_pais IS NULL
    THROW 50000, N'No hay países cargados en Mundial.Pais. Ejecutar el seed del Integrante 1.', 1;

/* A1. Alta válida */
EXEC Mundial.Sede_Alta
     @nombre_estadio = N'Estadio de Prueba',
     @ciudad = N'Ciudad de Prueba',
     @id_pais = @id_pais,
     @capacidad = 40000,
     @huso_horario = 'UTC-03:00',
     @latitud = -34.6,
     @longitud = -58.4,
     @id_sede = @id_sede OUTPUT;

SELECT prueba = N'A1 Alta válida', id_sede = @id_sede, nombre_estadio, ciudad, capacidad, huso_horario
FROM Mundial.Sede
WHERE id_sede = @id_sede;

/* A2. Modificación válida */
EXEC Mundial.Sede_Modificar
     @id_sede = @id_sede,
     @nombre_estadio = N'Estadio de Prueba',
     @ciudad = N'Ciudad de Prueba',
     @id_pais = @id_pais,
     @capacidad = 55000,
     @huso_horario = 'utc-06:00',
     @latitud = -34.7,
     @longitud = -58.5;

SELECT prueba = N'A2 Modificación válida (huso normalizado a mayúsculas)',
       id_sede, capacidad, huso_horario
FROM Mundial.Sede
WHERE id_sede = @id_sede;

/* A3. Baja válida */
EXEC Mundial.Sede_Baja @id_sede = @id_sede;

SELECT prueba = N'A3 Baja válida (debe devolver 0 filas)',
       filas = COUNT(*)
FROM Mundial.Sede
WHERE id_sede = @id_sede;
GO

PRINT N'============ SECCIÓN B: CASOS QUE NO CUMPLEN ==============';
GO

DECLARE @id_pais INT;
SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;

/* B1. Varios errores juntos en un único mensaje */
BEGIN TRY
    EXEC Mundial.Sede_Alta
         @nombre_estadio = N'   ',
         @ciudad = NULL,
         @id_pais = @id_pais,
         @capacidad = -1,
         @huso_horario = 'GMT-3',
         @latitud = 100,
         @longitud = NULL;
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 6 condiciones) -> ' + ERROR_MESSAGE();
END CATCH

/* B2. País inexistente */
BEGIN TRY
    EXEC Mundial.Sede_Alta
         @nombre_estadio = N'Estadio Fantasma',
         @ciudad = N'Ninguna',
         @id_pais = 999999,
         @capacidad = 10000,
         @huso_horario = 'UTC+00:00';
END TRY
BEGIN CATCH
    PRINT N'B2 (esperado: id_pais inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B3. Huso horario con desfase imposible */
BEGIN TRY
    EXEC Mundial.Sede_Alta
         @nombre_estadio = N'Estadio Fantasma',
         @ciudad = N'Ninguna',
         @id_pais = @id_pais,
         @capacidad = 10000,
         @huso_horario = 'UTC+19:00';
END TRY
BEGIN CATCH
    PRINT N'B3 (esperado: huso fuera de rango) -> ' + ERROR_MESSAGE();
END CATCH

/* B4. Capacidad cero y coordenadas fuera de rango */
BEGIN TRY
    EXEC Mundial.Sede_Alta
         @nombre_estadio = N'Estadio Fantasma',
         @ciudad = N'Ninguna',
         @id_pais = @id_pais,
         @capacidad = 0,
         @huso_horario = 'UTC+00:00',
         @latitud = -200,
         @longitud = 300;
END TRY
BEGIN CATCH
    PRINT N'B4 (esperado: capacidad + latitud + longitud inválidas) -> ' + ERROR_MESSAGE();
END CATCH

/* B5. Sede duplicada (se copian los datos de una sede ya existente) */
DECLARE @estadio NVARCHAR(100);
DECLARE @ciudad NVARCHAR(100);
DECLARE @pais_existente INT;
DECLARE @capacidad INT;
DECLARE @huso VARCHAR(10);

SELECT TOP 1
       @estadio = nombre_estadio,
       @ciudad = ciudad,
       @pais_existente = id_pais,
       @capacidad = capacidad,
       @huso = huso_horario
FROM Mundial.Sede
ORDER BY id_sede;

IF @estadio IS NULL
    PRINT N'B5 OMITIDO: no hay sedes cargadas.';
ELSE
BEGIN
    BEGIN TRY
        EXEC Mundial.Sede_Alta
             @nombre_estadio = @estadio,
             @ciudad = @ciudad,
             @id_pais = @pais_existente,
             @capacidad = @capacidad,
             @huso_horario = @huso;
    END TRY
    BEGIN CATCH
        PRINT N'B5 (esperado: estadio + ciudad + país duplicados) -> ' + ERROR_MESSAGE();
    END CATCH
END

/* B6. Modificación de una sede inexistente */
BEGIN TRY
    EXEC Mundial.Sede_Modificar
         @id_sede = 999999,
         @nombre_estadio = N'No existe',
         @ciudad = N'No existe',
         @id_pais = @id_pais,
         @capacidad = 1000,
         @huso_horario = 'UTC+00:00';
END TRY
BEGIN CATCH
    PRINT N'B6 (esperado: id_sede inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B7. Baja bloqueada: la sede tiene partidos asociados */
DECLARE @id_sede_con_partido INT;

IF OBJECT_ID(N'Mundial.Partido', N'U') IS NOT NULL
    SELECT TOP 1 @id_sede_con_partido = id_sede FROM Mundial.Partido ORDER BY id_partido;

IF @id_sede_con_partido IS NULL
    PRINT N'B7 OMITIDO: no hay partidos cargados.';
ELSE
BEGIN
    BEGIN TRY
        EXEC Mundial.Sede_Baja @id_sede = @id_sede_con_partido;
    END TRY
    BEGIN CATCH
        PRINT N'B7 (esperado: baja bloqueada por partidos asociados) -> ' + ERROR_MESSAGE();
    END CATCH
END

/* B8. Baja de una sede inexistente */
BEGIN TRY
    EXEC Mundial.Sede_Baja @id_sede = 999999;
END TRY
BEGIN CATCH
    PRINT N'B8 (esperado: id_sede inexistente) -> ' + ERROR_MESSAGE();
END CATCH
GO
