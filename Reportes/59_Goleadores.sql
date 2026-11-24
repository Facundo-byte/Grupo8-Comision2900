/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures de reportes sobre maximos goleadores
*/

USE MundialDeFutbol;
GO

IF SCHEMA_ID('MfReportes') IS NULL EXEC('CREATE SCHEMA MfReportes');
GO


CREATE OR ALTER PROCEDURE MfReportes.Goleadores_PorSeleccion
    @id_seleccion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
    BEGIN
        ;THROW 50401, N'id_seleccion invalido o inexistente.', 1;
    END
       
    SELECT
        p.nombre                AS seleccion,
        j.id_jugador,
        j.nombre + ' ' + j.apellido AS jugador,
        j.dorsal,
        COUNT(g.id_gol)         AS goles,
        SUM(CASE WHEN g.tipo = 'Penal'    THEN 1 ELSE 0 END) AS goles_penal,
        SUM(CASE WHEN g.tipo = 'Cabezazo' THEN 1 ELSE 0 END) AS goles_cabeza,
        SUM(CASE WHEN g.tipo = 'Tiro libre' THEN 1 ELSE 0 END) AS goles_tiro_libre
    FROM Mundial.Jugador j
    JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    JOIN Mundial.Seleccion s        ON s.id_seleccion = lc.id_seleccion
    join Mundial.Pais p on p.id_pais = s.id_pais
    join Mundial.Gol g              ON g.id_jugador_autor = j.id_jugador
    WHERE s.id_seleccion = @id_seleccion
    GROUP BY p.nombre, j.id_jugador, j.nombre, j.apellido, j.dorsal
    ORDER BY goles DESC, j.apellido ASC;
END;
GO

EXEC MfReportes.Goleadores_PorSeleccion @id_seleccion = 100;  -- Argentina
go


CREATE OR ALTER PROCEDURE MfReportes.Goleadores_PorFase
    @fase VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(2048)

    IF @fase IS NULL OR @fase NOT IN (
        'fasedegrupos',
        'octavos de final',
        'cuartos de final',
        'semifinal',
        'tercer puesto',
        'final'
    )
    BEGIN
        ;THROW 50401, N'fase invalida. Valores: fasedegrupos, octavos de final, cuartos de final, semifinal, tercer puesto, final. ', 1;
    END

    SELECT
        p.nombre                AS seleccion,
        j.id_jugador,
        j.nombre + ' ' + j.apellido AS jugador,
        j.dorsal,
        COUNT(g.id_gol)         AS goles,
        SUM(CASE WHEN g.tipo = 'Penal'    THEN 1 ELSE 0 END) AS goles_penal,
        SUM(CASE WHEN g.tipo = 'Cabezazo' THEN 1 ELSE 0 END) AS goles_cabeza
    FROM Mundial.Gol g
    INNER JOIN Mundial.Partido pa         ON pa.id_partido = g.id_partido
    INNER JOIN Mundial.Jugador j          ON j.id_jugador = g.id_jugador_autor
    INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    INNER JOIN Mundial.Seleccion s        ON s.id_seleccion = lc.id_seleccion
    INNER JOIN Mundial.Pais p             ON p.id_pais = s.id_pais
    WHERE pa.fase = @fase
    GROUP BY p.nombre, j.id_jugador, j.nombre, j.apellido, j.dorsal
    ORDER BY goles DESC, j.apellido ASC;
END;
GO

exec MfReportes.Goleadores_PorFase 'fase de grupos'
go

CREATE OR ALTER PROCEDURE MfReportes.Goleadores_Torneo
    @top INT = NULL   -- opcional: limitar a los N primeros
AS
BEGIN
    SET NOCOUNT ON;

    IF @top IS NOT NULL AND @top <= 0
    BEGIN
        ;THROW 51103, N'@top debe ser mayor a 0. ', 1;
    END

    ;WITH Ranking AS (
        SELECT
            p.nombre                AS seleccion,
            j.id_jugador,
            j.nombre + ' ' + j.apellido AS jugador,
            j.dorsal,
            COUNT(g.id_gol)         AS goles,
            SUM(CASE WHEN g.tipo = 'Penal'    THEN 1 ELSE 0 END) AS goles_penal,
            SUM(CASE WHEN g.tipo = 'Cabezazo' THEN 1 ELSE 0 END) AS goles_cabeza,
            SUM(CASE WHEN g.tipo = 'Tiro libre' THEN 1 ELSE 0 END) AS goles_tiro_libre,
            SUM(CASE WHEN g.tipo = 'En contra' THEN 1 ELSE 0 END) AS goles_en_contra,
            ROW_NUMBER() OVER (ORDER BY COUNT(g.id_gol) DESC, j.apellido ASC) AS posicion
        FROM Mundial.Gol g
        INNER JOIN Mundial.Jugador j          ON j.id_jugador = g.id_jugador_autor
        INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
        INNER JOIN Mundial.Seleccion s        ON s.id_seleccion = lc.id_seleccion
        INNER JOIN Mundial.Pais p             ON p.id_pais = s.id_pais
        GROUP BY p.nombre, j.id_jugador, j.nombre, j.apellido, j.dorsal
    )
    SELECT
        posicion,
        seleccion,
        id_jugador,
        jugador,
        dorsal,
        goles,
        goles_penal,
        goles_cabeza,
        goles_tiro_libre,
        goles_en_contra
    FROM Ranking
    WHERE @top IS NULL OR posicion <= @top
    ORDER BY posicion;
END;
GO

MfReportes.Goleadores_Torneo 10
go
















