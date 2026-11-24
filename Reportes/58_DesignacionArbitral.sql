/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures de reportes sobre designaciones arbitrales
*/

use MundialDeFutbol
go

CREATE OR ALTER PROCEDURE MfReportes.PartidosPorArbitro
    @id_arbitro INT = NULL   -- NULL = todos los árbitros
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_arbitro IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_arbitro = @id_arbitro)
    BEGIN
        ;THROW 50401, N'id_arbitro invalido o inexistente.', 1;
    END

    SELECT
        a.id_arbitro,
        a.nombre                          AS nombre_arbitro,
        a.apellido                        AS apellido_arbitro,
        p_arb.nombre                      AS nacionalidad_arbitro,
        a.categoria,
        par.id_partido,
        par.fase,
        par.fecha_hora_utc,
        p_loc.nombre                      AS pais_local,
        p_vis.nombre                      AS pais_visitante,
        arbt.rol                          AS rol_en_terna,
        ta.estado                         AS estado_terna,
        -- Solo si es Principal: conteos de tarjetas/expulsiones del partido
        CASE WHEN arbt.rol = 'Principal' THEN (
            SELECT COUNT(*)
            FROM Mundial.Tarjeta t
            WHERE t.id_partido = par.id_partido
              AND t.color = 'Amarilla'
        ) ELSE NULL END                    AS amarillas_mostradas,
        CASE WHEN arbt.rol = 'Principal' THEN (
            SELECT COUNT(*)
            FROM Mundial.Tarjeta t
            WHERE t.id_partido = par.id_partido
              AND t.color = 'Roja'
        ) ELSE NULL END                    AS rojas_mostradas,
        CASE WHEN arbt.rol = 'Principal' THEN (
            SELECT COUNT(*)
            FROM Mundial.Expulsion e
            INNER JOIN Mundial.Tarjeta t ON t.id_tarjeta = e.id_tarjeta
            WHERE t.id_partido = par.id_partido
        ) ELSE NULL END                    AS expulsiones_totales

    FROM Mundial.Arbitro a
    INNER JOIN Mundial.Pais p_arb            ON p_arb.id_pais         = a.id_pais
    INNER JOIN Mundial.Arbitro_Terna arbt    ON arbt.id_arbitro       = a.id_arbitro
    INNER JOIN Mundial.Terna_Arbitral ta     ON ta.id_terna           = arbt.id_terna
    INNER JOIN Mundial.Partido par           ON par.id_partido        = ta.id_partido
    INNER JOIN Mundial.Seleccion s_loc       ON s_loc.id_seleccion    = par.id_seleccion_local
    INNER JOIN Mundial.Pais p_loc            ON p_loc.id_pais         = s_loc.id_pais
    INNER JOIN Mundial.Seleccion s_vis       ON s_vis.id_seleccion    = par.id_seleccion_visitante
    INNER JOIN Mundial.Pais p_vis            ON p_vis.id_pais         = s_vis.id_pais
    WHERE @id_arbitro IS NULL OR a.id_arbitro = @id_arbitro
    ORDER BY a.apellido, a.nombre, par.fecha_hora_utc;
END;
GO

exec MfReportes.PartidosPorArbitro 
















