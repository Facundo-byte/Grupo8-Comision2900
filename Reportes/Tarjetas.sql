/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Creacion de la base de datos MundialDeFutbol y de los esquemas Mundial y MfSPabm
*/

use MundialDeFutbol
go

CREATE OR ALTER PROCEDURE MfReportes.Tarjetas_Suspensiones
    @id_seleccion     INT = NULL,   -- NULL = todas las selecciones
    @limite_amarillas INT = 2
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores NVARCHAR(1024) = N'';

    IF @id_seleccion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
        SET @errores += N'La seleccion indicada no existe. ';

    IF @limite_amarillas IS NULL OR @limite_amarillas < 1
        SET @errores += N'El limite de amarillas debe ser al menos 1. ';

    IF @errores <> N''
        THROW 50503, @errores, 1;

    ;WITH
    -- 1) Tarjetas por jugador
    Tarjetas AS (
        SELECT
            t.id_jugador,
            SUM(CASE WHEN t.color = 'Amarilla' THEN 1 ELSE 0 END) AS amarillas,
            SUM(CASE WHEN t.color = 'Roja'     THEN 1 ELSE 0 END) AS rojas
        FROM Mundial.Tarjeta t
        GROUP BY t.id_jugador
    ),
    -- 2) Expulsiones por jugador (con tipo)
    Expulsiones AS (
        SELECT
            t.id_jugador,
            SUM(CASE WHEN e.tipoexpulsion = 'Roja'            THEN 1 ELSE 0 END) AS exp_roja,
            SUM(CASE WHEN e.tipoexpulsion = 'Doble amarilla'  THEN 1 ELSE 0 END) AS exp_doble
        FROM Mundial.Expulsion e
        INNER JOIN Mundial.Tarjeta t ON t.id_tarjeta = e.id_tarjeta
        GROUP BY t.id_jugador
    ),
    -- 3) Último partido jugado por cada selección (para saber si hay "próximo partido")
    UltimoPartido AS (
        SELECT
            s.id_seleccion,
            MAX(p.fecha_hora_utc) AS ultima_fecha
        FROM Mundial.Seleccion s
        INNER JOIN Mundial.Partido p
            ON s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
        GROUP BY s.id_seleccion
    ),
    -- 4) Suspensión activa por jugador (roja o doble amarilla en su último partido,
    --    o acumulación de amarillas en partidos distintos)
    Suspensiones AS (
        SELECT
            j.id_jugador,
            lc.id_seleccion,
            -- Expulsión en el último partido de la selección
            CASE WHEN EXISTS (
                SELECT 1
                FROM Mundial.Tarjeta t
                INNER JOIN Mundial.Expulsion e ON e.id_tarjeta = t.id_tarjeta
                INNER JOIN Mundial.Partido p ON p.id_partido = t.id_partido
                WHERE t.id_jugador = j.id_jugador
                  AND p.fecha_hora_utc = up.ultima_fecha
            ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS suspendido_expulsion,
            -- Acumulación de amarillas (en partidos distintos, sin contar los partidos donde fue expulsado)
            (
                SELECT COUNT(DISTINCT t.id_partido)
                FROM Mundial.Tarjeta t
                INNER JOIN Mundial.Partido p ON p.id_partido = t.id_partido
                WHERE t.id_jugador = j.id_jugador
                  AND t.color = 'Amarilla'
                  AND NOT EXISTS (
                      SELECT 1
                      FROM Mundial.Tarjeta t2
                      INNER JOIN Mundial.Expulsion e2 ON e2.id_tarjeta = t2.id_tarjeta
                      WHERE t2.id_partido = t.id_partido
                        AND t2.id_jugador = t.id_jugador
                  )
            ) AS amarillas_acumuladas
        FROM Mundial.Jugador j
        INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
        INNER JOIN UltimoPartido up ON up.id_seleccion = lc.id_seleccion
    )
    SELECT
        p.nombre                    AS seleccion,
        j.id_jugador,
        j.nombre + ' ' + j.apellido AS jugador,
        j.dorsal,
        ISNULL(tj.amarillas, 0)     AS amarillas,
        ISNULL(tj.rojas, 0)         AS rojas,
        ISNULL(ex.exp_roja, 0)      AS expulsiones_roja,
        ISNULL(ex.exp_doble, 0)     AS expulsiones_doble_amarilla,
        ISNULL(su.amarillas_acumuladas, 0) AS amarillas_acumuladas,
        -- Suspensión activa: por expulsión en el último partido O por acumulación que llegó al límite
        CASE
            WHEN su.suspendido_expulsion = 1 THEN CAST(1 AS BIT)
            WHEN ISNULL(su.amarillas_acumuladas, 0) > 0
                 AND (su.amarillas_acumuladas % @limite_amarillas) = 0 THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END                         AS suspension_activa,
        -- Motivo de la suspensión
        CASE
            WHEN su.suspendido_expulsion = 1
                THEN N'Suspendido por expulsión en el último partido'
            WHEN ISNULL(su.amarillas_acumuladas, 0) > 0
                 AND (su.amarillas_acumuladas % @limite_amarillas) = 0
                THEN N'Suspendido por acumulación de '
                     + CONVERT(NVARCHAR(10), su.amarillas_acumuladas)
                     + N' amarillas'
            ELSE N'Habilitado'
        END                         AS motivo
    FROM Mundial.Jugador j
    INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    INNER JOIN Mundial.Seleccion s        ON s.id_seleccion = lc.id_seleccion
    INNER JOIN Mundial.Pais p             ON p.id_pais = s.id_pais
    LEFT JOIN Tarjetas tj                 ON tj.id_jugador = j.id_jugador
    LEFT JOIN Expulsiones ex              ON ex.id_jugador = j.id_jugador
    LEFT JOIN Suspensiones su             ON su.id_jugador = j.id_jugador
    WHERE @id_seleccion IS NULL OR s.id_seleccion = @id_seleccion
    ORDER BY p.nombre, j.dorsal;
END;
GO

exec MfReportes.Tarjetas_Suspensiones @id_seleccion = 1


