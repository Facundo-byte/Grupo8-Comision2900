/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Carga inicial de confederaciones, sedes, arbitros, idiomas y ternas arbitrales
*/

USE MundialDeFutbol;
GO

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @confederaciones TABLE (sigla VARCHAR(10) NOT NULL, nombre NVARCHAR(60) NOT NULL);
INSERT INTO @confederaciones (sigla, nombre) VALUES
    ('CONMEBOL', N'Confederación Sudamericana de Fútbol'),
    ('UEFA',     N'Unión de Asociaciones Europeas de Fútbol'),
    ('CONCACAF', N'Confederación de Fútbol de Norte, Centroamérica y el Caribe'),
    ('CAF',      N'Confederación Africana de Fútbol'),
    ('AFC',      N'Confederación Asiática de Fútbol'),
    ('OFC',      N'Confederación de Fútbol de Oceanía');

INSERT INTO Mundial.Confederacion (nombre, sigla)
SELECT c.nombre, c.sigla
FROM @confederaciones AS c
WHERE NOT EXISTS (SELECT 1 FROM Mundial.Confederacion AS x WHERE x.sigla = c.sigla);
PRINT N'Confederaciones cargadas: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);

DECLARE @sedes TABLE (estadio NVARCHAR(100) NOT NULL, ciudad NVARCHAR(100) NOT NULL, pais NVARCHAR(60) NOT NULL, capacidad INT NOT NULL, huso VARCHAR(10) NOT NULL, latitud DECIMAL(9,6) NOT NULL, longitud DECIMAL(9,6) NOT NULL);
INSERT INTO @sedes (estadio, ciudad, pais, capacidad, huso, latitud, longitud) VALUES
    (N'MetLife Stadium',       N'East Rutherford',  N'Estados Unidos', 82500, 'UTC-04:00',  40.813500,  -74.074500),
    (N'Estadio Azteca',        N'Ciudad de México', N'México',         87000, 'UTC-06:00',  19.302900,  -99.150500),
    (N'BMO Field',             N'Toronto',          N'Canadá',         45000, 'UTC-04:00',  43.633200,  -79.418600),
    (N'BC Place',              N'Vancouver',        N'Canadá',         54000, 'UTC-07:00',  49.276800, -123.112000),
    (N'AT&T Stadium',          N'Arlington',        N'Estados Unidos', 80000, 'UTC-05:00',  32.747300,  -97.094500),
    (N'Mercedes-Benz Stadium', N'Atlanta',          N'Estados Unidos', 71000, 'UTC-04:00',  33.755400,  -84.400800),
    (N'SoFi Stadium',          N'Inglewood',        N'Estados Unidos', 70000, 'UTC-07:00',  33.953500, -118.339200),
    (N'Hard Rock Stadium',     N'Miami Gardens',    N'Estados Unidos', 65000, 'UTC-04:00',  25.958000,  -80.238900);

INSERT INTO Mundial.Sede (nombre_estadio, ciudad, id_pais, capacidad, huso_horario, latitud, longitud)
SELECT s.estadio, s.ciudad, p.id_pais, s.capacidad, s.huso, s.latitud, s.longitud
FROM @sedes AS s
JOIN Mundial.Pais AS p ON p.nombre = s.pais
WHERE NOT EXISTS (SELECT 1 FROM Mundial.Sede AS x WHERE x.nombre_estadio = s.estadio AND x.ciudad = s.ciudad AND x.id_pais = p.id_pais);
PRINT N'Sedes cargadas: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);

DECLARE @arbitros TABLE (nombre NVARCHAR(50) NOT NULL, apellido NVARCHAR(50) NOT NULL, nacimiento DATE NOT NULL, pais NVARCHAR(60) NOT NULL, sigla VARCHAR(10) NOT NULL, categoria NVARCHAR(20) NOT NULL);
INSERT INTO @arbitros (nombre, apellido, nacimiento, pais, sigla, categoria) VALUES
    (N'Facundo',  N'Tello',      '1983-05-01', N'Argentina',      'CONMEBOL', N'FIFA'),
    (N'Raphael',  N'Claus',      '1982-09-06', N'Brasil',         'CONMEBOL', N'FIFA'),
    (N'Wilmar',   N'Roldán',     '1980-01-23', N'Colombia',       'CONMEBOL', N'FIFA'),
    (N'Andrés',   N'Matonte',    '1988-03-24', N'Uruguay',        'CONMEBOL', N'FIFA'),
    (N'Piero',    N'Maza',       '1984-10-25', N'Chile',          'CONMEBOL', N'CONFEDERACION'),
    (N'Anthony',  N'Taylor',     '1978-10-20', N'Inglaterra',     'UEFA',     N'FIFA'),
    (N'Slavko',   N'Vincic',     '1979-11-25', N'Eslovenia',      'UEFA',     N'FIFA'),
    (N'Clement',  N'Turpin',     '1982-05-16', N'Francia',        'UEFA',     N'FIFA'),
    (N'Felix',    N'Zwayer',     '1981-05-19', N'Alemania',       'UEFA',     N'FIFA'),
    (N'Szymon',   N'Marciniak',  '1981-01-07', N'Polonia',        'UEFA',     N'FIFA'),
    (N'César',    N'Ramos',      '1983-12-05', N'México',         'CONCACAF', N'FIFA'),
    (N'Ismail',   N'Elfath',     '1982-03-29', N'Estados Unidos', 'CONCACAF', N'FIFA'),
    (N'Drew',     N'Fischer',    '1981-09-01', N'Canadá',         'CONCACAF', N'CONFEDERACION'),
    (N'Yoshimi',  N'Yamashita',  '1986-02-20', N'Japón',          'AFC',      N'FIFA'),
    (N'Mustapha', N'Ghorbal',    '1985-08-19', N'Marruecos',      'CAF',      N'FIFA');

INSERT INTO Mundial.Arbitro (nombre, apellido, fecha_nacimiento, id_pais, id_confederacion, categoria, habilitado)
SELECT a.nombre, a.apellido, a.nacimiento, p.id_pais, c.id_confederacion, a.categoria, 1
FROM @arbitros AS a
JOIN Mundial.Pais AS p ON p.nombre = a.pais
JOIN Mundial.Confederacion AS c ON c.sigla = a.sigla
WHERE NOT EXISTS (SELECT 1 FROM Mundial.Arbitro AS x WHERE x.nombre = a.nombre AND x.apellido = a.apellido AND x.fecha_nacimiento = a.nacimiento AND x.id_pais = p.id_pais);
PRINT N'Árbitros cargados: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);

INSERT INTO Mundial.Idioma (id_arbitro, idioma)
SELECT a.id_arbitro, N'Inglés'
FROM Mundial.Arbitro AS a
WHERE NOT EXISTS (SELECT 1 FROM Mundial.Idioma AS x WHERE x.id_arbitro = a.id_arbitro AND x.idioma = N'Inglés');

DECLARE @idiomas TABLE (pais NVARCHAR(60) NOT NULL, idioma NVARCHAR(50) NOT NULL);
INSERT INTO @idiomas (pais, idioma) VALUES
    (N'Argentina', N'Español'), (N'Brasil', N'Portugués'), (N'Colombia', N'Español'),
    (N'Uruguay', N'Español'), (N'Chile', N'Español'), (N'México', N'Español'),
    (N'Francia', N'Francés'), (N'Alemania', N'Alemán'), (N'Polonia', N'Polaco'),
    (N'Portugal', N'Portugués'), (N'Eslovenia', N'Esloveno'), (N'Japón', N'Japonés'), (N'Marruecos', N'Árabe');

INSERT INTO Mundial.Idioma (id_arbitro, idioma)
SELECT a.id_arbitro, i.idioma
FROM Mundial.Arbitro AS a
JOIN Mundial.Pais AS p ON p.id_pais = a.id_pais
JOIN @idiomas AS i ON i.pais = p.nombre
WHERE NOT EXISTS (SELECT 1 FROM Mundial.Idioma AS x WHERE x.id_arbitro = a.id_arbitro AND x.idioma = i.idioma);
PRINT N'Idiomas cargados: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);

IF OBJECT_ID(N'Mundial.Partido', N'U') IS NOT NULL
BEGIN
    INSERT INTO Mundial.Terna_Arbitral
        (id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2, id_cuarto_arbitro, id_arbitro_var, estado, motivo_descarte)
    SELECT p.id_partido, a1.id_arbitro, a2.id_arbitro, a3.id_arbitro, a4.id_arbitro, a5.id_arbitro, N'Activa', NULL
    FROM (SELECT TOP (24) id_partido, id_seleccion_local, id_seleccion_visitante FROM Mundial.Partido ORDER BY id_partido) AS p
    CROSS APPLY (SELECT a.id_arbitro FROM Mundial.Arbitro AS a WHERE a.habilitado = 1 AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion AS s WHERE s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante) AND s.id_pais = a.id_pais) ORDER BY (a.id_arbitro * 7 + p.id_partido * 13) % 97, a.id_arbitro OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) AS a1
    CROSS APPLY (SELECT a.id_arbitro FROM Mundial.Arbitro AS a WHERE a.habilitado = 1 AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion AS s WHERE s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante) AND s.id_pais = a.id_pais) ORDER BY (a.id_arbitro * 7 + p.id_partido * 13) % 97, a.id_arbitro OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY) AS a2
    CROSS APPLY (SELECT a.id_arbitro FROM Mundial.Arbitro AS a WHERE a.habilitado = 1 AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion AS s WHERE s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante) AND s.id_pais = a.id_pais) ORDER BY (a.id_arbitro * 7 + p.id_partido * 13) % 97, a.id_arbitro OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY) AS a3
    CROSS APPLY (SELECT a.id_arbitro FROM Mundial.Arbitro AS a WHERE a.habilitado = 1 AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion AS s WHERE s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante) AND s.id_pais = a.id_pais) ORDER BY (a.id_arbitro * 7 + p.id_partido * 13) % 97, a.id_arbitro OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY) AS a4
    CROSS APPLY (SELECT a.id_arbitro FROM Mundial.Arbitro AS a WHERE a.habilitado = 1 AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion AS s WHERE s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante) AND s.id_pais = a.id_pais) ORDER BY (a.id_arbitro * 7 + p.id_partido * 13) % 97, a.id_arbitro OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY) AS a5
    WHERE NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral AS t WHERE t.id_partido = p.id_partido AND t.estado = N'Activa');
    PRINT N'Ternas activas cargadas: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);
END
GO
