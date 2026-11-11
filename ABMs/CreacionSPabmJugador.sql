
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
abm Jugador
================================================================
*/

--alta Jugador
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.altaJugador'))
    DROP PROCEDURE MfSPabm.altaJugador
GO

CREATE PROCEDURE MfSPabm.altaJugador (
    @IDListaConvocados INT,
    @Nombre VARCHAR(20),
    @Apellido VARCHAR(50),
    @Dorsal INT,
    @Club VARCHAR(50)
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@Nombre IS NULL) OR (@Apellido IS NULL) OR
       (@Dorsal IS NULL) OR (@Dorsal <= 0) OR (@Club IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar existencia de la lista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.ListaConvocados
        WHERE IDLista = @IDListaConvocados
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Lista de Convocados.'
    END

    -- Validar que no exista otro jugador con el mismo dorsal en la lista
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.Jugador
        WHERE IDListaConvocados = @IDListaConvocados
        AND Dorsal = @Dorsal
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Ya existe un jugador con ese dorsal en la lista.'
    END

    -- Insertar Jugador
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Selecciones.Jugador(
                IDListaConvocados, Nombre, Apellido, Dorsal, Club
            )
            VALUES (
                @IDListaConvocados, @Nombre, @Apellido, @Dorsal, @Club
            )

            PRINT 'Jugador creado exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo crear el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo crear el Jugador debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: altaJugador--'
GO


--baja Jugador
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.bajaJugador'))
    DROP PROCEDURE MfSPabm.bajaJugador
GO

CREATE PROCEDURE MfSPabm.bajaJugador (@IDJugador INT)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar IDJugador
    IF((@IDJugador IS NULL) OR (@IDJugador <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Jugador invalido.'
    END

    -- Validar existencia del jugador
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Jugador
        WHERE IDJugador = @IDJugador
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este Jugador.'
    END

    -- Eliminar Jugador
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Selecciones.Jugador
            WHERE IDJugador = @IDJugador

            PRINT 'Jugador eliminado exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo eliminar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50002, 'No se pudo eliminar el Jugador debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: bajaJugador--'
GO


--modificacion Jugador
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.modificacionJugador'))
    DROP PROCEDURE MfSPabm.modificacionJugador
GO

CREATE PROCEDURE MfSPabm.modificacionJugador (
    @IDJugador INT,
    @IDListaConvocados INT,
    @Nombre VARCHAR(20),
    @Apellido VARCHAR(50),
    @Dorsal INT,
    @Club VARCHAR(50)
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDJugador IS NULL) OR (@IDJugador <= 0) OR
       (@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@Nombre IS NULL) OR (@Apellido IS NULL) OR
       (@Dorsal IS NULL) OR (@Dorsal <= 0) OR (@Club IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar existencia del jugador
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Jugador
        WHERE IDJugador = @IDJugador
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este Jugador.'
    END

    -- Validar existencia de la lista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.ListaConvocados
        WHERE IDLista = @IDListaConvocados
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Lista de Convocados.'
    END

    -- Validar que otro jugador no tenga el mismo dorsal en la lista
    IF((@errorCount = 0) AND EXISTS(
        SELECT 1 FROM Selecciones.Jugador
        WHERE IDListaConvocados = @IDListaConvocados
        AND Dorsal = @Dorsal
        AND IDJugador <> @IDJugador
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Ya existe otro jugador con ese dorsal en la lista.'
    END

    -- Modificar Jugador
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Selecciones.Jugador
            SET IDListaConvocados = @IDListaConvocados,
                Nombre = @Nombre,
                Apellido = @Apellido,
                Dorsal = @Dorsal,
                Club = @Club
            WHERE IDJugador = @IDJugador

            PRINT 'Jugador modificado exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo modificar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50003, 'No se pudo modificar el Jugador debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: modificacionJugador--'
GO

























