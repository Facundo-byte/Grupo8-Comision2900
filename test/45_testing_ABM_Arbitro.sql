/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/17_ABM_Arbitro.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;
GO

DELETE FROM Mundial.Idioma WHERE id_arbitro IN (SELECT id_arbitro FROM Mundial.Arbitro WHERE apellido = N'PruebaArbitro');
DELETE FROM Mundial.Arbitro WHERE apellido = N'PruebaArbitro';
GO

DECLARE @id_pais INT, @id_conf INT, @id_arb INT;
SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;
SELECT TOP 1 @id_conf = id_confederacion FROM Mundial.Confederacion ORDER BY id_confederacion;

EXEC Mundial.Arbitro_Alta @nombre = N'Test', @apellido = N'PruebaArbitro', @fecha_nacimiento = '1985-06-15', @id_pais = @id_pais, @id_confederacion = @id_conf, @categoria = N'FIFA', @habilitado = 1, @id_arbitro = @id_arb OUTPUT;
SELECT prueba = N'A1 Alta válida', id_arbitro = @id_arb, nombre, apellido, categoria, habilitado FROM Mundial.Arbitro WHERE id_arbitro = @id_arb;

EXEC Mundial.Arbitro_Modificar @id_arbitro = @id_arb, @nombre = N'Test', @apellido = N'PruebaArbitro', @fecha_nacimiento = '1985-06-15', @id_pais = @id_pais, @id_confederacion = @id_conf, @categoria = N'CONFEDERACION', @habilitado = 1;
EXEC Mundial.Arbitro_Baja @id_arbitro = @id_arb;

BEGIN TRY
    EXEC Mundial.Arbitro_Alta @nombre = NULL, @apellido = N'   ', @fecha_nacimiento = '2099-01-01', @id_pais = 999999, @id_confederacion = 999999, @categoria = N'REGIONAL';
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 6 condiciones) -> ' + ERROR_MESSAGE();
END CATCH
GO
