/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/04_CreacionSPabmSeleccion.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

DELETE FROM Mundial.Seleccion WHERE id_pais IN (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'PaisSeleccionTest');
DELETE FROM Mundial.Pais WHERE nombre = 'PaisSeleccionTest';
GO

PRINT '=== TESTING ABM SELECCION ===';

EXEC MfSPabm.altaPais @nombrePais = 'PaisSeleccionTest';
DECLARE @idPais INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'PaisSeleccionTest');

-- Caso 1: Alta valida
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'Z';
DECLARE @idSel INT = (SELECT id_seleccion FROM Mundial.Seleccion WHERE id_pais = @idPais);
SELECT prueba = 'S1 Alta valida', id_seleccion = @idSel, id_pais, confederacion, grupo FROM Mundial.Seleccion WHERE id_seleccion = @idSel;

-- Caso 2: Alta duplicada para el mismo pais (debe fallar)
BEGIN TRY
    EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'Z';
END TRY
BEGIN CATCH
    PRINT 'S2 Alta duplicada OK (error esperado): ' + ERROR_MESSAGE();
END CATCH

-- Caso 3: Modificacion valida
EXEC MfSPabm.modificacionSeleccion @IDSeleccion = @idSel, @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'Y';
SELECT prueba = 'S3 Modificacion valida', id_seleccion, confederacion, grupo FROM Mundial.Seleccion WHERE id_seleccion = @idSel;

-- Caso 4: Baja valida y limpieza
EXEC MfSPabm.bajaSeleccion @IDSeleccion = @idSel;
EXEC MfSPabm.bajaPais @IDPais = @idPais;
SELECT prueba = 'S4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.Seleccion WHERE id_seleccion = @idSel;
GO
