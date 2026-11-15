
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
abm AltasBajasConvocados
================================================================
*/

--alta AltasBajasConvocados
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.altaAltasBajasConvocados'))
    DROP PROCEDURE MfSPabm.altaAltasBajasConvocados
GO

CREATE PROCEDURE MfSPabm.altaAltasBajasConvocados (
    @IDListaConvocados INT,
    @IDSeleccion INT,
    @IDJugador INT,
    @Tipo CHAR(4),
    @Motivo VARCHAR(100),
    @FechaModificacion DATE
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@IDSeleccion IS NULL) OR (@IDSeleccion <= 0) OR
       (@IDJugador IS NULL) OR (@IDJugador <= 0) OR
       (@Tipo IS NULL) OR (@Motivo IS NULL) OR
       (@FechaModificacion IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar tipo
    IF((@errorCount = 0) AND (@Tipo NOT IN ('ALTA', 'BAJA')))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: El tipo debe ser ALTA o BAJA.'
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

    -- Validar existencia de la seleccion
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Seleccion
        WHERE IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Seleccion.'
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

    -- Validar que el jugador pertenezca a la lista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Jugador
        WHERE IDJugador = @IDJugador
        AND IDListaConvocados = @IDListaConvocados
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: El jugador no pertenece a esta Lista de Convocados.'
    END

    -- Validar que la lista pertenezca a la seleccion
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1
        FROM Selecciones.ListaConvocados LC
        INNER JOIN Selecciones.Seleccion S
            ON LC.IDSeleccion = S.IDSeleccion
        WHERE LC.IDLista = @IDListaConvocados
        AND S.IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: La Lista de Convocados no pertenece a esta Seleccion.'
    END

    -- Insertar movimiento
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Selecciones.AltasBajasConvocados(
                IDListaConvocados, IDSeleccion, IDJugador,
                Tipo, Motivo, FechaModificacion
            )
            VALUES (
                @IDListaConvocados, @IDSeleccion, @IDJugador,
                @Tipo, @Motivo, @FechaModificacion
            )

            PRINT 'Movimiento registrado exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo crear el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo registrar el movimiento debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: altaAltasBajasConvocados--'
GO

--baja AltasBajasConvocados
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.bajaAltasBajasConvocados'))
    DROP PROCEDURE MfSPabm.bajaAltasBajasConvocados
GO

CREATE PROCEDURE MfSPabm.bajaAltasBajasConvocados (@IDAltaBaja INT)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar ID
    IF((@IDAltaBaja IS NULL) OR (@IDAltaBaja <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Movimiento invalido.'
    END

    -- Validar existencia del movimiento
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.AltasBajasConvocados
        WHERE IDAltaBaja = @IDAltaBaja
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este movimiento.'
    END

    -- Eliminar movimiento
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Selecciones.AltasBajasConvocados
            WHERE IDAltaBaja = @IDAltaBaja

            PRINT 'Movimiento eliminado exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo eliminar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50002, 'No se pudo eliminar el movimiento debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: bajaAltasBajasConvocados--'
GO

--modificacion AltasBajasConvocados
IF EXISTS (SELECT name FROM sys.objects WHERE object_id = OBJECT_ID('MfSPabm.modificacionAltasBajasConvocados'))
    DROP PROCEDURE MfSPabm.modificacionAltasBajasConvocados
GO

CREATE PROCEDURE MfSPabm.modificacionAltasBajasConvocados (
    @IDAltaBaja INT,
    @IDListaConvocados INT,
    @IDSeleccion INT,
    @IDJugador INT,
    @Tipo CHAR(4),
    @Motivo VARCHAR(100),
    @FechaModificacion DATE
)
AS
BEGIN
    DECLARE @errorCount INT
    SET @errorCount = 0

    -- Validar datos
    IF((@IDAltaBaja IS NULL) OR (@IDAltaBaja <= 0) OR
       (@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@IDSeleccion IS NULL) OR (@IDSeleccion <= 0) OR
       (@IDJugador IS NULL) OR (@IDJugador <= 0) OR
       (@Tipo IS NULL) OR (@Motivo IS NULL) OR
       (@FechaModificacion IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: Datos invalidos.'
    END

    -- Validar tipo
    IF((@errorCount = 0) AND (@Tipo NOT IN ('ALTA', 'BAJA')))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: El tipo debe ser ALTA o BAJA.'
    END

    -- Validar existencia del movimiento
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.AltasBajasConvocados
        WHERE IDAltaBaja = @IDAltaBaja
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe este movimiento.'
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

    -- Validar existencia de la seleccion
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Seleccion
        WHERE IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: No existe esta Seleccion.'
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

    -- Validar que el jugador pertenezca a la lista
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1 FROM Selecciones.Jugador
        WHERE IDJugador = @IDJugador
        AND IDListaConvocados = @IDListaConvocados
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: El jugador no pertenece a esta Lista de Convocados.'
    END

    -- Validar que la lista pertenezca a la seleccion
    IF((@errorCount = 0) AND NOT EXISTS(
        SELECT 1
        FROM Selecciones.ListaConvocados LC
        INNER JOIN Selecciones.Seleccion S
            ON LC.IDSeleccion = S.IDSeleccion
        WHERE LC.IDLista = @IDListaConvocados
        AND S.IDSeleccion = @IDSeleccion
    ))
    BEGIN
        SET @errorCount = @errorCount + 1
        PRINT 'ERROR: La Lista de Convocados no pertenece a esta Seleccion.'
    END

    -- Modificar movimiento
    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Selecciones.AltasBajasConvocados
            SET IDListaConvocados = @IDListaConvocados,
                IDSeleccion = @IDSeleccion,
                IDJugador = @IDJugador,
                Tipo = @Tipo,
                Motivo = @Motivo,
                FechaModificacion = @FechaModificacion
            WHERE IDAltaBaja = @IDAltaBaja

            PRINT 'Movimiento modificado exitosamente.'
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo modificar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50003, 'No se pudo modificar el movimiento debido a errores de validacion.', 1;
    END
END
GO

PRINT '--Creado SP: modificacionAltasBajasConvocados--'
GO



























