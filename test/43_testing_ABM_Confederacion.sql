/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/15_ABM_Confederacion.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO

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

IF EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE sigla IN ('ZZTEST', 'ZZTSEC', 'ESTAMUYLAR'))
BEGIN
    DELETE FROM Mundial.Idioma
    WHERE id_arbitro IN (SELECT id_arbitro FROM Mundial.Arbitro WHERE apellido IN (N'PruebaConfederacion'));
    DELETE FROM Mundial.Arbitro WHERE apellido IN (N'PruebaConfederacion');
    DELETE FROM Mundial.Confederacion WHERE sigla IN ('ZZTEST', 'ZZTSEC', 'ESTAMUYLAR');
END;
GO

PRINT N'================ SECCIÓN A: CASOS EXITOSOS ================';
GO

DECLARE @id_conf INT, @id_conf2 INT;

EXEC Mundial.Confederacion_Alta @nombre = N'Confederación de Prueba', @sigla = 'ZZTEST', @id_confederacion = @id_conf OUTPUT;
SELECT prueba = N'A1 Alta válida', id_confederacion = @id_conf, nombre, sigla FROM Mundial.Confederacion WHERE id_confederacion = @id_conf;

EXEC Mundial.Confederacion_Modificar @id_confederacion = @id_conf, @nombre = N'Confederación de Prueba Modificada', @sigla = 'ZZTSEC';
SELECT prueba = N'A2 Modificación válida', id_confederacion, nombre, sigla FROM Mundial.Confederacion WHERE id_confederacion = @id_conf;

EXEC Mundial.Confederacion_Alta @nombre = N'Confederación de Prueba 3', @sigla = 'ZZTEST', @id_confederacion = @id_conf2 OUTPUT;
EXEC Mundial.Confederacion_Baja @id_confederacion = @id_conf2;
SELECT prueba = N'A4 Baja válida (debe devolver 0 filas)', filas = COUNT(*) FROM Mundial.Confederacion WHERE id_confederacion = @id_conf2;
GO

PRINT N'============ SECCIÓN B: CASOS QUE NO CUMPLEN ==============';
GO

BEGIN TRY
    EXEC Mundial.Confederacion_Alta @nombre = NULL, @sigla = '12A';
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 2 condiciones) -> ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    EXEC Mundial.Confederacion_Alta @nombre = N'   ', @sigla = 'A';
END TRY
BEGIN CATCH
    PRINT N'B2 (esperado: nombre vacío + sigla corta) -> ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    EXEC Mundial.Confederacion_Alta @nombre = N'Confederación de Prueba Modificada', @sigla = 'ZZNEW';
END TRY
BEGIN CATCH
    PRINT N'B3 (esperado: nombre duplicado) -> ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    EXEC Mundial.Confederacion_Alta @nombre = N'Otra Confederación', @sigla = 'ZZTSEC';
END TRY
BEGIN CATCH
    PRINT N'B4 (esperado: sigla duplicada) -> ' + ERROR_MESSAGE();
END CATCH

DELETE FROM Mundial.Confederacion WHERE sigla IN ('ZZTEST', 'ZZTSEC', 'ESTAMUYLAR');
GO
