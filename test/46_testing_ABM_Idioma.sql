/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/18_ABM_Idioma.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;
GO

DELETE FROM Mundial.Idioma WHERE id_arbitro IN (SELECT id_arbitro FROM Mundial.Arbitro WHERE apellido = N'PruebaIdioma');
DELETE FROM Mundial.Arbitro WHERE apellido = N'PruebaIdioma';
GO

DECLARE @id_pais INT, @id_conf INT, @id_arb INT;
SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;
SELECT TOP 1 @id_conf = id_confederacion FROM Mundial.Confederacion ORDER BY id_confederacion;

EXEC Mundial.Arbitro_Alta @nombre = N'Test', @apellido = N'PruebaIdioma', @fecha_nacimiento = '1988-02-02', @id_pais = @id_pais, @id_confederacion = @id_conf, @categoria = N'FIFA', @habilitado = 1, @id_arbitro = @id_arb OUTPUT;
EXEC Mundial.Idioma_Alta @id_arbitro = @id_arb, @idioma = N'Alemán';
EXEC Mundial.Idioma_Modificar @id_arbitro = @id_arb, @idioma = N'Alemán', @idioma_nuevo = N'Suizo';
EXEC Mundial.Idioma_Baja @id_arbitro = @id_arb, @idioma = N'Suizo';

BEGIN TRY
    EXEC Mundial.Idioma_Alta @id_arbitro = NULL, @idioma = N'   ';
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 2 condiciones) -> ' + ERROR_MESSAGE();
END CATCH

EXEC Mundial.Arbitro_Baja @id_arbitro = @id_arb;
GO
