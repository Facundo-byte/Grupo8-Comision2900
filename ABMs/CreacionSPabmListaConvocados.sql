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
abm ListaConvocados
================================================================
*/

--alta ListaConvocados
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.altaListaConvocados'))
    DROP PROCEDURE MfSPabm.altaListaConvocados
GO

CREATE PROCEDURE MfSPabm.altaListaConvocados (@IDSeleccion INT)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar IDSeleccion
    IF((@IDSeleccion IS NULL) OR (@IDSeleccion <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Seleccion invalida.'
    END

    -- Validar que la seleccion exista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Seleccion WHERE IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Seleccion.'
    END

    -- Validar que no tenga una lista asociada
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.ListaConvocados WHERE IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Esta Seleccion ya tiene una Lista de Convocados.'
    END

    -- Insertar Lista
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Selecciones.ListaConvocados(IDSeleccion)
            VALUES (@IDSeleccion)

            PRINT 'Lista de Convocados creada exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo crear el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo crear la Lista de Convocados debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: altaListaConvocados--'
GO

--baja ListaConvocados
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.bajaListaConvocados'))
    DROP PROCEDURE MfSPabm.bajaListaConvocados
GO

CREATE PROCEDURE MfSPabm.bajaListaConvocados (@IDLista INT)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar IDLista
    IF((@IDLista IS NULL) OR (@IDLista <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Lista de Convocados invalida.'
    END

    -- Validar existencia de la lista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.ListaConvocados WHERE IDLista = @IDLista
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Lista de Convocados.'
    END

    -- Eliminar Lista
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Selecciones.ListaConvocados
            WHERE IDLista = @IDLista

            PRINT 'Lista de Convocados eliminada exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo eliminar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50002, 'No se pudo eliminar la Lista de Convocados debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: bajaListaConvocados--'
GO


--modificacion ListaConvocados
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.modificacionListaConvocados'))
    DROP PROCEDURE MfSPabm.modificacionListaConvocados
GO

CREATE PROCEDURE MfSPabm.modificacionListaConvocados (
    @IDLista INT,
    @IDSeleccion INT
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDLista IS NULL) OR (@IDLista <= 0) OR
       (@IDSeleccion IS NULL) OR (@IDSeleccion <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar existencia de la lista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.ListaConvocados WHERE IDLista = @IDLista
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Lista de Convocados.'
    END

    -- Validar existencia de la seleccion
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Seleccion WHERE IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Seleccion.'
    END

    -- Validar que otra lista no tenga asociada la misma seleccion
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.ListaConvocados
        WHERE IDSeleccion = @IDSeleccion AND IDLista <> @IDLista
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Esta Seleccion ya tiene otra Lista de Convocados.'
    END

    -- Modificar Lista
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Selecciones.ListaConvocados
            SET IDSeleccion = @IDSeleccion
            WHERE IDLista = @IDLista

            PRINT 'Lista de Convocados modificada exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo modificar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50003, 'No se pudo modificar la Lista de Convocados debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: modificacionListaConvocados--'
GO


























