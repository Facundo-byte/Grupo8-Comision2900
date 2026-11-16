/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Seleccion
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.altaSeleccion (@IDPais INT, @Confederacion VARCHAR(30), @Grupo CHAR(1))
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDPais IS NULL) OR (@IDPais <= 0) OR (@Confederacion IS NULL) OR (@Grupo IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Pais WHERE id_pais = @IDPais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Pais.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_pais = @IDPais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Este Pais ya tiene una Seleccion asociada.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Mundial.Seleccion(id_pais, confederacion, grupo)
            VALUES (@IDPais, @Confederacion, @Grupo);
            PRINT 'Seleccion creada exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo crear el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo crear la Seleccion debido a errores de validacion.', 1;
    END
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.bajaSeleccion (@IDSeleccion INT)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDSeleccion IS NULL) OR (@IDSeleccion <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Seleccion invalida.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Seleccion.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Mundial.Seleccion WHERE id_seleccion = @IDSeleccion;
            PRINT 'Seleccion eliminada exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo eliminar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50002, 'No se pudo eliminar la Seleccion debido a errores de validacion.', 1;
    END
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.modificacionSeleccion (@IDSeleccion INT, @IDPais INT, @Confederacion VARCHAR(30), @Grupo CHAR(1))
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDSeleccion IS NULL) OR (@IDSeleccion <= 0) OR (@IDPais IS NULL) OR (@IDPais <= 0) OR (@Confederacion IS NULL) OR (@Grupo IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Seleccion.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Pais WHERE id_pais = @IDPais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Pais.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_pais = @IDPais AND id_seleccion <> @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Este Pais ya tiene otra Seleccion asociada.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Mundial.Seleccion
            SET id_pais = @IDPais, confederacion = @Confederacion, grupo = @Grupo
            WHERE id_seleccion = @IDSeleccion;
            PRINT 'Seleccion modificada exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo modificar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50003, 'No se pudo modificar la Seleccion debido a errores de validacion.', 1;
    END
END
GO
