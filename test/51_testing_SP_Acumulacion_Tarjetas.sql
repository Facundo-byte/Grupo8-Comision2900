/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script SPs/26_SP_Acumulacion_Tarjetas.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

PRINT '=== TESTING SP ACUMULACION TARJETAS Y SUSPENSION ===';

DECLARE @sede INT = (SELECT TOP 1 id_sede FROM Mundial.Sede ORDER BY id_sede);
DECLARE @selArg INT = (SELECT s.id_seleccion FROM Mundial.Seleccion s JOIN Mundial.Pais p ON p.id_pais = s.id_pais WHERE p.nombre = 'Argentina');
DECLARE @selBra INT = (SELECT s.id_seleccion FROM Mundial.Seleccion s JOIN Mundial.Pais p ON p.id_pais = s.id_pais WHERE p.nombre = 'Brasil');
DECLARE @jugArg INT = (
    SELECT TOP 1 j.id_jugador
    FROM Mundial.Jugador j
    JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    WHERE lc.id_seleccion = @selArg
    ORDER BY j.dorsal
);
DECLARE @p1 INT, @p2 INT, @p3 INT, @t1 INT, @t2 INT, @tRoja INT, @susp BIT, @mot NVARCHAR(300);

IF @sede IS NULL OR @selArg IS NULL OR @selBra IS NULL OR @jugArg IS NULL
    PRINT 'FALTAN DATOS: ejecutar seeds 28 a 31 primero.';
ELSE
BEGIN
    -- Crear 3 partidos consecutivos para simular acumulacion entre fechas
    EXEC Mundial.Partido_Alta @sede, @selArg, @selBra, '2026-08-01 15:00:00', '2026-08-01 19:00:00', 1, 0, 50000, 'fasedegrupos', @p1 OUTPUT;
    EXEC Mundial.Partido_Alta @sede, @selArg, @selBra, '2026-08-05 15:00:00', '2026-08-05 19:00:00', 2, 1, 52000, 'fasedegrupos', @p2 OUTPUT;
    EXEC Mundial.Partido_Alta @sede, @selArg, @selBra, '2026-08-10 15:00:00', '2026-08-10 19:00:00', 1, 1, 55000, 'octavos de final', @p3 OUTPUT;

    -- Caso 1: Primera amarilla en Partido 1 -> NO suspende
    EXEC Mundial.usp_Registrar_Amonestacion_Y_Verificar_Suspension
        @id_partido = @p1,
        @id_jugador = @jugArg,
        @minuto = 25,
        @motivo = 'Falta tactica fecha 1',
        @color = 'Amarilla',
        @limite_amarillas = 2,
        @id_tarjeta_generada = @t1 OUTPUT,
        @suspendido_proximo_partido = @susp OUTPUT,
        @motivo_suspension = @mot OUTPUT;
    SELECT prueba = 'AC1 Primera amarilla (no suspende)', suspendido = @susp, motivo = @mot;

    -- Caso 2: Segunda amarilla en Partido 2 (partido distinto) -> SUSPENDE por acumulacion
    EXEC Mundial.usp_Registrar_Amonestacion_Y_Verificar_Suspension
        @id_partido = @p2,
        @id_jugador = @jugArg,
        @minuto = 68,
        @motivo = 'Falta reiterada fecha 2',
        @color = 'Amarilla',
        @limite_amarillas = 2,
        @id_tarjeta_generada = @t2 OUTPUT,
        @suspendido_proximo_partido = @susp OUTPUT,
        @motivo_suspension = @mot OUTPUT;
    SELECT prueba = 'AC2 Segunda amarilla acumulada (suspende)', suspendido = @susp, motivo = @mot;

    -- Caso 3: Verificar nomina de habilitados/suspendidos para el Partido 3
    EXEC Mundial.usp_Verificar_Jugadores_Suspendidos_Partido @id_partido = @p3, @id_seleccion = @selArg, @limite_amarillas = 2;

    -- Caso 4: Roja directa en Partido 3 -> genera expulsion y suspension automatica
    EXEC Mundial.usp_Registrar_Amonestacion_Y_Verificar_Suspension
        @id_partido = @p3,
        @id_jugador = @jugArg,
        @minuto = 82,
        @motivo = 'Juego brusco grave',
        @color = 'Roja',
        @id_tarjeta_generada = @tRoja OUTPUT,
        @suspendido_proximo_partido = @susp OUTPUT,
        @motivo_suspension = @mot OUTPUT;
    SELECT prueba = 'AC4 Roja directa (expulsion + suspension)', suspendido = @susp, motivo = @mot;

    -- Caso 5: Jugador de otra seleccion ajena al partido (debe fallar)
    BEGIN TRY
        DECLARE @jugAjeno INT = (
            SELECT TOP 1 j.id_jugador
            FROM Mundial.Jugador j
            JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
            WHERE lc.id_seleccion NOT IN (@selArg, @selBra)
        );
        IF @jugAjeno IS NOT NULL
            EXEC Mundial.usp_Registrar_Amonestacion_Y_Verificar_Suspension @p1, @jugAjeno, 10, 'Test', 'Amarilla';
        ELSE
            THROW 50501, 'Simulacion jugador ajeno', 1;
    END TRY
    BEGIN CATCH
        PRINT 'AC5 Jugador ajeno al partido OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Limpieza
    DELETE FROM Mundial.Expulsion WHERE id_tarjeta IN (@t1, @t2, @tRoja);
    DELETE FROM Mundial.Tarjeta WHERE id_tarjeta IN (@t1, @t2, @tRoja);
    EXEC Mundial.Partido_Baja @p3;
    EXEC Mundial.Partido_Baja @p2;
    EXEC Mundial.Partido_Baja @p1;
END
GO
