/*
-/-/2026
Universidad Nacional de La Matanza
Bases de Datos Aplicada

Grupo 11
DAL SECCO THIAGO
Ramiro De Rogatis
Fede Iascas 
Gonzalo Cardozo
*/

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MundialDeFutbol')
BEGIN
	USE MundialDeFutbol
	PRINT '--Usando BD: MundialDeFutbol--' 
END;
GO

CREATE SCHEMA MfSPabm
GO

PRINT '--Creando SPabm para tablas Seleccion...--';
GO


/*
================================================================
abm Pais
================================================================
*/

--alta Pais
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.altaPais'))
    DROP PROCEDURE MfSPabm.altaPais
GO

CREATE PROCEDURE MfSPabm.altaPais (@nombrePais VARCHAR(30))
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar nombre
    IF(@nombrePais IS NULL)
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Nombre invalido.'
    END

    -- Validar que no exista el pais
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.Pais WHERE nombrePais = @nombrePais
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Pais ya existente.'
    END

    -- Insertar Pais
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Selecciones.Pais(nombrePais)
            VALUES (@nombrePais)

            PRINT 'Pais creado exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo crear el registro.'
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo crear el Pais debido a errores de validacion.', 1;
    END
END
GO

PRINT '-- Alta Pais Creado--'
GO


--baja Pais
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.bajaPais'))
    DROP PROCEDURE MfSPabm.bajaPais
GO

CREATE PROCEDURE MfSPabm.bajaPais (@IDPais INT)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar ID
    IF((@IDPais IS NULL) OR (@IDPais <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Pais invalido.'
    END

    -- Validar existencia del pais
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Pais WHERE IDPais = @IDPais
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este Pais.'
    END

    -- Eliminar Pais
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Selecciones.Pais
            WHERE IDPais = @IDPais

            PRINT 'Pais eliminado exitosamente.'
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

PRINT '--Creado SP: bajaPais--'
GO


-- modificacion Pais
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.modificacionPais'))
    DROP PROCEDURE MfSPabm.modificacionPais
GO

CREATE PROCEDURE MfSPabm.modificacionPais (
    @IDPais INT,
    @nombrePais VARCHAR(30)
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDPais IS NULL) OR (@IDPais <= 0) OR (@nombrePais IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar existencia del pais
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Pais WHERE IDPais = @IDPais
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este Pais.'
    END

    -- Validar que el nombre no pertenezca a otro pais
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.Pais 
        WHERE nombrePais = @nombrePais AND IDPais <> @IDPais
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: El nombre ya pertenece a otro Pais.'
    END

    -- Modificar Pais
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Selecciones.Pais
            SET nombrePais = @nombrePais
            WHERE IDPais = @IDPais

            PRINT 'Pais modificado exitosamente'
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

PRINT '--Creado SP: modificacionPais--'
GO





















