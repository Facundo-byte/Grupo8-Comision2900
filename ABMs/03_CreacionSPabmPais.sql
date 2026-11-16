/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Pais
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.altaPais (@nombrePais VARCHAR(30))
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF(@nombrePais IS NULL OR LTRIM(RTRIM(@nombrePais)) = '')
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Nombre invalido.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.Pais WHERE nombre = @nombrePais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Pais ya existente.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Mundial.Pais(nombre) VALUES (@nombrePais);
            PRINT 'Pais creado exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo crear el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo crear el Pais debido a errores de validacion.', 1;
    END
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.bajaPais (@IDPais INT)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDPais IS NULL) OR (@IDPais <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Pais invalido.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Pais WHERE id_pais = @IDPais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Pais.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Mundial.Pais WHERE id_pais = @IDPais;
            PRINT 'Pais eliminado exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo eliminar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50002, 'No se pudo eliminar el Pais debido a errores de validacion.', 1;
    END
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.modificacionPais (@IDPais INT, @nombrePais VARCHAR(30))
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDPais IS NULL) OR (@IDPais <= 0) OR (@nombrePais IS NULL) OR LTRIM(RTRIM(@nombrePais)) = '')
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Pais WHERE id_pais = @IDPais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Pais.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.Pais WHERE nombre = @nombrePais AND id_pais <> @IDPais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: El nombre ya pertenece a otro Pais.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Mundial.Pais SET nombre = @nombrePais WHERE id_pais = @IDPais;
            PRINT 'Pais modificado exitosamente';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo modificar el registro';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo modificar el Pais debido a errores de validacion.', 1;
    END
END
GO
