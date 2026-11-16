/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Logica de negocio: Registro de amonestacion/expulsion y calculo parametrizable de suspension por acumulacion
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Registrar_Amonestacion_Y_Verificar_Suspension
    @id_partido INT,
    @id_jugador INT,
    @minuto INT,
    @motivo VARCHAR(100) = NULL,
    @color VARCHAR(20),
    @limite_amarillas INT = 2,
    @fase_limpia_amarillas VARCHAR(20) = 'semifinal',
    @id_tarjeta_generada INT = NULL OUTPUT,
    @suspendido_proximo_partido BIT = 0 OUTPUT,
    @motivo_suspension NVARCHAR(300) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';
    DECLARE @id_seleccion_jugador INT;
    DECLARE @fase_actual VARCHAR(20);
    DECLARE @fecha_partido DATETIME;

    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @errores += N'El partido indicado no existe. ';

    IF @id_jugador IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Jugador WHERE id_jugador = @id_jugador)
        SET @errores += N'El jugador indicado no existe. ';

    IF @minuto IS NULL OR @minuto < 0
        SET @errores += N'El minuto debe ser mayor o igual a cero. ';

    IF @color IS NULL OR @color NOT IN ('Amarilla', 'Roja')
        SET @errores += N'El color debe ser Amarilla o Roja. ';

    IF @limite_amarillas IS NULL OR @limite_amarillas < 1
        SET @errores += N'El limite parametrizable de amarillas debe ser al menos 1. ';

    IF @id_partido IS NOT NULL AND @id_jugador IS NOT NULL AND @errores = N''
    BEGIN
        SELECT @id_seleccion_jugador = lc.id_seleccion
        FROM Mundial.Jugador j
        JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
        WHERE j.id_jugador = @id_jugador;

        IF NOT EXISTS (
            SELECT 1
            FROM Mundial.Partido p
            WHERE p.id_partido = @id_partido
              AND (p.id_seleccion_local = @id_seleccion_jugador OR p.id_seleccion_visitante = @id_seleccion_jugador)
        )
            SET @errores += N'El jugador no pertenece a ninguna de las selecciones que disputan el partido. ';
    END

    IF @errores <> N''
        THROW 50501, @errores, 1;

    SELECT @fase_actual = fase, @fecha_partido = fecha_hora_utc
    FROM Mundial.Partido
    WHERE id_partido = @id_partido;

    SET @suspendido_proximo_partido = 0;
    SET @motivo_suspension = N'Sin suspension pendiente.';

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Registrar la tarjeta mediante el ABM encapsulado
        EXEC Mundial.Tarjeta_Alta
            @id_partido = @id_partido,
            @id_jugador = @id_jugador,
            @minuto = @minuto,
            @motivo = @motivo,
            @color = @color,
            @id_tarjeta = @id_tarjeta_generada OUTPUT;

        -- 2. Si es Roja directa -> genera expulsion y suspension automatica
        IF @color = 'Roja'
        BEGIN
            EXEC Mundial.Expulsion_Alta
                @id_tarjeta = @id_tarjeta_generada,
                @tipoexpulsion = 'Roja';

            SET @suspendido_proximo_partido = 1;
            SET @motivo_suspension = N'Suspension automatica por tarjeta roja directa.';
        END
        ELSE
        BEGIN
            -- 3. Si es Amarilla, verificar si es segunda amarilla en el mismo partido
            DECLARE @amarillas_mismo_partido INT = (
                SELECT COUNT(*)
                FROM Mundial.Tarjeta
                WHERE id_partido = @id_partido
                  AND id_jugador = @id_jugador
                  AND color = 'Amarilla'
            );

            IF @amarillas_mismo_partido >= 2
            BEGIN
                EXEC Mundial.Expulsion_Alta
                    @id_tarjeta = @id_tarjeta_generada,
                    @tipoexpulsion = 'Doble amarilla';

                SET @suspendido_proximo_partido = 1;
                SET @motivo_suspension = N'Suspension automatica por expulsion (doble amarilla en el mismo partido).';
            END
            ELSE
            BEGIN
                -- 4. Evaluar acumulacion en partidos distintos hasta este encuentro (aplicando limpieza por fase si corresponde)
                DECLARE @amarillas_acumuladas INT = (
                    SELECT COUNT(DISTINCT t.id_partido)
                    FROM Mundial.Tarjeta t
                    JOIN Mundial.Partido p ON p.id_partido = t.id_partido
                    WHERE t.id_jugador = @id_jugador
                      AND t.color = 'Amarilla'
                      AND p.fecha_hora_utc <= @fecha_partido
                      -- Si el partido actual es igual o posterior a la fase de limpieza, solo cuentan amarillas desde esa fase
                      AND (
                          @fase_actual <> @fase_limpia_amarillas
                          OR p.fase = @fase_limpia_amarillas
                      )
                      -- No contar partidos donde fue expulsado por doble amarilla (ya cumplio sancion por expulsion)
                      AND NOT EXISTS (
                          SELECT 1
                          FROM Mundial.Tarjeta t2
                          JOIN Mundial.Expulsion e ON e.id_tarjeta = t2.id_tarjeta
                          WHERE t2.id_partido = t.id_partido
                            AND t2.id_jugador = t.id_jugador
                      )
                );

                IF @amarillas_acumuladas > 0 AND (@amarillas_acumuladas % @limite_amarillas) = 0
                BEGIN
                    SET @suspendido_proximo_partido = 1;
                    SET @motivo_suspension = N'Suspension por acumulacion de '
                        + CONVERT(NVARCHAR(10), @amarillas_acumuladas)
                        + N' tarjetas amarillas en partidos distintos (limite vigente: '
                        + CONVERT(NVARCHAR(10), @limite_amarillas) + N').';
                END
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

    SELECT
        @id_partido AS id_partido,
        @id_jugador AS id_jugador,
        @id_tarjeta_generada AS id_tarjeta_generada,
        @color AS tarjeta_registrada,
        @suspendido_proximo_partido AS suspendido_proximo_partido,
        @motivo_suspension AS detalle_estado;
END;
GO

-- Consulta/verificacion previa a armar una formacion: devuelve jugadores habilitados y suspendidos para un partido
CREATE OR ALTER PROCEDURE Mundial.usp_Verificar_Jugadores_Suspendidos_Partido
    @id_partido INT,
    @id_seleccion INT,
    @limite_amarillas INT = 2
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores NVARCHAR(1024) = N'';
    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @errores += N'El partido indicado no existe. ';
    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
        SET @errores += N'La seleccion indicada no existe. ';
    IF @errores <> N''
        THROW 50502, @errores, 1;

    DECLARE @fecha_partido DATETIME = (SELECT fecha_hora_utc FROM Mundial.Partido WHERE id_partido = @id_partido);

    -- Partido inmediatamente anterior jugado por la seleccion
    DECLARE @id_partido_anterior INT = (
        SELECT TOP 1 p.id_partido
        FROM Mundial.Partido p
        WHERE (p.id_seleccion_local = @id_seleccion OR p.id_seleccion_visitante = @id_seleccion)
          AND p.fecha_hora_utc < @fecha_partido
        ORDER BY p.fecha_hora_utc DESC
    );

    SELECT
        j.id_jugador,
        j.nombre,
        j.apellido,
        j.dorsal,
        CASE
            WHEN @id_partido_anterior IS NOT NULL AND EXISTS (
                SELECT 1
                FROM Mundial.Tarjeta t
                JOIN Mundial.Expulsion e ON e.id_tarjeta = t.id_tarjeta
                WHERE t.id_partido = @id_partido_anterior
                  AND t.id_jugador = j.id_jugador
            ) THEN CAST(1 AS BIT)
            WHEN @id_partido_anterior IS NOT NULL AND EXISTS (
                SELECT 1
                FROM Mundial.Tarjeta t_ant
                WHERE t_ant.id_partido = @id_partido_anterior
                  AND t_ant.id_jugador = j.id_jugador
                  AND t_ant.color = 'Amarilla'
            ) AND (
                SELECT COUNT(DISTINCT t.id_partido)
                FROM Mundial.Tarjeta t
                JOIN Mundial.Partido p ON p.id_partido = t.id_partido
                WHERE t.id_jugador = j.id_jugador
                  AND t.color = 'Amarilla'
                  AND p.fecha_hora_utc <= (SELECT fecha_hora_utc FROM Mundial.Partido WHERE id_partido = @id_partido_anterior)
            ) % @limite_amarillas = 0 THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END AS suspendido,
        CASE
            WHEN @id_partido_anterior IS NOT NULL AND EXISTS (
                SELECT 1
                FROM Mundial.Tarjeta t
                JOIN Mundial.Expulsion e ON e.id_tarjeta = t.id_tarjeta
                WHERE t.id_partido = @id_partido_anterior
                  AND t.id_jugador = j.id_jugador
            ) THEN N'Suspendido por expulsion en el partido anterior'
            WHEN @id_partido_anterior IS NOT NULL AND EXISTS (
                SELECT 1
                FROM Mundial.Tarjeta t_ant
                WHERE t_ant.id_partido = @id_partido_anterior
                  AND t_ant.id_jugador = j.id_jugador
                  AND t_ant.color = 'Amarilla'
            ) AND (
                SELECT COUNT(DISTINCT t.id_partido)
                FROM Mundial.Tarjeta t
                JOIN Mundial.Partido p ON p.id_partido = t.id_partido
                WHERE t.id_jugador = j.id_jugador
                  AND t.color = 'Amarilla'
                  AND p.fecha_hora_utc <= (SELECT fecha_hora_utc FROM Mundial.Partido WHERE id_partido = @id_partido_anterior)
            ) % @limite_amarillas = 0 THEN N'Suspendido por acumulacion de amarillas'
            ELSE N'Habilitado'
        END AS estado_disciplinario
    FROM Mundial.Jugador j
    JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    WHERE lc.id_seleccion = @id_seleccion
    ORDER BY j.dorsal;
END;
GO
