/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.AltasBajasConvocados
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.altaAltasBajasConvocados (
    @IDListaConvocados INT,
    @IDSeleccion INT,
    @IDJugador INT,
    @Tipo CHAR(4),
    @Motivo VARCHAR(100),
    @FechaModificacion DATE
)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@IDSeleccion IS NULL) OR (@IDSeleccion <= 0) OR
       (@IDJugador IS NULL) OR (@IDJugador <= 0) OR
       (@Tipo IS NULL) OR (@Motivo IS NULL) OR (@FechaModificacion IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND (@Tipo NOT IN ('ALTA', 'BAJA')))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: El tipo debe ser ALTA o BAJA.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_lista = @IDListaConvocados))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Lista de Convocados.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Seleccion.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_jugador = @IDJugador))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Jugador.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_jugador = @IDJugador AND id_lista_convocados = @IDListaConvocados))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: El jugador no pertenece a esta Lista de Convocados.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados LC INNER JOIN Mundial.Seleccion S ON LC.id_seleccion = S.id_seleccion WHERE LC.id_lista = @IDListaConvocados AND S.id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: La Lista de Convocados no pertenece a esta Seleccion.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Mundial.AltasBajasConvocados(id_lista_convocados, id_seleccion, id_jugador, tipo, motivo, fecha_modificacion)
            VALUES (@IDListaConvocados, @IDSeleccion, @IDJugador, @Tipo, @Motivo, @FechaModificacion);
            PRINT 'Movimiento registrado exitosamente.';
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

CREATE OR ALTER PROCEDURE MfSPabm.bajaAltasBajasConvocados (@IDAltaBaja INT)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDAltaBaja IS NULL) OR (@IDAltaBaja <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Movimiento invalido.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.AltasBajasConvocados WHERE id_alta_baja = @IDAltaBaja))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este movimiento.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Mundial.AltasBajasConvocados WHERE id_alta_baja = @IDAltaBaja;
            PRINT 'Movimiento eliminado exitosamente.';
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

CREATE OR ALTER PROCEDURE MfSPabm.modificacionAltasBajasConvocados (
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
    DECLARE @errorCount INT = 0;

    IF((@IDAltaBaja IS NULL) OR (@IDAltaBaja <= 0) OR
       (@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@IDSeleccion IS NULL) OR (@IDSeleccion <= 0) OR
       (@IDJugador IS NULL) OR (@IDJugador <= 0) OR
       (@Tipo IS NULL) OR (@Motivo IS NULL) OR (@FechaModificacion IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND (@Tipo NOT IN ('ALTA', 'BAJA')))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: El tipo debe ser ALTA o BAJA.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.AltasBajasConvocados WHERE id_alta_baja = @IDAltaBaja))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este movimiento.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_lista = @IDListaConvocados))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Lista de Convocados.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Seleccion.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_jugador = @IDJugador))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Jugador.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_jugador = @IDJugador AND id_lista_convocados = @IDListaConvocados))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: El jugador no pertenece a esta Lista de Convocados.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados LC INNER JOIN Mundial.Seleccion S ON LC.id_seleccion = S.id_seleccion WHERE LC.id_lista = @IDListaConvocados AND S.id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: La Lista de Convocados no pertenece a esta Seleccion.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Mundial.AltasBajasConvocados
            SET id_lista_convocados = @IDListaConvocados, id_seleccion = @IDSeleccion, id_jugador = @IDJugador, tipo = @Tipo, motivo = @Motivo, fecha_modificacion = @FechaModificacion
            WHERE id_alta_baja = @IDAltaBaja;
            PRINT 'Movimiento modificado exitosamente.';
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
