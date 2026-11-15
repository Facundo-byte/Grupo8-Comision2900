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
     Testing del script ABMs/18_ABM_Idioma.sql (relación 1:1).
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

DELETE FROM Mundial.Idioma
WHERE id_arbitro IN (SELECT id_arbitro FROM Mundial.Arbitro WHERE apellido = N'PruebaIdioma');

DELETE FROM Mundial.Arbitro WHERE apellido = N'PruebaIdioma';
GO

PRINT N'================ SECCIÓN A: CASOS EXITOSOS ================';
GO

DECLARE @id_pais INT;
DECLARE @id_conf INT;
DECLARE @id_arb INT;

SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;
SELECT TOP 1 @id_conf = id_confederacion FROM Mundial.Confederacion ORDER BY id_confederacion;

IF @id_pais IS NULL OR @id_conf IS NULL
    THROW 50000, N'Faltan datos base: países o confederaciones. Ejecutar los seeds.', 1;

/* Árbitro de apoyo */
EXEC Mundial.Arbitro_Alta
     @nombre = N'Test',
     @apellido = N'PruebaIdioma',
     @fecha_nacimiento = '1988-02-02',
     @id_pais = @id_pais,
     @id_confederacion = @id_conf,
     @categoria = N'FIFA',
     @habilitado = 1,
     @id_arbitro = @id_arb OUTPUT;

/* A1. Alta válida */
EXEC Mundial.Idioma_Alta @id_arbitro = @id_arb, @idioma = N'Alemán';

SELECT prueba = N'A1 Alta válida', id_arbitro, idioma
FROM Mundial.Idioma
WHERE id_arbitro = @id_arb;

/* A2. Modificación válida */
EXEC Mundial.Idioma_Modificar
     @id_arbitro = @id_arb,
     @idioma = N'Alemán',
     @idioma_nuevo = N'Suizo';

SELECT prueba = N'A2 Modificación válida', id_arbitro, idioma
FROM Mundial.Idioma
WHERE id_arbitro = @id_arb;

/* A3. Alta de un segundo idioma y baja de uno de ellos */
EXEC Mundial.Idioma_Alta @id_arbitro = @id_arb, @idioma = N'Inglés';

EXEC Mundial.Idioma_Baja @id_arbitro = @id_arb, @idioma = N'Suizo';

SELECT prueba = N'A3 Baja válida (queda solo un idioma del árbitro de prueba)',
       idioma
FROM Mundial.Idioma
WHERE id_arbitro = @id_arb;
GO

PRINT N'============ SECCIÓN B: CASOS QUE NO CUMPLEN ==============';
GO

DECLARE @id_arb INT = (SELECT TOP 1 id_arbitro FROM Mundial.Arbitro WHERE apellido = N'PruebaIdioma' ORDER BY id_arbitro);

IF @id_arb IS NULL
    THROW 50000, N'No existe el árbitro de prueba. Ejecutar la sección A primero.', 1;

/* B1. Árbitro nulo e idioma vacío: dos condiciones en un mensaje */
BEGIN TRY
    EXEC Mundial.Idioma_Alta @id_arbitro = NULL, @idioma = N'   ';
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 2 condiciones) -> ' + ERROR_MESSAGE();
END CATCH

/* B2. Árbitro inexistente */
BEGIN TRY
    EXEC Mundial.Idioma_Alta @id_arbitro = 999999, @idioma = N'Inglés';
END TRY
BEGIN CATCH
    PRINT N'B2 (esperado: id_arbitro inexistente) -> ' + ERROR_MESSAGE();
END CATCH

/* B3. Idioma duplicado para el mismo árbitro */
BEGIN TRY
    EXEC Mundial.Idioma_Alta @id_arbitro = @id_arb, @idioma = N'Inglés';
END TRY
BEGIN CATCH
    PRINT N'B3 (esperado: idioma ya registrado) -> ' + ERROR_MESSAGE();
END CATCH

/* B4. Idioma demasiado largo */
DECLARE @idioma_largo NVARCHAR(51) = REPLICATE(N'X', 51);

BEGIN TRY
    EXEC Mundial.Idioma_Alta @id_arbitro = @id_arb, @idioma = @idioma_largo;
END TRY
BEGIN CATCH
    PRINT N'B4 (esperado: idioma fuera de longitud) -> ' + ERROR_MESSAGE();
END CATCH

/* B5. Modificación de un idioma que el árbitro no tiene */
BEGIN TRY
    EXEC Mundial.Idioma_Modificar
         @id_arbitro = @id_arb,
         @idioma = N'Quechua',
         @idioma_nuevo = N'Guaraní';
END TRY
BEGIN CATCH
    PRINT N'B5 (esperado: el árbitro no tiene ese idioma) -> ' + ERROR_MESSAGE();
END CATCH

/* B6. Baja de un idioma inexistente */
BEGIN TRY
    EXEC Mundial.Idioma_Baja @id_arbitro = @id_arb, @idioma = N'Quechua';
END TRY
BEGIN CATCH
    PRINT N'B6 (esperado: el árbitro no tiene ese idioma) -> ' + ERROR_MESSAGE();
END CATCH

/* Limpieza del árbitro de apoyo (ya no tiene idiomas) */
EXEC Mundial.Arbitro_Baja @id_arbitro = @id_arb;
GO
