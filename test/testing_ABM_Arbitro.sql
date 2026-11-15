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
     Testing del script ABMs/17_ABM_Arbitro.sql (relación 1:1).
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
DELETE FROM Mundial.Idioma
WHERE id_arbitro IN (SELECT id_arbitro FROM Mundial.Arbitro WHERE apellido = N'PruebaArbitro');

DELETE FROM Mundial.Arbitro WHERE apellido = N'PruebaArbitro';
GO

PRINT N'================ SECCIÓN A: CASOS EXITOSOS ================';
GO

DECLARE @id_pais INT;
DECLARE @id_conf INT;
DECLARE @id_arb INT;

SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;
SELECT TOP 1 @id_conf = id_confederacion FROM Mundial.Confederacion ORDER BY id_confederacion;

IF @id_pais IS NULL
    THROW 50000, N'No hay países cargados en Mundial.Pais. Ejecutar el seed del Integrante 1.', 1;
IF @id_conf IS NULL
    THROW 50000, N'No hay confederaciones cargadas. Ejecutar seeds/seed_integrante3.sql.', 1;

/* A1. Alta válida */
EXEC Mundial.Arbitro_Alta
     @nombre = N'Test',
     @apellido = N'PruebaArbitro',
     @fecha_nacimiento = '1985-06-15',
     @id_pais = @id_pais,
     @id_confederacion = @id_conf,
     @categoria = N'FIFA',
     @habilitado = 1,
     @id_arbitro = @id_arb OUTPUT;

SELECT prueba = N'A1 Alta válida', id_arbitro = @id_arb, nombre, apellido, categoria, habilitado
FROM Mundial.Arbitro
WHERE id_arbitro = @id_arb;

/* A2. Modificación válida */
EXEC Mundial.Arbitro_Modificar
     @id_arbitro = @id_arb,
     @nombre = N'Test',
     @apellido = N'PruebaArbitro',
     @fecha_nacimiento = '1985-06-15',
     @id_pais = @id_pais,
     @id_confederacion = @id_conf,
     @categoria = N'CONFEDERACION',
     @habilitado = 1;

SELECT prueba = N'A2 Modificación válida', id_arbitro, categoria, habilitado
FROM Mundial.Arbitro
WHERE id_arbitro = @id_arb;

/* A3. Alta de idioma y baja del árbitro: la baja elimina también sus
       idiomas en la misma transacción. */
EXEC Mundial.Idioma_Alta @id_arbitro = @id_arb, @idioma = N'Italiano';

SELECT prueba = N'A3 Idioma antes de la baja', idioma
FROM Mundial.Idioma
WHERE id_arbitro = @id_arb;

EXEC Mundial.Arbitro_Baja @id_arbitro = @id_arb;

SELECT prueba = N'A3 Baja válida (árbitro e idiomas eliminados)',
       arbitros = (SELECT COUNT(*) FROM Mundial.Arbitro WHERE id_arbitro = @id_arb),
       idiomas  = (SELECT COUNT(*) FROM Mundial.Idioma WHERE id_arbitro = @id_arb);
GO

PRINT N'============ SECCIÓN B: CASOS QUE NO CUMPLEN ==============';
GO

DECLARE @id_pais INT;
DECLARE @id_conf INT;
SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;
SELECT TOP 1 @id_conf = id_confederacion FROM Mundial.Confederacion ORDER BY id_confederacion;

/* B1. Varios errores juntos en un único mensaje */
BEGIN TRY
    EXEC Mundial.Arbitro_Alta
         @nombre = NULL,
         @apellido = N'   ',
         @fecha_nacimiento = '2099-01-01',
         @id_pais = 999999,
         @id_confederacion = 999999,
         @categoria = N'REGIONAL';
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 6 condiciones) -> ' + ERROR_MESSAGE();
END CATCH

/* B2. Árbitro menor de 18 años */
DECLARE @fecha_menor DATE = DATEADD(YEAR, -16, CAST(SYSDATETIME() AS DATE));

BEGIN TRY
    EXEC Mundial.Arbitro_Alta
         @nombre = N'Joven',
         @apellido = N'PruebaArbitro',
         @fecha_nacimiento = @fecha_menor,
         @id_pais = @id_pais,
         @id_confederacion = @id_conf,
         @categoria = N'FIFA';
END TRY
BEGIN CATCH
    PRINT N'B2 (esperado: debe ser mayor de 18 años) -> ' + ERROR_MESSAGE();
END CATCH

/* B3. Datos personales duplicados */
DECLARE @pais_argentina INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = N'Argentina');

BEGIN TRY
    EXEC Mundial.Arbitro_Alta
         @nombre = N'Facundo',
         @apellido = N'Tello',
         @fecha_nacimiento = '1983-05-01',
         @id_pais = @pais_argentina,
         @id_confederacion = @id_conf,
         @categoria = N'FIFA';
END TRY
BEGIN CATCH
    PRINT N'B3 (esperado: árbitro duplicado o país inexistente si no se cargó Argentina) -> ' + ERROR_MESSAGE();
END CATCH

/* B4. Fecha de nacimiento anterior a 1900 */
BEGIN TRY
    EXEC Mundial.Arbitro_Alta
         @nombre = N'Antiguo',
         @apellido = N'PruebaArbitro',
         @fecha_nacimiento = '1850-01-01',
         @id_pais = @id_pais,
         @id_confederacion = @id_conf,
         @categoria = N'FIFA';
END TRY
BEGIN CATCH
    PRINT N'B4 (esperado: fecha anterior a 1900) -> ' + ERROR_MESSAGE();
END CATCH

/* B5. Inhabilitar un árbitro que tiene una terna activa asignada */
DECLARE @id_arb_tema INT;
DECLARE @nom NVARCHAR(50);
DECLARE @ape NVARCHAR(50);
DECLARE @fec DATE;
DECLARE @pais_a INT;
DECLARE @conf_a INT;
DECLARE @cat NVARCHAR(20);

IF OBJECT_ID(N'Mundial.Terna_Arbitral', N'U') IS NOT NULL
    SELECT TOP 1 @id_arb_tema = t.id_arbitro_principal
    FROM Mundial.Terna_Arbitral AS t
    WHERE t.estado = N'Activa'
    ORDER BY t.id_terna;

IF @id_arb_tema IS NULL
    PRINT N'B5 OMITIDO: no hay ternas activas cargadas.';
ELSE
BEGIN
    SELECT @nom = nombre, @ape = apellido, @fec = fecha_nacimiento,
           @pais_a = id_pais, @conf_a = id_confederacion, @cat = categoria
    FROM Mundial.Arbitro
    WHERE id_arbitro = @id_arb_tema;

    BEGIN TRY
        EXEC Mundial.Arbitro_Modificar
             @id_arbitro = @id_arb_tema,
             @nombre = @nom,
             @apellido = @ape,
             @fecha_nacimiento = @fec,
             @id_pais = @pais_a,
             @id_confederacion = @conf_a,
             @categoria = @cat,
             @habilitado = 0;
    END TRY
    BEGIN CATCH
        PRINT N'B5 (esperado: no se puede inhabilitar con terna activa) -> ' + ERROR_MESSAGE();
    END CATCH

    /* B6. Baja bloqueada por tener ternas asignadas */
    BEGIN TRY
        EXEC Mundial.Arbitro_Baja @id_arbitro = @id_arb_tema;
    END TRY
    BEGIN CATCH
        PRINT N'B6 (esperado: baja bloqueada por ternas asignadas) -> ' + ERROR_MESSAGE();
    END CATCH
END

/* B7. Baja de un árbitro inexistente */
BEGIN TRY
    EXEC Mundial.Arbitro_Baja @id_arbitro = 999999;
END TRY
BEGIN CATCH
    PRINT N'B7 (esperado: id inexistente) -> ' + ERROR_MESSAGE();
END CATCH
GO
