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

CREATE OR ALTER PROCEDURE MfSPabm.altaPais (@nombrePais VARCHAR(60),
    @huso_horario VARCHAR(20) = NULL,
    @pbi_per_capita DECIMAL(18,2) = NULL,
    @hora_inicio_prime TIME(0) = '19:00',
    @hora_fin_prime TIME(0) = '23:00')
AS
BEGIN
    DECLARE @errorCount INT = 0
    SET @nombrePais = LTRIM(RTRIM(@nombrePais))

    IF(@nombrePais IS NULL OR @nombrePais = '')
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Nombre invalido.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.Pais WHERE nombre = @nombrePais))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Pais ya existente.';
    END

    IF @pbi_per_capita < 0
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: PBI per capita negativo.';
    END

    SET @huso_horario = UPPER(LTRIM(RTRIM(@huso_horario)));
    IF @huso_horario IS NOT NULL AND (
        @huso_horario NOT LIKE 'UTC[+-][01][0-9]:[0-5][0-9]'
        OR RIGHT(@huso_horario, 5) > '14:00')
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: El huso horario debe tener el formato UTC+HH:MM o UTC-HH:MM.';
    END

    IF @hora_inicio_prime IS NULL OR @hora_fin_prime IS NULL OR @hora_inicio_prime = @hora_fin_prime
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Indicar un inicio y fin de prime time distintos.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Mundial.Pais (nombre, huso_horario, pbi_per_capita, hora_inicio_prime, hora_fin_prime)
            VALUES (@nombrePais, @huso_horario, @pbi_per_capita, @hora_inicio_prime, @hora_fin_prime);
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

CREATE OR ALTER PROCEDURE MfSPabm.modificacionPais (@IDPais INT, @nombrePais VARCHAR(60),
    @huso_horario VARCHAR(20) = NULL,
    @pbi_per_capita DECIMAL(18,2) = NULL,
    @hora_inicio_prime TIME(0) = NULL,
    @hora_fin_prime TIME(0) = NULL)
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

    IF @pbi_per_capita < 0
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: PBI per capita negativo.';
    END

    SET @huso_horario = UPPER(LTRIM(RTRIM(@huso_horario)));
    IF @huso_horario IS NOT NULL AND (
        @huso_horario NOT LIKE 'UTC[+-][01][0-9]:[0-5][0-9]'
        OR RIGHT(@huso_horario, 5) > '14:00')
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: El huso horario debe tener el formato UTC+HH:MM o UTC-HH:MM.';
    END

    IF (@hora_inicio_prime IS NULL AND @hora_fin_prime IS NOT NULL)
       OR (@hora_fin_prime IS NULL AND @hora_inicio_prime IS NOT NULL) OR @hora_inicio_prime = @hora_fin_prime
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Indicar un inicio y fin de prime time distintos.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Mundial.Pais
            SET nombre = LTRIM(RTRIM(@nombrePais)),
                huso_horario = COALESCE(@huso_horario, huso_horario),
                pbi_per_capita = COALESCE(@pbi_per_capita, pbi_per_capita),
                hora_inicio_prime = COALESCE(@hora_inicio_prime, hora_inicio_prime),
                hora_fin_prime = COALESCE(@hora_fin_prime, hora_fin_prime)
            WHERE id_pais = @IDPais;
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
