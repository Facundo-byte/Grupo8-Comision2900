/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/03_CreacionSPabmPais.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

DELETE FROM Mundial.Pais WHERE nombre IN ('PaisPrueba', 'PaisPruebaMod');
GO

PRINT '=== TESTING ABM PAIS ===';

-- Caso 1: Alta valida
EXEC MfSPabm.altaPais @nombrePais = 'PaisPrueba';
DECLARE @id INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'PaisPrueba');
SELECT prueba = 'P1 Alta valida', id_pais = @id, nombre FROM Mundial.Pais WHERE id_pais = @id;

-- Caso 2: Alta duplicada (debe fallar)
BEGIN TRY
    EXEC MfSPabm.altaPais @nombrePais = 'PaisPrueba';
END TRY
BEGIN CATCH
    PRINT 'P2 Alta duplicada OK (error esperado): ' + ERROR_MESSAGE();
END CATCH

-- Caso 3: Alta con nombre vacio (debe fallar)
BEGIN TRY
    EXEC MfSPabm.altaPais @nombrePais = '   ';
END TRY
BEGIN CATCH
    PRINT 'P3 Alta vacia OK (error esperado): ' + ERROR_MESSAGE();
END CATCH

-- Caso 4: Modificacion valida
EXEC MfSPabm.modificacionPais @IDPais = @id, @nombrePais = 'PaisPruebaMod';
SELECT prueba = 'P4 Modificacion valida', id_pais, nombre FROM Mundial.Pais WHERE id_pais = @id;

-- Caso 5: Modificacion inexistente (debe fallar)
BEGIN TRY
    EXEC MfSPabm.modificacionPais @IDPais = 999999, @nombrePais = 'Otro';
END TRY
BEGIN CATCH
    PRINT 'P5 Modificacion inexistente OK (error esperado): ' + ERROR_MESSAGE();
END CATCH

-- Caso 6: Baja valida
EXEC MfSPabm.bajaPais @IDPais = @id;
SELECT prueba = 'P6 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.Pais WHERE id_pais = @id;
GO
