/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Jugador
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.altaJugador (
    @IDListaConvocados INT,
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @Dorsal INT,
    @Club VARCHAR(50)
)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@Nombre IS NULL) OR (@Apellido IS NULL) OR
       (@Dorsal IS NULL) OR (@Dorsal <= 0) OR (@Club IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_lista = @IDListaConvocados))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Lista de Convocados.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_lista_convocados = @IDListaConvocados AND dorsal = @Dorsal))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Ya existe un jugador con ese dorsal en la lista.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Mundial.Jugador(id_lista_convocados, nombre, apellido, dorsal, club)
            VALUES (@IDListaConvocados, @Nombre, @Apellido, @Dorsal, @Club);
            PRINT 'Jugador creado exitosamente.';
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

CREATE OR ALTER PROCEDURE MfSPabm.bajaJugador (@IDJugador INT)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDJugador IS NULL) OR (@IDJugador <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Jugador invalido.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_jugador = @IDJugador))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Jugador.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Mundial.Jugador WHERE id_jugador = @IDJugador;
            PRINT 'Jugador eliminado exitosamente.';
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

CREATE OR ALTER PROCEDURE MfSPabm.modificacionJugador (
    @IDJugador INT,
    @IDListaConvocados INT,
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @Dorsal INT,
    @Club VARCHAR(50)
)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDJugador IS NULL) OR (@IDJugador <= 0) OR
       (@IDListaConvocados IS NULL) OR (@IDListaConvocados <= 0) OR
       (@Nombre IS NULL) OR (@Apellido IS NULL) OR
       (@Dorsal IS NULL) OR (@Dorsal <= 0) OR (@Club IS NULL))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_jugador = @IDJugador))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe este Jugador.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_lista = @IDListaConvocados))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Lista de Convocados.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.Jugador WHERE id_lista_convocados = @IDListaConvocados AND dorsal = @Dorsal AND id_jugador <> @IDJugador))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Ya existe otro jugador con ese dorsal en la lista.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Mundial.Jugador
            SET id_lista_convocados = @IDListaConvocados, nombre = @Nombre, apellido = @Apellido, dorsal = @Dorsal, club = @Club
            WHERE id_jugador = @IDJugador;
            PRINT 'Jugador modificado exitosamente.';
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
