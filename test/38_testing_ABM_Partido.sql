/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/08_ABM_Partido.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

PRINT '=== TESTING ABM PARTIDO ===';

DECLARE @sede INT = (SELECT TOP 1 id_sede FROM Mundial.Sede ORDER BY id_sede);
DECLARE @sel1 INT = (SELECT MIN(id_seleccion) FROM Mundial.Seleccion);
DECLARE @sel2 INT = (SELECT MAX(id_seleccion) FROM Mundial.Seleccion);
DECLARE @idPart INT;

IF @sede IS NULL OR @sel1 IS NULL OR @sel1 = @sel2
    PRINT 'FALTAN DATOS: se requieren sedes y al menos 2 selecciones.';
ELSE
BEGIN
    -- Caso 1: Alta valida
    EXEC Mundial.Partido_Alta
        @id_sede = @sede,
        @id_seleccion_local = @sel1,
        @id_seleccion_visitante = @sel2,
        @fecha_hora_local = '2026-07-19 16:00:00',
        @fecha_hora_utc = '2026-07-19 20:00:00',
        @goles_local = 2,
        @goles_visitante = 1,
        @asistencia = 75000,
        @fase = 'final',
        @id_partido = @idPart OUTPUT;

    SELECT prueba = 'PA1 Alta valida', id_partido = @idPart, fase, goles_local, goles_visitante FROM Mundial.Partido WHERE id_partido = @idPart;

    -- Caso 2: Misma seleccion local y visitante (debe fallar)
    BEGIN TRY
        EXEC Mundial.Partido_Alta
            @id_sede = @sede,
            @id_seleccion_local = @sel1,
            @id_seleccion_visitante = @sel1,
            @fecha_hora_local = '2026-07-19 16:00:00',
            @fecha_hora_utc = '2026-07-19 20:00:00';
    END TRY
    BEGIN CATCH
        PRINT 'PA2 Selecciones iguales OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Caso 3: Modificacion valida
    EXEC Mundial.Partido_Modificar
        @id_partido = @idPart,
        @id_sede = @sede,
        @id_seleccion_local = @sel1,
        @id_seleccion_visitante = @sel2,
        @fecha_hora_local = '2026-07-19 16:00:00',
        @fecha_hora_utc = '2026-07-19 20:00:00',
        @goles_local = 3,
        @goles_visitante = 3,
        @asistencia = 80000,
        @fase = 'final';
    SELECT prueba = 'PA3 Modificacion valida', id_partido, goles_local, goles_visitante, asistencia FROM Mundial.Partido WHERE id_partido = @idPart;

    -- Caso 4: Baja valida
    EXEC Mundial.Partido_Baja @id_partido = @idPart;
    SELECT prueba = 'PA4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.Partido WHERE id_partido = @idPart;
END
GO
