/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/16_ABM_Sede.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM Mundial.Sede WHERE nombre_estadio = N'Estadio de Prueba')
    DELETE FROM Mundial.Sede WHERE nombre_estadio = N'Estadio de Prueba';
GO

DECLARE @id_sede INT, @id_pais INT;
SELECT TOP 1 @id_pais = id_pais FROM Mundial.Pais ORDER BY id_pais;

EXEC Mundial.Sede_Alta @nombre_estadio = N'Estadio de Prueba', @ciudad = N'Ciudad de Prueba', @id_pais = @id_pais, @capacidad = 40000, @huso_horario = 'UTC-03:00', @latitud = -34.6, @longitud = -58.4, @id_sede = @id_sede OUTPUT;
SELECT prueba = N'A1 Alta válida', id_sede = @id_sede, nombre_estadio, ciudad, capacidad, huso_horario FROM Mundial.Sede WHERE id_sede = @id_sede;

EXEC Mundial.Sede_Modificar @id_sede = @id_sede, @nombre_estadio = N'Estadio de Prueba', @ciudad = N'Ciudad de Prueba', @id_pais = @id_pais, @capacidad = 55000, @huso_horario = 'utc-06:00', @latitud = -34.7, @longitud = -58.5;
SELECT prueba = N'A2 Modificación válida', id_sede, capacidad, huso_horario FROM Mundial.Sede WHERE id_sede = @id_sede;

EXEC Mundial.Sede_Baja @id_sede = @id_sede;
SELECT prueba = N'A3 Baja válida (debe devolver 0 filas)', filas = COUNT(*) FROM Mundial.Sede WHERE id_sede = @id_sede;

BEGIN TRY
    EXEC Mundial.Sede_Alta @nombre_estadio = N'   ', @ciudad = NULL, @id_pais = @id_pais, @capacidad = -1, @huso_horario = 'GMT-3', @latitud = 100, @longitud = NULL;
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con 6 condiciones) -> ' + ERROR_MESSAGE();
END CATCH
GO
