/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Creacion Stored Procedura Para matriz Prime Time
*/

Use MundialDeFutbol
go

CREATE OR ALTER PROCEDURE MfReportes.Matriz_PrimeTime
    @hora_inicio TIME = '18:00',
    @hora_fin    TIME = '23:00',
    @fase        VARCHAR(20) = NULL   -- NULL = todas las fases
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores NVARCHAR(1024) = N'';

    IF @hora_inicio IS NULL OR @hora_fin IS NULL OR @hora_inicio >= @hora_fin
        SET @errores += N'La franja horaria es invalida (inicio debe ser menor que fin). ';

    IF @fase IS NOT NULL AND @fase NOT IN ('fasedegrupos','octavos de final','cuartos de final',
                                           'semifinal','tercer puesto','final')
        SET @errores += N'Fase invalida. ';

    IF @errores <> N''
        THROW 51201, @errores, 1;

    -- 1) Armo la base: partido + país mercado + hora local + flag prime time
    ;WITH Base AS (
        SELECT
            p.id_partido,
            p.fase,
            p.fecha_hora_utc,
            pa.id_pais          AS id_pais_mercado,
            pa.nombre           AS pais_mercado,
            pa.huso_horario,
            -- Hora local = UTC + offset del huso
            CAST(
                DATEADD(MINUTE,
                    CASE
                        WHEN pa.huso_horario LIKE 'UTC+%' THEN
                            (CAST(SUBSTRING(pa.huso_horario, 5, 2) AS INT) * 60)
                          + (CAST(SUBSTRING(pa.huso_horario, 8, 2) AS INT))
                        WHEN pa.huso_horario LIKE 'UTC-%' THEN
                          - (CAST(SUBSTRING(pa.huso_horario, 5, 2) AS INT) * 60)
                          - (CAST(SUBSTRING(pa.huso_horario, 8, 2) AS INT))
                        ELSE 0
                    END,
                    p.fecha_hora_utc
                ) AS TIME
            ) AS hora_local
        FROM Mundial.Partido p
        CROSS JOIN Mundial.Pais pa
        WHERE pa.huso_horario IS NOT NULL
          AND (@fase IS NULL OR p.fase = @fase)
    ),
    -- 2) Marco prime time
    Marcado AS (
        SELECT
            id_partido,
            fase,
            fecha_hora_utc,
            pais_mercado,
            hora_local,
            CASE
                WHEN hora_local >= @hora_inicio AND hora_local < @hora_fin THEN 1
                ELSE 0
            END AS prime_time
        FROM Base
    )
    -- 3) Pivot dinámico: una columna por país
    SELECT
        id_partido,
        fase,
        fecha_hora_utc,
        -- Pivot manual con MAX(CASE ...) para los países del torneo
        MAX(CASE WHEN pais_mercado = 'Argentina'      THEN prime_time END) AS [Argentina],
        MAX(CASE WHEN pais_mercado = 'Brasil'         THEN prime_time END) AS [Brasil],
        MAX(CASE WHEN pais_mercado = 'Uruguay'        THEN prime_time END) AS [Uruguay],
        MAX(CASE WHEN pais_mercado = 'Colombia'       THEN prime_time END) AS [Colombia],
        MAX(CASE WHEN pais_mercado = 'Ecuador'        THEN prime_time END) AS [Ecuador],
        MAX(CASE WHEN pais_mercado = 'Paraguay'       THEN prime_time END) AS [Paraguay],
        MAX(CASE WHEN pais_mercado = 'Francia'        THEN prime_time END) AS [Francia],
        MAX(CASE WHEN pais_mercado = 'España'         THEN prime_time END) AS [España],
        MAX(CASE WHEN pais_mercado = 'Alemania'       THEN prime_time END) AS [Alemania],
        MAX(CASE WHEN pais_mercado = 'Inglaterra'     THEN prime_time END) AS [Inglaterra],
        MAX(CASE WHEN pais_mercado = 'Italia'         THEN prime_time END) AS [Italia],
        MAX(CASE WHEN pais_mercado = 'Portugal'       THEN prime_time END) AS [Portugal],
        MAX(CASE WHEN pais_mercado = 'Paises Bajos'   THEN prime_time END) AS [Países Bajos],
        MAX(CASE WHEN pais_mercado = 'Bélgica'        THEN prime_time END) AS [Bélgica],
        MAX(CASE WHEN pais_mercado = 'Croacia'        THEN prime_time END) AS [Croacia],
        MAX(CASE WHEN pais_mercado = 'Noruega'      THEN prime_time END) AS [Dinamarca],
        MAX(CASE WHEN pais_mercado = 'Suiza'          THEN prime_time END) AS [Suiza],
        MAX(CASE WHEN pais_mercado = 'Serbia'         THEN prime_time END) AS [Serbia],
        MAX(CASE WHEN pais_mercado = 'Polonia'        THEN prime_time END) AS [Polonia],
        MAX(CASE WHEN pais_mercado = 'Austria'        THEN prime_time END) AS [Austria],
        MAX(CASE WHEN pais_mercado = 'México'         THEN prime_time END) AS [México],
        MAX(CASE WHEN pais_mercado = 'USA' THEN prime_time END) AS [Estados Unidos],
        MAX(CASE WHEN pais_mercado = 'Canadá'         THEN prime_time END) AS [Canadá],
        MAX(CASE WHEN pais_mercado = 'Costa Rica'     THEN prime_time END) AS [Costa Rica],
        MAX(CASE WHEN pais_mercado = 'Marruecos'      THEN prime_time END) AS [Marruecos],
        MAX(CASE WHEN pais_mercado = 'Senegal'        THEN prime_time END) AS [Senegal],
        MAX(CASE WHEN pais_mercado = 'Nigeria'        THEN prime_time END) AS [Nigeria],
        MAX(CASE WHEN pais_mercado = 'Egipto'         THEN prime_time END) AS [Egipto],
        MAX(CASE WHEN pais_mercado = 'Costa de Marfil'        THEN prime_time END) AS [Camerún],
        MAX(CASE WHEN pais_mercado = 'Japon'          THEN prime_time END) AS [Japón],
        MAX(CASE WHEN pais_mercado = 'Corea del Sur'  THEN prime_time END) AS [Corea del Sur],
        MAX(CASE WHEN pais_mercado = 'Australia'      THEN prime_time END) AS [Australia]
    FROM Marcado
    GROUP BY id_partido, fase, fecha_hora_utc
    ORDER BY fecha_hora_utc;
END;
GO

EXEC MfReportes.Matriz_PrimeTime


