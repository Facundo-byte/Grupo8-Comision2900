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
abm Seleccion
================================================================
*/

--alta Seleccion
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.altaSeleccion'))
    DROP PROCEDURE MfSPabm.altaSeleccion
GO

CREATE PROCEDURE MfSPabm.altaSeleccion (
    @IDPais INT,
    @Confederacion VARCHAR(30),
    @Grupo CHAR
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDPais IS NULL) OR (@IDPais <= 0) OR (@Confederacion IS NULL) OR (@Grupo IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar que el pais exista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Pais WHERE IDPais = @IDPais
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este Pais.'
    END

    -- Validar que el pais no tenga una seleccion asociada
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.Seleccion WHERE IDPais = @IDPais
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Este Pais ya tiene una Seleccion asociada.'
    END

    -- Insertar Seleccion
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Selecciones.Seleccion(IDPais, Confederacion, Grupo)
            VALUES (@IDPais, @Confederacion, @Grupo)

            PRINT 'Seleccion creada exitosamente.'
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

PRINT '--Creado SP: altaSeleccion--'
GO

--baja Seleccion
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.bajaSeleccion'))
    DROP PROCEDURE MfSPabm.bajaSeleccion
GO

CREATE PROCEDURE MfSPabm.bajaSeleccion (@IDSeleccion INT)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar ID
    IF((@IDSeleccion IS NULL) OR (@IDSeleccion <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Seleccion invalida.'
    END

    -- Validar existencia de la seleccion
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Seleccion WHERE IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Seleccion.'
    END

    -- Eliminar Seleccion
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Selecciones.Seleccion
            WHERE IDSeleccion = @IDSeleccion

            PRINT 'Seleccion eliminada exitosamente.'
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

PRINT '--Creado SP: bajaSeleccion--'
GO

--modificacion Seleccion
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.modificacionSeleccion'))
    DROP PROCEDURE MfSPabm.modificacionSeleccion
GO

CREATE PROCEDURE MfSPabm.modificacionSeleccion (
    @IDSeleccion INT,
    @IDPais INT,
    @Confederacion VARCHAR(30),
    @Grupo CHAR
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDSeleccion IS NULL) OR (@IDSeleccion <= 0) OR
       (@IDPais IS NULL) OR (@IDPais <= 0) OR
       (@Confederacion IS NULL) OR (@Grupo IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar existencia de la seleccion
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Seleccion WHERE IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Seleccion.'
    END

    -- Validar existencia del pais
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Pais WHERE IDPais = @IDPais
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este Pais.'
    END

    -- Validar que otro registro no tenga asociado el mismo pais
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.Seleccion
        WHERE IDPais = @IDPais AND IDSeleccion <> @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Este Pais ya tiene otra Seleccion asociada.'
    END

    -- Modificar Seleccion
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Selecciones.Seleccion
            SET IDPais = @IDPais,
                Confederacion = @Confederacion,
                Grupo = @Grupo
            WHERE IDSeleccion = @IDSeleccion

            PRINT 'Seleccion modificada exitosamente.'
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

PRINT '--Creado SP: modificacionSeleccion--'
GO




























