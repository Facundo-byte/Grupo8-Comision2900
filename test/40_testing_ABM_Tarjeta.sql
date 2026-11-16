/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/10_ABM_Tarjeta.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

PRINT '=== TESTING ABM TARJETA ===';

DECLARE @idPart INT = (SELECT TOP 1 id_partido FROM Mundial.Partido ORDER BY id_partido);
DECLARE @idJug INT = (SELECT TOP 1 id_jugador FROM Mundial.Jugador ORDER BY id_jugador);
DECLARE @idTar INT;

IF @idPart IS NULL OR @idJug IS NULL
    PRINT 'FALTAN DATOS: se requieren partidos y jugadores.';
ELSE
BEGIN
    -- Caso 1: Alta valida
    EXEC Mundial.Tarjeta_Alta
        @id_partido = @idPart,
        @id_jugador = @idJug,
        @minuto = 35,
        @motivo = 'Falta tactica',
        @color = 'Amarilla',
        @id_tarjeta = @idTar OUTPUT;

    SELECT prueba = 'T1 Alta valida', id_tarjeta = @idTar, minuto, color, motivo FROM Mundial.Tarjeta WHERE id_tarjeta = @idTar;

    -- Caso 2: Color invalido (debe fallar)
    BEGIN TRY
        EXEC Mundial.Tarjeta_Alta
            @id_partido = @idPart,
            @id_jugador = @idJug,
            @minuto = 50,
            @motivo = 'Test',
            @color = 'Azul';
    END TRY
    BEGIN CATCH
        PRINT 'T2 Color invalido OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Caso 3: Modificacion valida
    EXEC Mundial.Tarjeta_Modificar
        @id_tarjeta = @idTar,
        @id_partido = @idPart,
        @id_jugador = @idJug,
        @minuto = 36,
        @motivo = 'Juego brusco',
        @color = 'Amarilla';
    SELECT prueba = 'T3 Modificacion valida', id_tarjeta, minuto, motivo FROM Mundial.Tarjeta WHERE id_tarjeta = @idTar;

    -- Caso 4: Baja valida
    EXEC Mundial.Tarjeta_Baja @id_tarjeta = @idTar;
    SELECT prueba = 'T4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.Tarjeta WHERE id_tarjeta = @idTar;
END
GO
