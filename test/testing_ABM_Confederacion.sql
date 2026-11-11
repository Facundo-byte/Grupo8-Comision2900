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
     Testing del script ABMs/15_ABM_Confederacion.sql (relación 1:1).
     Sección A: casos exitosos (con evidencia de los datos).
     Sección B: casos que NO cumplen las validaciones (se muestra el
                mensaje agrupado que devuelve cada SP).

   Ejecutar después de tablas_creacion.sql y del seed del módulo.
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
IF EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE sigla IN ('ZZTEST', 'ZZTSEC', 'ESTAMUYLAR'))
BEGIN
    DELETE FROM Mundial.Idioma
    WHERE id_arbitro IN (
        SELECT id_arbitro FROM Mundial.Arbitro
        WHERE apellido IN (N'PruebaConfederacion')
    );

    DELETE FROM Mundial.Arbitro
    WHERE apellido IN (N'PruebaConfederacion');

    DELETE FROM Mundial.Confederacion
    WHERE sigla IN ('ZZTEST', 'ZZTSEC', 'ESTAMUYLAR');
END;
GO

PRINT N'================ SECCIÓN A: CASOS EXITOSOS ================';
GO

DECLARE @id_conf INT;
DECLARE @id_conf2 INT;

/* A1. Alta válida */
EXEC Mundial.Confederacion_Alta
     @nombre = N'Confederación de Prueba',
     @sigla = 'ZZTEST',
     @id_confederacion = @id_conf OUTPUT;

SELECT prueba = N'A1 Alta válida', id_confederacion = @id_conf, nombre, sigla
FROM Mundial.Confederacion
WHERE id_confederacion = @id_conf;

/* A2. Modificación válida */
EXEC Mundial.Confederacion_Modificar
     @id_confederacion = @id_conf,
     @nombre = N'Confederación de Prueba Modificada',
     @sigla = 'ZZTSEC';

SELECT prueba = N'A2 Modificación válida', id_confederacion, nombre, sigla
FROM Mundial.Confederacion
WHERE id_confederacion = @id_conf;

/* A3. Alta de una segunda confederación (para el caso de baja bloqueada) */
EXEC Mundial.Confederacion_Alta
     @nombre = N'Confederación de Prueba 3',
     @sigla = 'ZZTEST',
     @id_confederacion = @id_conf2 OUTPUT;

SELECT prueba = N'A3 Segunda alta válida', id_confederacion = @id_conf2, nombre, sigla
FROM Mundial.Confederacion
WHERE id_confederacion = @id_conf2;

/* A4. Baja válida */
EXEC Mundial.Confederacion_Baja @id_confederacion = @id_conf2;

SELECT prueba = N'A4 Baja válida (debe devolver 0 filas)',
       filas = COUNT(*)
FROM Mundial.Confederacion
WHERE id_confederacion = @id_conf2;
GO

PRINT N'============ SECCIÓN B: CASOS QUE NO CUMPLEN ==============';
GO

/* B1. Nombre nulo y sigla con números: los dos errores en UN mensaje */
BEGIN TRY
    EXEC Mundial.Confederacion_Alta
         @nombre = NULL,
         @sigla = '12A';
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 2 condiciones) -> ' + ERROR_MESSAGE();
END CATCH

/* B2. Nombre vacío y sigla demasiado corta */
BEGIN TRY
    EXEC Mundial.Confederacion_Alta
         @nombre = N'   ',
         @sigla = 'A';
END TRY
BEGIN CATCH
    PRINT N'B2 (esperado: nombre vacío + sigla corta) -> ' + ERROR_MESSAGE();
END CATCH

/* B3. Nombre duplicado */
BEGIN TRY
    EXEC Mundial.Confederacion_Alta
         @nombre = N'Confederación de Prueba Modificada',
         @sigla = 'ZZNEW';
END TRY
BEGIN CATCH
    PRINT N'B3 (esperado: nombre duplicado) -> ' + ERROR_MESSAGE();
END CATCH

/* B4. Sigla duplicada */
BEGIN TRY
    EXEC Mundial.Confederacion_Alta
         @nombre = N'Otra Confederación',
         @sigla = 'ZZTSEC';
END TRY
BEGIN CATCH
    PRINT N'B4 (esperado: sigla duplicada) -> ' + ERROR_MESSAGE();
END CATCH

/* B5. Nombre y sigla demasiado largos */
DECLARE @nombre_largo NVARCHAR(61) = REPLICATE(N'X', 61);

BEGIN TRY
    EXEC Mundial.Confederacion_Alta
         @nombre = @nombre_largo,
         @sigla = 'ESTAMUYLARGA';
END TRY
BEGIN CATCH
    PRINT N'B5 (esperado: nombre y sigla fuera de longitud) -> ' + ERROR_MESSAGE();
END CATCH

/* B6. Modificación de una confederación inexistente */
BEGIN TRY
    EXEC Mundial.Confederacion_Modificar
         @id_confederacion = 999999,
         @nombre = N'No existe',
         @sigla = 'ZZNO';
END TRY
BEGIN CATCH
    PRINT N'B6 (esperado: id inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B7. Baja de una confederación inexistente */
BEGIN TRY
    EXEC Mundial.Confederacion_Baja @id_confederacion = 999999;
END TRY
BEGIN CATCH
    PRINT N'B7 (esperado: id inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B8. Baja bloqueada: la confederación tiene árbitros asociados.
       Se crea un árbitro de prueba en la confederación ZZTEST y se
       intenta dar de baja. */
DECLARE @id_arb INT;
DECLARE @id_pais INT;
DECLARE @id_conf INT = (SELECT id_confederacion FROM Mundial.Confederacion WHERE sigla = 'ZZTSEC');

IF OBJECT_ID(N'Mundial.Pais', N'U') IS NOT NULL
   AND EXISTS (SELECT 1 FROM Mundial.Pais)
BEGIN
    SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;

    EXEC Mundial.Arbitro_Alta
         @nombre = N'Test',
         @apellido = N'PruebaConfederacion',
         @fecha_nacimiento = '1990-01-01',
         @id_pais = @id_pais,
         @id_confederacion = @id_conf,
         @categoria = N'FIFA',
         @habilitado = 1,
         @id_arbitro = @id_arb OUTPUT;

    BEGIN TRY
        EXEC Mundial.Confederacion_Baja @id_confederacion = @id_conf;
    END TRY
    BEGIN CATCH
        PRINT N'B8 (esperado: baja bloqueada por árbitros asociados) -> ' + ERROR_MESSAGE();
    END CATCH

    /* Limpieza */
    DELETE FROM Mundial.Idioma WHERE id_arbitro = @id_arb;
    DELETE FROM Mundial.Arbitro WHERE id_arbitro = @id_arb;
END
ELSE
    PRINT N'B8 OMITIDO: no hay países cargados para asociar un árbitro.';
GO

/* Estado final: la confederación de prueba sigue existiendo (la baja de
   B8 fue rechazada a propósito). */
SELECT prueba = N'Estado final', id_confederacion, nombre, sigla
FROM Mundial.Confederacion
WHERE sigla = 'ZZTSEC';

/* Limpieza final: se eliminan los datos de prueba para que el script
   pueda volver a ejecutarse sin dejar basura. */
DELETE FROM Mundial.Confederacion
WHERE sigla IN ('ZZTEST', 'ZZTSEC', 'ESTAMUYLAR');

PRINT N'Limpieza: datos de prueba de Confederacion eliminados.';
GO
