/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/09_ABM_Gol.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

PRINT '=== TESTING ABM GOL ===';

DECLARE @idPart INT = (SELECT TOP 1 id_partido FROM Mundial.Partido ORDER BY id_partido);
DECLARE @j1 INT = (SELECT MIN(id_jugador) FROM Mundial.Jugador);
DECLARE @j2 INT = (SELECT MAX(id_jugador) FROM Mundial.Jugador);
DECLARE @idGol INT;

IF @idPart IS NULL OR @j1 IS NULL OR @j1 = @j2
    PRINT 'FALTAN DATOS: se requieren partidos y al menos 2 jugadores.';
ELSE
BEGIN
    -- Caso 1: Alta valida con asistencia
    EXEC Mundial.Gol_Alta
        @id_partido = @idPart,
        @id_jugador_autor = @j1,
        @id_jugador_asistencia = @j2,
        @minuto = 23,
        @periodo = 'Primer tiempo',
        @id_gol = @idGol OUTPUT;

    SELECT prueba = 'G1 Alta valida', id_gol = @idGol, minuto, periodo FROM Mundial.Gol WHERE id_gol = @idGol;

    -- Caso 2: Autor y asistente iguales (debe fallar)
    BEGIN TRY
        EXEC Mundial.Gol_Alta
            @id_partido = @idPart,
            @id_jugador_autor = @j1,
            @id_jugador_asistencia = @j1,
            @minuto = 40,
            @periodo = 'Primer tiempo';
    END TRY
    BEGIN CATCH
        PRINT 'G2 Autor=Asistente OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Caso 3: Modificacion valida
    EXEC Mundial.Gol_Modificar
        @id_gol = @idGol,
        @id_partido = @idPart,
        @id_jugador_autor = @j1,
        @id_jugador_asistencia = NULL,
        @minuto = 78,
        @periodo = 'Segundo tiempo';
    SELECT prueba = 'G3 Modificacion valida', id_gol, minuto, periodo, id_jugador_asistencia FROM Mundial.Gol WHERE id_gol = @idGol;

    -- Caso 4: Baja valida
    EXEC Mundial.Gol_Baja @id_gol = @idGol;
    SELECT prueba = 'G4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.Gol WHERE id_gol = @idGol;
END
GO
