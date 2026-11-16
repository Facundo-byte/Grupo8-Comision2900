/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/06_CreacionSPabmJugador.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

DELETE FROM Mundial.Jugador WHERE apellido = 'JugadorPruebaTest';
GO

PRINT '=== TESTING ABM JUGADOR ===';

DECLARE @idLista INT = (SELECT TOP 1 id_lista FROM Mundial.ListaConvocados ORDER BY id_lista);

IF @idLista IS NULL
    PRINT 'FALTAN DATOS: ejecutar 29_seed_convocados_jugadores.sql primero.';
ELSE
BEGIN
    -- Caso 1: Alta valida (dorsal 99)
    EXEC MfSPabm.altaJugador @IDListaConvocados = @idLista, @Nombre = 'Test', @Apellido = 'JugadorPruebaTest', @Dorsal = 99, @Club = 'Club Test';
    DECLARE @idJug INT = (SELECT id_jugador FROM Mundial.Jugador WHERE apellido = 'JugadorPruebaTest');
    SELECT prueba = 'J1 Alta valida', id_jugador = @idJug, nombre, apellido, dorsal, club FROM Mundial.Jugador WHERE id_jugador = @idJug;

    -- Caso 2: Dorsal duplicado en la misma lista (debe fallar)
    BEGIN TRY
        EXEC MfSPabm.altaJugador @IDListaConvocados = @idLista, @Nombre = 'Otro', @Apellido = 'Duplicado', @Dorsal = 99, @Club = 'Club Test';
    END TRY
    BEGIN CATCH
        PRINT 'J2 Dorsal duplicado OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Caso 3: Modificacion valida
    EXEC MfSPabm.modificacionJugador @IDJugador = @idJug, @IDListaConvocados = @idLista, @Nombre = 'TestMod', @Apellido = 'JugadorPruebaTest', @Dorsal = 98, @Club = 'Club Mod';
    SELECT prueba = 'J3 Modificacion valida', id_jugador, nombre, dorsal, club FROM Mundial.Jugador WHERE id_jugador = @idJug;

    -- Caso 4: Baja valida
    EXEC MfSPabm.bajaJugador @IDJugador = @idJug;
    SELECT prueba = 'J4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.Jugador WHERE id_jugador = @idJug;
END
GO
