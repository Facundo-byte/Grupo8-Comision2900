/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Logica de negocio: Simulacion de prime time y asignacion priorizada de los 4 espacios publicitarios por partido
*/

USE MundialDeFutbol;
GO

IF TYPE_ID('Mundial.tt_CandidatoPublicidad') IS NULL
    CREATE TYPE Mundial.tt_CandidatoPublicidad AS TABLE
    (
        id_pieza         INT           NOT NULL PRIMARY KEY,
        anunciante       NVARCHAR(100) NOT NULL,
        campania         NVARCHAR(100) NOT NULL,
        id_pais_destino  INT           NOT NULL,
        huso_horario     VARCHAR(10)   NOT NULL, -- Formato 'UTC+HH:MM' o 'UTC-HH:MM'
        pbi_per_capita   DECIMAL(18,2) NOT NULL,
        tarifa_usd       DECIMAL(12,2) NOT NULL
    );
GO

-- Simula para un partido dado en que mercados candidatos el horario UTC cae en prime time (19:00 a 23:00 local)
CREATE OR ALTER PROCEDURE Mundial.usp_Simular_PrimeTime_Partido
    @id_partido INT,
    @candidatos Mundial.tt_CandidatoPublicidad READONLY,
    @hora_inicio_prime INT = 19,
    @hora_fin_prime INT = 23
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores NVARCHAR(1024) = N'';
    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @errores += N'El partido indicado no existe. ';
    IF NOT EXISTS (SELECT 1 FROM @candidatos)
        SET @errores += N'Debe suministrar al menos un mercado/pieza candidata. ';
    IF @errores <> N''
        THROW 50601, @errores, 1;

    DECLARE @fecha_utc DATETIME = (SELECT fecha_hora_utc FROM Mundial.Partido WHERE id_partido = @id_partido);

    SELECT
        c.id_pieza,
        c.anunciante,
        c.campania,
        p.nombre AS pais_destino,
        c.huso_horario,
        @fecha_utc AS fecha_hora_utc,
        DATEADD(
            MINUTE,
            (CASE WHEN SUBSTRING(c.huso_horario, 4, 1) = '-' THEN -1 ELSE 1 END) *
            (CAST(SUBSTRING(c.huso_horario, 5, 2) AS INT) * 60 + CAST(SUBSTRING(c.huso_horario, 8, 2) AS INT)),
            @fecha_utc
        ) AS fecha_hora_local_mercado,
        CASE
            WHEN DATEPART(HOUR, DATEADD(
                MINUTE,
                (CASE WHEN SUBSTRING(c.huso_horario, 4, 1) = '-' THEN -1 ELSE 1 END) *
                (CAST(SUBSTRING(c.huso_horario, 5, 2) AS INT) * 60 + CAST(SUBSTRING(c.huso_horario, 8, 2) AS INT)),
                @fecha_utc
            )) BETWEEN @hora_inicio_prime AND (@hora_fin_prime - 1)
            THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END AS es_prime_time
    FROM @candidatos c
    JOIN Mundial.Pais p ON p.id_pais = c.id_pais_destino
    ORDER BY es_prime_time DESC, c.pbi_per_capita DESC;
END;
GO

-- Selecciona y asigna los 4 espacios publicitarios de la sede del partido aplicando las prioridades de negocio:
-- Prioridad 1: Paises de las selecciones que disputan el partido
-- Prioridad 2: Mercados de mayor poder adquisitivo (PBI per capita)
-- Prioridad 3: Emision en horario prime time (19:00 a 23:00 hora local del mercado destino)
CREATE OR ALTER PROCEDURE Mundial.usp_Asignar_Publicidad_Partido
    @id_partido INT,
    @candidatos Mundial.tt_CandidatoPublicidad READONLY,
    @persistir_en_sede BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';
    DECLARE @id_sede INT, @id_pais_local INT, @id_pais_visitante INT, @fecha_utc DATETIME;

    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @errores += N'El partido indicado no existe. ';

    IF @persistir_en_sede = 1
        SET @errores += N'La propuesta es de consulta. Registre la exhibicion confirmada mediante el ABM de Anuncios_en_Partido. ';

    IF EXISTS (
        SELECT 1
        FROM @candidatos c
        WHERE NOT EXISTS (SELECT 1 FROM Mundial.Pais p WHERE p.id_pais = c.id_pais_destino)
    )
        SET @errores += N'Uno o mas candidatos refieren a un id_pais_destino inexistente. ';

    IF EXISTS (
        SELECT 1
        FROM @candidatos
        WHERE huso_horario NOT LIKE 'UTC[+-][0-1][0-9]:[0-5][0-9]'
    )
        SET @errores += N'Todos los husos horarios candidatos deben respetar el formato UTC+HH:MM o UTC-HH:MM. ';

    IF @errores <> N''
        THROW 50602, @errores, 1;

    SELECT
        @id_sede = p.id_sede,
        @fecha_utc = p.fecha_hora_utc,
        @id_pais_local = sl.id_pais,
        @id_pais_visitante = sv.id_pais
    FROM Mundial.Partido p
    JOIN Mundial.Seleccion sl ON sl.id_seleccion = p.id_seleccion_local
    JOIN Mundial.Seleccion sv ON sv.id_seleccion = p.id_seleccion_visitante
    WHERE p.id_partido = @id_partido;

    DECLARE @seleccionados TABLE (
        numero_espacio   TINYINT PRIMARY KEY,
        id_pieza         INT,
        anunciante       NVARCHAR(100),
        campania         NVARCHAR(150),
        id_pais_destino  INT,
        pais_destino     VARCHAR(60),
        es_pais_partido  BIT,
        pbi_per_capita   DECIMAL(18,2),
        es_prime_time    BIT,
        tarifa_usd       DECIMAL(12,2),
        criterio_aplicado NVARCHAR(150)
    );

    -- Sin candidatos externos, se usan las piezas vigentes y sus mercados registrados.
    ;WITH Mercados AS (
        SELECT c.id_pieza, c.anunciante, c.campania, c.id_pais_destino, c.huso_horario,
               c.pbi_per_capita, c.tarifa_usd
        FROM @candidatos c
        UNION ALL
        SELECT pi.id_pieza, a.nombre, ca.nombre, pm.id_pais, pa.huso_horario,
               pa.pbi_per_capita, NULL
        FROM Mundial.Pieza_publicitaria pi
        JOIN Mundial.Campania ca ON ca.id_campania = pi.id_campania
        JOIN Mundial.Anunciante a ON a.id_anunciante = ca.id_anunciante
        JOIN Mundial.Pieza_Mercado pm ON pm.id_pieza = pi.id_pieza
        JOIN Mundial.Pais pa ON pa.id_pais = pm.id_pais
        WHERE NOT EXISTS (SELECT 1 FROM @candidatos)
          AND @fecha_utc BETWEEN ca.fecha_desde AND ca.fecha_hasta
    ),
    Evaluacion AS (
        SELECT c.id_pieza, c.anunciante, c.campania, c.id_pais_destino,
               pa.nombre AS pais_destino,
               CAST(CASE WHEN pa.id_pais IN (@id_pais_local, @id_pais_visitante) THEN 1 ELSE 0 END AS BIT) AS es_pais_partido,
               c.pbi_per_capita,
               CAST(CASE
                   WHEN pa.hora_inicio_prime < pa.hora_fin_prime AND
                        h.hora_local >= pa.hora_inicio_prime AND h.hora_local < pa.hora_fin_prime THEN 1
                   WHEN pa.hora_inicio_prime > pa.hora_fin_prime AND
                        (h.hora_local >= pa.hora_inicio_prime OR h.hora_local < pa.hora_fin_prime) THEN 1
                   ELSE 0 END AS BIT) AS es_prime_time,
               c.tarifa_usd
        FROM Mercados c
        JOIN Mundial.Pais pa ON pa.id_pais = c.id_pais_destino
        CROSS APPLY (VALUES (CAST(DATEADD(MINUTE,
            CASE WHEN SUBSTRING(c.huso_horario, 4, 1) = '-' THEN -1 ELSE 1 END *
            (60 * TRY_CONVERT(INT, SUBSTRING(c.huso_horario, 5, 2))
                + TRY_CONVERT(INT, SUBSTRING(c.huso_horario, 8, 2))), @fecha_utc) AS TIME))) h(hora_local)
    ),
    MejorMercado AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY id_pieza ORDER BY
            es_pais_partido DESC, pbi_per_capita DESC, es_prime_time DESC, id_pais_destino) AS orden_mercado
        FROM Evaluacion
    ),
    Ranking AS (
        SELECT TOP 4
            ROW_NUMBER() OVER (
                ORDER BY
                    es_pais_partido DESC,
                    pbi_per_capita DESC,
                    es_prime_time DESC,
                    tarifa_usd DESC,
                    id_pieza ASC
            ) AS numero_espacio,
            id_pieza,
            anunciante,
            campania,
            id_pais_destino,
            pais_destino,
            es_pais_partido,
            pbi_per_capita,
            es_prime_time,
            tarifa_usd,
            CASE
                WHEN es_pais_partido = 1 THEN N'Prioridad 1: Pais interviniente en el partido'
                WHEN es_prime_time = 1 THEN N'Prioridad 2/3: Mayor PBI per capita + Prime Time local'
                ELSE N'Prioridad 2: Mayor PBI per capita'
            END AS criterio_aplicado
        FROM MejorMercado
        WHERE orden_mercado = 1
        ORDER BY
            es_pais_partido DESC,
            pbi_per_capita DESC,
            es_prime_time DESC,
            tarifa_usd DESC,
            id_pieza ASC
    )
    INSERT INTO @seleccionados
    SELECT * FROM Ranking;

    IF (SELECT COUNT(*) FROM @seleccionados) <> 4
        THROW 50602, N'Se requieren al menos cuatro piezas distintas para el partido.', 1;

    SELECT
        @id_partido AS id_partido,
        @id_sede AS id_sede,
        numero_espacio,
        id_pieza,
        anunciante,
        campania,
        pais_destino,
        es_pais_partido,
        pbi_per_capita,
        es_prime_time,
        tarifa_usd,
        criterio_aplicado
    FROM @seleccionados
    ORDER BY numero_espacio;
END;
GO
