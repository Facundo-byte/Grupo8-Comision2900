USE MundialDeFutbol;
GO
SET NOCOUNT ON;

/*
============================================================
Inserto Paises
============================================================ 
*/

/*
============================================================
Paises Conmebol
============================================================
*/
--Inserto Argentina
exec MfSPabm.altaPais 'Argentina'
go

--Inserto Brasil
exec MfSPabm.altaPais 'Brasil'
go

--Inserto Uruguay
exec MfSPabm.altaPais 'Uruguay'
go

--Inserto Colombia
exec MfSPabm.altaPais 'Colombia'
go

--Inserto Ecuador
exec MfSPabm.altaPais 'Ecuador'
go

--Inserto Paraguay
exec MfSPabm.altaPais 'Paraguay'
go

/*
============================================================
Paises UEFA
============================================================
*/

--Inserto Francia
exec MfSPabm.altaPais 'Francia'
go

--Inserto Alemania
exec MfSPabm.altaPais 'Alemania'
go

--Inserto España
exec MfSPabm.altaPais 'España'
go

--Inserto Inglaterra
exec MfSPabm.altaPais 'Inglaterra'
go

--Inserto Portugal
exec MfSPabm.altaPais 'Portugal'
go

--Inserto Paises Bajos
exec MfSPabm.altaPais 'Paises Bajos'
go

--Inserto Croacia
exec MfSPabm.altaPais 'Croacia'
go

--Inserto Italia
exec MfSPabm.altaPais 'Italia'
go

--Inserto Bélgica
exec MfSPabm.altaPais 'Bélgica'
go

--Inserto Polonia
exec MfSPabm.altaPais 'Polonia'
go

--Inserto Austria
exec MfSPabm.altaPais 'Austria'
go

--Inserto Noruega
exec MfSPabm.altaPais 'Noruega'
go

--Inserto Suiza
exec MfSPabm.altaPais 'Suiza'
go

--Inserto Serbia
exec MfSPabm.altaPais 'Serbia'
go


/*
============================================================
Paises CONCACAF
============================================================
*/

--Inserto México
exec MfSPabm.altaPais 'México'
go

--Inserto USA
exec MfSPabm.altaPais 'USA'
go

--Inserto Canadá
exec MfSPabm.altaPais 'Canadá'
go

--Inserto Costa Rica
exec MfSPabm.altaPais 'Costa Rica'
go

/*
============================================================
Paises CAF
============================================================
*/

--Inserto Marruecos
exec MfSPabm.altaPais 'Marruecos'
go

--Inserto Senegal
exec MfSPabm.altaPais 'Senegal'
go

--Inserto Nigeria
exec MfSPabm.altaPais 'Nigeria'
go

--Inserto Costa de Marfil
exec MfSPabm.altaPais 'Costa de Marfil'
go

--Inserto Egipto
exec MfSPabm.altaPais 'Egipto'
go

/*
============================================================
Paises AFC
============================================================
*/

--Inserto Japon
exec MfSPabm.altaPais 'Japon'
go

--Inserto Corea del Sur
exec MfSPabm.altaPais 'Corea del Sur'
go

/*
============================================================
Paises OFC
============================================================
*/

--Inserto Australia
exec MfSPabm.altaPais 'Australia'
go

--Insertado correctamente
select * from Mundial.Pais
order by id_pais
go



/* ============================================================
   CONFEDERACIONES (las 6 confederaciones continentales de la FIFA)
   Se insertan vía SP para respetar validaciones.
   ============================================================ */

-- CONMEBOL (América del Sur)
EXEC MfSPabm.Confederacion_Alta
    @nombre = N'Confederación Sudamericana de Fútbol',
    @sigla  = 'CONMEBOL'
go

-- UEFA (Europa)
EXEC MfSPabm.Confederacion_Alta
    @nombre = N'Unión de Asociaciones Europeas de Fútbol',
    @sigla  = 'UEFA'
go

-- CONCACAF (Norte, Centroamérica y Caribe)
EXEC MfSPabm.Confederacion_Alta
    @nombre = N'Confederación de Fútbol de Norte, Centroamérica y el Caribe',
    @sigla  = 'CONCACAF'
go

-- CAF (África)
EXEC MfSPabm.Confederacion_Alta
    @nombre = N'Confederación Africana de Fútbol',
    @sigla  = 'CAF'
    go

-- AFC (Asia)
EXEC MfSPabm.Confederacion_Alta
    @nombre = N'Confederación Asiática de Fútbol',
    @sigla  = 'AFC'
    go

-- OFC (Oceanía)
EXEC MfSPabm.Confederacion_Alta
    @nombre = N'Confederación de Fútbol de Oceanía',
    @sigla  = 'OFC'
GO

--Insertado correctamente
select * from Mundial.confederacion
go

/* 
============================================================
      Grupos de 4 equipos, mezclando confederaciones.
============================================================ 
*/

DECLARE @idPais INT;

/* ---------------- GRUPO A ---------------- */
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Argentina';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'A';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Francia';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'A';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'México';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONCACAF', @Grupo = 'A';

DECLARE @idPais INT;
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Japon';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'AFC', @Grupo = 'A';

/* ---------------- GRUPO B ---------------- */

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Brasil';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'B';
go

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'España';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'B';
go

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'USA';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONCACAF', @Grupo = 'B';
go

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Marruecos';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CAF', @Grupo = 'B';
go
/* ---------------- GRUPO C ---------------- */
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Alemania';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'C';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Uruguay';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'C';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Senegal';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CAF', @Grupo = 'C';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Corea del Sur';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'AFC', @Grupo = 'C';

/* ---------------- GRUPO D ---------------- */
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Inglaterra';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'D';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Colombia';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'D';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Nigeria';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CAF', @Grupo = 'D';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Canadá';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONCACAF', @Grupo = 'D';

/* ---------------- GRUPO E ---------------- */
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Portugal';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'E';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Ecuador';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'E';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Egipto';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CAF', @Grupo = 'E';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Costa Rica';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONCACAF', @Grupo = 'E';

/* ---------------- GRUPO F ---------------- */
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Italia';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'F';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Paraguay';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'F';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Costa de Marfil';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CAF', @Grupo = 'F';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Australia';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'OFC', @Grupo = 'F';

/* ---------------- GRUPO G ---------------- */
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Países Bajos';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'G';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Bélgica';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'G';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Croacia';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'G';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Dinamarca';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'G';

/* ---------------- GRUPO H ---------------- */
DECLARE @idPais INT;
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Suiza';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'H';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Serbia';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'H';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Polonia';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'H';

SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Austria';
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'UEFA', @Grupo = 'H';
GO

--Todos los grupos tienen 4 selecciones cada uno
select grupo, count(*) as equipos_en_grupo from Mundial.Seleccion s
group by s.grupo
order by s.grupo
go

select * from Mundial.Seleccion
go

/* 
============================================================
   LISTAS DE CONVOCADOS (una por selección) - versión WHILE
============================================================ 
*/

DECLARE @idSeleccion INT;
DECLARE @minId       INT;
DECLARE @maxId       INT;
DECLARE @grupo       CHAR(1);
DECLARE @pais        VARCHAR(30);

SELECT @minId = MIN(id_seleccion), @maxId = MAX(id_seleccion)
FROM Mundial.Seleccion;

SET @idSeleccion = @minId;

WHILE @idSeleccion <= @maxId
BEGIN
    -- Solo procesamos si la selección existe (puede haber huecos por bajas)
    IF EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @idSeleccion)
    BEGIN
        SELECT @grupo = s.grupo, @pais = p.nombre
        FROM Mundial.Seleccion s
        INNER JOIN Mundial.Pais p ON p.id_pais = s.id_pais
        WHERE s.id_seleccion = @idSeleccion;

        BEGIN TRY
            EXEC MfSPabm.altaListaConvocados @IDSeleccion = @idSeleccion;
        END TRY
        BEGIN CATCH
            PRINT '  (omitida: ya tenía lista o error de validación)';
        END CATCH
    END

    SET @idSeleccion = @idSeleccion + 1;
END
GO

--Cada seleccion tiene su lista
select * from Mundial.ListaConvocados
go


/*
============================================================
Creo los jugadores
============================================================
*/

USE MundialDeFutbol;
GO

/* ============================================================
   JUGADORES (4 por lista de convocados)
   ============================================================ */

-- 1) Armo la tabla de jugadores a insertar
DECLARE @Jugadores TABLE (
    fila            INT IDENTITY(1,1) PRIMARY KEY,
    nombrePais      VARCHAR(30),
    nombre          VARCHAR(50),
    apellido        VARCHAR(50),
    dorsal          INT,
    club            VARCHAR(50)
);

INSERT INTO @Jugadores (nombrePais, nombre, apellido, dorsal, club) VALUES
-- GRUPO A
('Argentina',    'Emiliano',  'Martínez',   23, 'Chelsea'),
('Argentina',    'Lionel',    'Messi',      10, 'Inter Miami'),
('Argentina',    'Julián',    'Álvarez',     9, 'Atlético Madrid'),
('Argentina',    'Enzo',      'Fernández',  24, 'Manchester City'),
('Francia',      'Mike',      'Maignan',    16, 'AC Milan'),
('Francia',      'Kylian',    'Mbappé',     10, 'Real Madrid'),
('Francia',      'Antoine',   'Griezmann',   7, 'Atlético Madrid'),
('Francia',      'Aurélien',  'Tchouaméni',  8, 'Real Madrid'),
('México',       'Guillermo', 'Ochoa',      13, 'América'),
('México',       'Hirving',   'Lozano',     22, 'PSV'),
('México',       'Santiago',  'Giménez',     9, 'Feyenoord'),
('México',       'Edson',     'Álvarez',     4, 'West Ham'),
('Japón',        'Shuichi',   'Gonda',       1, 'Shimizu S-Pulse'),
('Japón',        'Takefusa',  'Kubo',       11, 'Real Sociedad'),
('Japón',        'Kaoru',     'Mitoma',      9, 'Brighton'),
('Japón',        'Wataru',    'Endo',        6, 'Liverpool'),

-- GRUPO B
('Brasil',       'Alisson',   'Becker',      1, 'Liverpool'),
('Brasil',       'Vinícius',  'Júnior',      7, 'Real Madrid'),
('Brasil',       'Rodrygo',   'Goes',       11, 'Real Madrid'),
('Brasil',       'Casemiro',  'Santos',      5, 'Manchester United'),
('España',       'Unai',      'Simón',       1, 'Athletic Bilbao'),
('España',       'Pedri',     'González',    8, 'Barcelona'),
('España',       'Álvaro',    'Morata',      7, 'Atlético Madrid'),
('España',       'Rodri',     'Hernández',  16, 'Manchester City'),
('Estados Unidos','Matt',     'Turner',      1, 'Nottingham Forest'),
('Estados Unidos','Christian','Pulisic',    10, 'AC Milan'),
('Estados Unidos','Weston',   'McKennie',    8, 'Juventus'),
('Estados Unidos','Tyler',    'Adams',       4, 'Bournemouth'),
('Marruecos',    'Yassine',   'Bounou',      1, 'Al-Hilal'),
('Marruecos',    'Hakim',     'Ziyech',     10, 'Galatasaray'),
('Marruecos',    'Achraf',    'Hakimi',      2, 'PSG'),
('Marruecos',    'Sofyan',    'Amrabat',     4, 'Fenerbahçe'),

-- GRUPO C
('Alemania',     'Manuel',    'Neuer',       1, 'Bayern Múnich'),
('Alemania',     'Jamal',     'Musiala',    10, 'Bayern Múnich'),
('Alemania',     'Kai',       'Havertz',     7, 'Arsenal'),
('Alemania',     'Joshua',    'Kimmich',     6, 'Bayern Múnich'),
('Uruguay',      'Sergio',    'Rochet',      1, 'Nacional'),
('Uruguay',      'Federico',  'Valverde',    8, 'Real Madrid'),
('Uruguay',      'Darwin',    'Núñez',       9, 'Liverpool'),
('Uruguay',      'Ronald',    'Araújo',      4, 'Barcelona'),
('Senegal',      'Édouard',   'Mendy',      16, 'Al-Hilal'),
('Senegal',      'Sadio',     'Mané',       10, 'Al-Nassr'),
('Senegal',      'Kalidou',   'Koulibaly',   3, 'Al-Hilal'),
('Senegal',      'Idrissa',   'Gueye',       5, 'Everton'),
('Corea del Sur','Kim',       'Seung-gyu',   1, 'Al-Shabab'),
('Corea del Sur','Son',       'Heung-min',   7, 'Tottenham'),
('Corea del Sur','Lee',       'Kang-in',    18, 'PSG'),
('Corea del Sur','Kim',       'Min-jae',     4, 'Bayern Múnich'),

-- GRUPO D
('Inglaterra',   'Jordan',    'Pickford',    1, 'Everton'),
('Inglaterra',   'Jude',      'Bellingham', 10, 'Real Madrid'),
('Inglaterra',   'Harry',     'Kane',        9, 'Bayern Múnich'),
('Inglaterra',   'Bukayo',    'Saka',        7, 'Arsenal'),
('Colombia',     'David',     'Ospina',      1, 'Atlético Nacional'),
('Colombia',     'James',     'Rodríguez',  10, 'Rayo Vallecano'),
('Colombia',     'Luis',      'Díaz',        7, 'Liverpool'),
('Colombia',     'Jhon',      'Durán',       9, 'Aston Villa'),
('Nigeria',      'Francis',   'Uzoho',      23, 'Omonia'),
('Nigeria',      'Victor',    'Osimhen',     9, 'Napoli'),
('Nigeria',      'Ademola',   'Lookman',    11, 'Atalanta'),
('Nigeria',      'Alex',      'Iwobi',       8, 'Fulham'),
('Canadá',       'Milan',     'Borjan',      1, 'Slovan Bratislava'),
('Canadá',       'Alphonso',  'Davies',     19, 'Bayern Múnich'),
('Canadá',       'Jonathan',  'David',       9, 'Lille'),
('Canadá',       'Cyle',      'Larin',      17, 'Mallorca'),

-- GRUPO E
('Portugal',     'Diogo',     'Costa',       1, 'Porto'),
('Portugal',     'Cristiano', 'Ronaldo',     7, 'Al-Nassr'),
('Portugal',     'Bruno',     'Fernandes',   8, 'Manchester United'),
('Portugal',     'Bernardo',  'Silva',      10, 'Manchester City'),
('Ecuador',      'Hernán',    'Galíndez',    1, 'Liga de Quito'),
('Ecuador',      'Moisés',    'Caicedo',     8, 'Chelsea'),
('Ecuador',      'Enner',     'Valencia',   13, 'Internacional'),
('Ecuador',      'Piero',     'Hincapié',    3, 'Bayer Leverkusen'),
('Egipto',       'Mohamed',   'El-Shenawy',  1, 'Al Ahly'),
('Egipto',       'Mohamed',   'Salah',      10, 'Liverpool'),
('Egipto',       'Omar',      'Marmoush',    9, 'Manchester City'),
('Egipto',       'Mostafa',   'Mohamed',     5, 'Al Ahly'),
('Costa Rica',   'Keylor',    'Navas',       1, 'Newell''s Old Boys'),
('Costa Rica',   'Joel',      'Campbell',   12, 'Alajuelense'),
('Costa Rica',   'Manfred',   'Ugalde',      9, 'Spartak Moscú'),
('Costa Rica',   'Francisco', 'Calvo',       3, 'Konyaspor'),

-- GRUPO F
('Italia',       'Gianluigi', 'Donnarumma',  1, 'PSG'),
('Italia',       'Nicolò',    'Barella',     8, 'Inter'),
('Italia',       'Federico',  'Chiesa',     14, 'Liverpool'),
('Italia',       'Alessandro','Bastoni',     5, 'Inter'),
('Paraguay',     'Antonio',   'Sanabria',    1, 'Cerro Porteño'),
('Paraguay',     'Miguel',    'Almirón',    10, 'Atlanta United'),
('Paraguay',     'Ramón',     'Sosa',        8, 'Nottingham Forest'),
('Paraguay',     'Gustavo',   'Gómez',       3, 'Palmeiras'),
('Camerún',      'André',     'Onana',       1, 'Manchester United'),
('Camerún',      'Vincent',   'Aboubakar',   9, 'Beşiktaş'),
('Camerún',      'Karl',      'Toko Ekambi', 7, 'Abha'),
('Camerún',      'Frank',     'Zambo Anguissa', 8, 'Napoli'),
('Australia',    'Mathew',    'Ryan',        1, 'AZ Alkmaar'),
('Australia',    'Jackson',   'Irvine',      6, 'St. Pauli'),
('Australia',    'Mitchell',  'Duke',        9, 'Machida Zelvia'),
('Australia',    'Harry',     'Souttar',     5, 'Sheffield United'),

-- GRUPO G
('Países Bajos', 'Bart',      'Verbruggen',  1, 'Brighton'),
('Países Bajos', 'Virgil',    'van Dijk',    4, 'Liverpool'),
('Países Bajos', 'Frenkie',   'de Jong',     8, 'Barcelona'),
('Países Bajos', 'Cody',      'Gakpo',      11, 'Liverpool'),
('Bélgica',      'Koen',      'Casteels',    1, 'Al-Qadsiah'),
('Bélgica',      'Kevin',     'De Bruyne',   7, 'Napoli'),
('Bélgica',      'Romelu',    'Lukaku',      9, 'Napoli'),
('Bélgica',      'Jérémy',    'Doku',       11, 'Manchester City'),
('Croacia',      'Dominik',   'Livaković',   1, 'Fenerbahçe'),
('Croacia',      'Luka',      'Modrić',     10, 'AC Milan'),
('Croacia',      'Mateo',     'Kovačić',     8, 'Manchester City'),
('Croacia',      'Joško',     'Gvardiol',    4, 'Manchester City'),
('Dinamarca',    'Kasper',    'Schmeichel',  1, 'Anderlecht'),
('Dinamarca',    'Christian', 'Eriksen',    10, 'Wolfsburg'),
('Dinamarca',    'Rasmus',    'Højlund',     9, 'Napoli'),
('Dinamarca',    'Pierre-Emile','Højbjerg',  2, 'Marsella'),

-- GRUPO H
('Suiza',        'Yann',      'Sommer',      1, 'Inter'),
('Suiza',        'Granit',    'Xhaka',       8, 'Bayer Leverkusen'),
('Suiza',        'Manuel',    'Akanji',      5, 'Inter'),
('Suiza',        'Breel',     'Embolo',      9, 'Mónaco'),
('Serbia',       'Predrag',   'Rajković',    1, 'Mallorca'),
('Serbia',       'Dušan',     'Vlahović',    9, 'Juventus'),
('Serbia',       'Sergej',    'Milinković-Savić', 20, 'Al-Hilal'),
('Serbia',       'Aleksandar','Mitrović',   10, 'Al-Hilal'),
('Polonia',      'Wojciech',  'Szczęsny',    1, 'Barcelona'),
('Polonia',      'Robert',    'Lewandowski', 9, 'Barcelona'),
('Polonia',      'Piotr',     'Zieliński',  10, 'Inter'),
('Polonia',      'Nicola',    'Zalewski',    5, 'Atalanta'),
('Austria',      'Patrick',   'Pentz',       1, 'Brøndby'),
('Austria',      'Marcel',    'Sabitzer',   10, 'Borussia Dortmund'),
('Austria',      'Konrad',    'Laimer',      8, 'Bayern Múnich'),
('Austria',      'Marko',     'Arnautović',  7, 'Estrella Roja');

-- 2) Recorro la tabla con WHILE (usando TOP 1 + id > @ultimo)
DECLARE @fila            INT = 0;
DECLARE @totalFilas      INT;
DECLARE @idLista         INT;
DECLARE @nombrePais      VARCHAR(30);
DECLARE @nombre          VARCHAR(50);
DECLARE @apellido        VARCHAR(50);
DECLARE @dorsal          INT;
DECLARE @club            VARCHAR(50);

SELECT @totalFilas = MAX(fila) FROM @Jugadores;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @nombrePais = j.nombrePais,
        @nombre     = j.nombre,
        @apellido   = j.apellido,
        @dorsal     = j.dorsal,
        @club       = j.club
    FROM @Jugadores j
    WHERE j.fila = @fila;

    -- Resuelvo la lista de convocados del país
    SELECT @idLista = lc.id_lista
    FROM Mundial.ListaConvocados lc
    JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
    JOIN Mundial.Pais p      ON p.id_pais       = s.id_pais
    WHERE p.nombre = @nombrePais;

    BEGIN TRY
        EXEC MfSPabm.altaJugador
             @IDListaConvocados = @idLista,
             @Nombre            = @nombre,
             @Apellido          = @apellido,
             @Dorsal            = @dorsal,
             @Club              = @club;
    END TRY
    BEGIN CATCH
        PRINT '  (omitido: error de validación)';
    END CATCH
END
GO

--Jugadores insertados
select * from Mundial.Jugador
go

/*
============================================================
IDIOMAS 
============================================================ 
*/

DECLARE @Idiomas TABLE (
    fila   INT IDENTITY(1,1) PRIMARY KEY,
    idioma NVARCHAR(200)
);

INSERT INTO @Idiomas (idioma) VALUES
(N'Español'),
(N'Portugués'),
(N'Inglés'),
(N'Francés'),
(N'Alemán'),
(N'Italiano'),
(N'Polaco'),
(N'Árabe'),
(N'Persa'),
(N'Neerlandés');

DECLARE @fila       INT = 0;
DECLARE @totalFilas INT;
DECLARE @idioma     NVARCHAR(200);

SELECT @totalFilas = MAX(fila) FROM @Idiomas;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT @idioma = idioma FROM @Idiomas WHERE fila = @fila;
    BEGIN TRY
        EXEC Mundial.Idioma_Alta @idioma = @idioma;
        PRINT '  Insertado.';
    END TRY
    BEGIN CATCH
        PRINT '  (omitido: ' + ERROR_MESSAGE() + ')';
    END CATCH
END
GO

--Insertados correctamente
select * from Mundial.Idioma
go

/* 
============================================================
2) ÁRBITROS 
============================================================ 
*/

DECLARE @Arbitros TABLE (
    fila          INT IDENTITY(1,1) PRIMARY KEY,
    nombre        NVARCHAR(200),
    apellido      NVARCHAR(200),
    fecha_nac     DATE,
    nombrePais    VARCHAR(30),
    siglaConf     VARCHAR(50),
    categoria     NVARCHAR(50),
    habilitado    BIT,
    idioma        NVARCHAR(200)
);

INSERT INTO @Arbitros (nombre, apellido, fecha_nac, nombrePais, siglaConf, categoria, habilitado, idioma) VALUES
-- CONMEBOL
(N'Facundo',    N'Tello',     '1982-06-05', 'Argentina',    'CONMEBOL', N'FIFA', 1, N'Español'),
(N'Raphael',    N'Claus',     '1977-09-06', 'Brasil',       'CONMEBOL', N'FIFA', 1, N'Portugués'),
(N'Wilton',     N'Sampaio',   '1981-12-28', 'Brasil',       'CONMEBOL', N'FIFA', 1, N'Portugués'),

-- UEFA
(N'Clément',    N'Turpin',    '1982-05-16', 'Francia',      'UEFA',     N'FIFA', 1, N'Francés'),
(N'Anthony',    N'Taylor',    '1978-10-20', 'Inglaterra',   'UEFA',     N'FIFA', 1, N'Inglés'),
(N'Daniele',    N'Orsato',    '1975-11-23', 'Italia',       'UEFA',     N'FIFA', 1, N'Italiano'),
(N'Felix',      N'Brych',     '1975-08-03', 'Alemania',     'UEFA',     N'FIFA', 1, N'Alemán'),
(N'Michael',    N'Oliver',    '1985-02-20', 'Inglaterra',   'UEFA',     N'FIFA', 1, N'Inglés'),
(N'Szymon',     N'Marciniak', '1981-01-07', 'Polonia',      'UEFA',     N'FIFA', 1, N'Polaco'),

-- CONCACAF
(N'César',      N'Ramos',     '1983-12-05', 'México',       'CONCACAF', N'FIFA', 1, N'Español'),
(N'Ismail',     N'Elfath',    '1982-03-03', 'Estados Unidos','CONCACAF', N'FIFA', 1, N'Inglés'),

-- CAF
(N'Victor',     N'Gomes',     '1976-12-30', 'Nigeria',      'CAF',      N'FIFA', 1, N'Inglés'),
(N'Mustapha',   N'Ghorbal',   '1985-09-19', 'Marruecos',    'CAF',      N'FIFA', 1, N'Árabe'),

-- AFC
(N'Alireza',    N'Faghani',   '1978-03-21', 'Australia',    'AFC',      N'FIFA', 1, N'Persa'),
(N'Abdulrahman',N'Al-Jassim', '1987-10-14', 'Australia',    'AFC',      N'FIFA', 1, N'Árabe'),

-- OFC
(N'Matthew',    N'Conger',    '1986-06-11', 'Nueva Zelanda','OFC',      N'FIFA', 1, N'Inglés');

DECLARE @fila         INT = 0;
DECLARE @totalFilas   INT;
DECLARE @nombre       NVARCHAR(200);
DECLARE @apellido     NVARCHAR(200);
DECLARE @fechaNac     DATE;
DECLARE @nombrePais   VARCHAR(30);
DECLARE @siglaConf    VARCHAR(50);
DECLARE @categoria    NVARCHAR(50);
DECLARE @habilitado   BIT;
DECLARE @idioma       NVARCHAR(200);
DECLARE @idPais       INT;
DECLARE @idConf       INT;
DECLARE @idIdioma     INT;

SELECT @totalFilas = MAX(fila) FROM @Arbitros;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @nombre     = nombre,
        @apellido   = apellido,
        @fechaNac   = fecha_nac,
        @nombrePais = nombrePais,
        @siglaConf  = siglaConf,
        @categoria  = categoria,
        @habilitado = habilitado,
        @idioma     = idioma
    FROM @Arbitros
    WHERE fila = @fila;

    -- Resuelvo FKs
    SELECT @idPais   = id_pais          FROM Mundial.Pais         WHERE nombre = @nombrePais;
    SELECT @idConf   = id_confederacion FROM Mundial.Confederacion WHERE sigla  = @siglaConf;
    SELECT @idIdioma = id_idioma        FROM Mundial.Idioma        WHERE idioma = @idioma;

    BEGIN TRY
        EXEC MfSPabm.Arbitro_Alta
             @nombre           = @nombre,
             @apellido         = @apellido,
             @fecha_nacimiento = @fechaNac,
             @id_pais          = @idPais,
             @id_confederacion = @idConf,
             @categoria        = @categoria,
             @habilitado       = @habilitado,
             @id_idioma        = @idIdioma;
        PRINT '  Árbitro insertado.';
    END TRY
    BEGIN CATCH
        PRINT '  (omitido: ' + ERROR_MESSAGE() + ')';
    END CATCH
END
GO

--insertados correctamente
select * from Mundial.Arbitro
go

USE MundialDeFutbol;
GO

/* 
============================================================
   SEDES DEL MUNDIAL EN ARGENTINA 
============================================================
*/

-- 1) Resuelvo id_pais de Argentina
DECLARE @idPais INT;
SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = 'Argentina';

IF @idPais IS NULL
BEGIN
    PRINT 'ERROR: no existe el país Argentina. Cargalo antes.';
    RETURN;
END

-- 2) Tabla variable con las sedes
DECLARE @Sedes TABLE (
    fila           INT IDENTITY(1,1) PRIMARY KEY,
    nombre_estadio NVARCHAR(400),
    ciudad         NVARCHAR(400),
    capacidad      INT,
    huso_horario   VARCHAR(20),
    latitud        DECIMAL(9,6),
    longitud       DECIMAL(9,6)
);

INSERT INTO @Sedes (nombre_estadio, ciudad, capacidad, huso_horario, latitud, longitud) VALUES
(N'Estadio Monumental Antonio V. Liberti', N'Buenos Aires',    84000, 'UTC-03:00', -34.545278, -58.449722),
(N'Estadio Alberto J. Armando (La Bombonera)', N'Buenos Aires', 54000, 'UTC-03:00', -34.635556, -58.364722),
(N'Estadio Ciudad de La Plata',            N'La Plata',         53000, 'UTC-03:00', -34.913611, -57.989167),
(N'Estadio Mario Alberto Kempes',          N'Córdoba',          57000, 'UTC-03:00', -31.368611, -64.246667),
(N'Estadio Malvinas Argentinas',           N'Mendoza',          40268, 'UTC-03:00', -32.889444, -68.879722),
(N'Estadio Gigante de Arroyito',           N'Rosario',          41954, 'UTC-03:00', -32.938333, -60.626667),
(N'Estadio Padre Ernesto Martearena',      N'Salta',            20408, 'UTC-03:00', -24.816389, -65.418333),
(N'Estadio Bicentenario de San Juan',      N'San Juan',         25000, 'UTC-03:00', -31.537500, -68.550000),
(N'Estadio Único de La Plata',             N'La Plata',         20000, 'UTC-03:00', -34.916667, -57.983333),
(N'Estadio José Amalfitani',               N'Buenos Aires',     49540, 'UTC-03:00', -34.636389, -58.526111),
(N'Estadio Tomás Adolfo Ducó',             N'Buenos Aires',     48000, 'UTC-03:00', -34.644167, -58.395556),
(N'Estadio Libertadores de América',       N'Avellaneda',       49000, 'UTC-03:00', -34.668611, -58.368611);

-- 3) Recorro con WHILE (sin cursor)
DECLARE @fila           INT = 0;
DECLARE @totalFilas     INT;
DECLARE @nombreEstadio  NVARCHAR(400);
DECLARE @ciudad         NVARCHAR(400);
DECLARE @capacidad      INT;
DECLARE @huso           VARCHAR(20);
DECLARE @lat            DECIMAL(9,6);
DECLARE @lon            DECIMAL(9,6);
DECLARE @idSedeOut      INT;

SELECT @totalFilas = MAX(fila) FROM @Sedes;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @nombreEstadio = nombre_estadio,
        @ciudad        = ciudad,
        @capacidad     = capacidad,
        @huso          = huso_horario,
        @lat           = latitud,
        @lon           = longitud
    FROM @Sedes
    WHERE fila = @fila;

    BEGIN TRY
        EXEC Mundial.Sede_Alta
             @nombre_estadio = @nombreEstadio,
             @ciudad         = @ciudad,
             @id_pais        = @idPais,
             @capacidad      = @capacidad,
             @huso_horario   = @huso,
             @latitud        = @lat,
             @longitud       = @lon,
             @id_sede        = @idSedeOut OUTPUT;
    END TRY
    BEGIN CATCH
        PRINT '  (omitida: ' + ERROR_MESSAGE() + ')';
    END CATCH
END
GO

select * from Mundial.Sede
go


/* 
============================================================
   PARTIDOS FASE DE GRUPOS (48) 
============================================================ 
*/

-- 1) Tabla variable con los cruces (por nombre de país y estadio)
DECLARE @Partidos TABLE (
    fila            INT IDENTITY(1,1) PRIMARY KEY,
    grupo           CHAR(1),
    fecha_num       INT,            -- 1, 2 o 3
    local           NVARCHAR(100),
    visitante       NVARCHAR(100),
    nombre_estadio  NVARCHAR(200),
    hora_local      TIME
);

-- Fecha 1: 11/06/2026
INSERT INTO @Partidos (grupo, fecha_num, local, visitante, nombre_estadio, hora_local) VALUES
('A', 1, N'Argentina',      N'Francia',         N'Estadio Monumental Antonio V. Liberti', '13:00'),
('A', 1, N'México',         N'Japón',           N'Estadio Monumental Antonio V. Liberti', '16:00'),
('B', 1, N'Brasil',         N'España',          N'Estadio Mario Alberto Kempes',          '13:00'),
('B', 1, N'Estados Unidos', N'Marruecos',       N'Estadio Mario Alberto Kempes',          '16:00'),
('C', 1, N'Alemania',       N'Uruguay',         N'Estadio Ciudad de La Plata',            '13:00'),
('C', 1, N'Senegal',        N'Corea del Sur',   N'Estadio Ciudad de La Plata',            '16:00'),
('D', 1, N'Inglaterra',     N'Colombia',        N'Estadio Malvinas Argentinas',           '13:00'),
('D', 1, N'Nigeria',        N'Canadá',          N'Estadio Malvinas Argentinas',           '16:00'),
('E', 1, N'Portugal',       N'Ecuador',         N'Estadio Gigante de Arroyito',           '13:00'),
('E', 1, N'Egipto',         N'Costa Rica',      N'Estadio Gigante de Arroyito',           '16:00'),
('F', 1, N'Italia',         N'Paraguay',        N'Estadio Padre Ernesto Martearena',      '13:00'),
('F', 1, N'Camerún',        N'Australia',       N'Estadio Padre Ernesto Martearena',      '16:00'),
('G', 1, N'Países Bajos',   N'Bélgica',         N'Estadio Bicentenario de San Juan',      '13:00'),
('G', 1, N'Croacia',        N'Dinamarca',       N'Estadio Bicentenario de San Juan',      '16:00'),
('H', 1, N'Suiza',          N'Serbia',          N'Estadio Único de La Plata',             '13:00'),
('H', 1, N'Polonia',        N'Austria',         N'Estadio Único de La Plata',             '16:00'),

-- Fecha 2: 15/06/2026
('A', 2, N'Argentina',      N'México',          N'Estadio Monumental Antonio V. Liberti', '13:00'),
('A', 2, N'Francia',        N'Japón',           N'Estadio Monumental Antonio V. Liberti', '16:00'),
('B', 2, N'Brasil',         N'Estados Unidos',  N'Estadio Mario Alberto Kempes',          '13:00'),
('B', 2, N'España',         N'Marruecos',       N'Estadio Mario Alberto Kempes',          '16:00'),
('C', 2, N'Alemania',       N'Senegal',         N'Estadio Ciudad de La Plata',            '13:00'),
('C', 2, N'Uruguay',        N'Corea del Sur',   N'Estadio Ciudad de La Plata',            '16:00'),
('D', 2, N'Inglaterra',     N'Nigeria',         N'Estadio Malvinas Argentinas',           '13:00'),
('D', 2, N'Colombia',       N'Canadá',          N'Estadio Malvinas Argentinas',           '16:00'),
('E', 2, N'Portugal',       N'Egipto',          N'Estadio Gigante de Arroyito',           '13:00'),
('E', 2, N'Ecuador',        N'Costa Rica',      N'Estadio Gigante de Arroyito',           '16:00'),
('F', 2, N'Italia',         N'Camerún',         N'Estadio Padre Ernesto Martearena',      '13:00'),
('F', 2, N'Paraguay',       N'Australia',       N'Estadio Padre Ernesto Martearena',      '16:00'),
('G', 2, N'Países Bajos',   N'Croacia',         N'Estadio Bicentenario de San Juan',      '13:00'),
('G', 2, N'Bélgica',        N'Dinamarca',       N'Estadio Bicentenario de San Juan',      '16:00'),
('H', 2, N'Suiza',          N'Polonia',         N'Estadio Único de La Plata',             '13:00'),
('H', 2, N'Serbia',         N'Austria',         N'Estadio Único de La Plata',             '16:00'),

-- Fecha 3: 19/06/2026 (simultáneos por grupo)
('A', 3, N'Argentina',      N'Japón',           N'Estadio Monumental Antonio V. Liberti', '16:00'),
('A', 3, N'Francia',        N'México',          N'Estadio José Amalfitani',               '16:00'),
('B', 3, N'Brasil',         N'Marruecos',       N'Estadio Mario Alberto Kempes',          '16:00'),
('B', 3, N'España',         N'Estados Unidos',  N'Estadio Tomás Adolfo Ducó',             '16:00'),
('C', 3, N'Alemania',       N'Corea del Sur',   N'Estadio Ciudad de La Plata',            '16:00'),
('C', 3, N'Uruguay',        N'Senegal',         N'Estadio Libertadores de América',       '16:00'),
('D', 3, N'Inglaterra',     N'Canadá',          N'Estadio Malvinas Argentinas',           '16:00'),
('D', 3, N'Colombia',       N'Nigeria',         N'Estadio Único de La Plata',             '16:00'),
('E', 3, N'Portugal',       N'Costa Rica',      N'Estadio Gigante de Arroyito',           '16:00'),
('E', 3, N'Ecuador',        N'Egipto',          N'Estadio Padre Ernesto Martearena',      '16:00'),
('F', 3, N'Italia',         N'Australia',       N'Estadio Bicentenario de San Juan',      '16:00'),
('F', 3, N'Paraguay',       N'Camerún',         N'Estadio Monumental Antonio V. Liberti', '16:00'),
('G', 3, N'Países Bajos',   N'Dinamarca',       N'Estadio Ciudad de La Plata',            '16:00'),
('G', 3, N'Bélgica',        N'Croacia',         N'Estadio Libertadores de América',       '16:00'),
('H', 3, N'Suiza',          N'Austria',         N'Estadio Malvinas Argentinas',           '16:00'),
('H', 3, N'Serbia',         N'Polonia',         N'Estadio Único de La Plata',             '16:00');

-- 2) Recorro con WHILE (sin cursor)
DECLARE @fila             INT = 0;
DECLARE @totalFilas       INT;
DECLARE @grupo            CHAR(1);
DECLARE @fechaNum         INT;
DECLARE @local            NVARCHAR(100);
DECLARE @visitante        NVARCHAR(100);
DECLARE @nombreEstadio    NVARCHAR(200);
DECLARE @horaLocal        TIME;

DECLARE @idSede           INT;
DECLARE @idLocal          INT;
DECLARE @idVisitante      INT;
DECLARE @fechaLocal       DATETIME;
DECLARE @fechaUtc         DATETIME;
DECLARE @fase             VARCHAR(MAX) = 'fasedegrupos';
DECLARE @idPartidoOut     INT;

SELECT @totalFilas = MAX(fila) FROM @Partidos;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @grupo         = grupo,
        @fechaNum      = fecha_num,
        @local         = local,
        @visitante     = visitante,
        @nombreEstadio = nombre_estadio,
        @horaLocal     = hora_local
    FROM @Partidos
    WHERE fila = @fila;

    -- Resuelvo FKs por nombre
    SELECT @idSede      = id_sede      FROM Mundial.Sede     WHERE nombre_estadio = @nombreEstadio;
    SELECT @idLocal     = s.id_seleccion
        FROM Mundial.Seleccion s
        INNER JOIN Mundial.Pais p ON p.id_pais = s.id_pais
        WHERE p.nombre = @local;
    SELECT @idVisitante = s.id_seleccion
        FROM Mundial.Seleccion s
        INNER JOIN Mundial.Pais p ON p.id_pais = s.id_pais
        WHERE p.nombre = @visitante;

    -- Armo fecha_hora_local según fecha_num (11, 15, 19 de junio 2026)
    DECLARE @dia INT = CASE @fechaNum
                          WHEN 1 THEN 11
                          WHEN 2 THEN 15
                          WHEN 3 THEN 19
                       END;
    SET @fechaLocal = DATETIMEFROMPARTS(2026, 6, @dia,
                                        DATEPART(HOUR,   @horaLocal),
                                        DATEPART(MINUTE, @horaLocal),
                                        0, 0);
    SET @fechaUtc = DATEADD(HOUR, 3, @fechaLocal);  -- Argentina es UTC-03:00

    BEGIN TRY
        EXEC Mundial.Partido_Alta
             @id_sede                = @idSede,
             @id_seleccion_local     = @idLocal,
             @id_seleccion_visitante = @idVisitante,
             @fecha_hora_local       = @fechaLocal,
             @fecha_hora_utc         = @fechaUtc,
             @fase                   = @fase,
             @id_partido             = @idPartidoOut OUTPUT;
    END TRY
    BEGIN CATCH
        PRINT '  (omitido: ' + ERROR_MESSAGE() + ')';
    END CATCH
END
GO

--Insercion exitosa
select * from Mundial.Partido
go

USE MundialDeFutbol;
GO

/* 
============================================================
   ALTA de Cuerpo_tecnico para todas las selecciones
============================================================ 
*/

DECLARE @idSeleccion INT = 0;
DECLARE @mensaje     VARCHAR(500);
DECLARE @rc          INT;

WHILE 1 = 1
BEGIN
    -- Próxima selección mayor al último id procesado
    SELECT TOP 1 @idSeleccion = s.id_seleccion
    FROM Mundial.Seleccion s
    WHERE s.id_seleccion > @idSeleccion
    ORDER BY s.id_seleccion;

    IF @@ROWCOUNT = 0
        BREAK;

    PRINT '--- Seleccion id=' + CONVERT(VARCHAR(10), @idSeleccion) + ' ---';

    BEGIN TRY
        SET @mensaje = NULL;
        EXEC @rc = Mundial.usp_Cuerpo_tecnico_Alta
             @id_seleccion = @idSeleccion,
             @mensaje      = @mensaje OUTPUT;

        IF @rc = 0
            PRINT '  OK: ' + ISNULL(@mensaje, 'Cuerpo tecnico creado.');
        ELSE
            PRINT '  OMITIDO: ' + ISNULL(@mensaje, '(sin mensaje)');
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO


select * from Mundial.Cuerpo_tecnico
go

USE MundialDeFutbol;
GO

/* 
============================================================
   TÉCNICOS (3 por cuerpo técnico) 
   Total: 32 cuerpos × 3 = 96 técnicos
============================================================ 
*/

-- 1) Tabla variable con los técnicos a insertar
DECLARE @Tecnicos TABLE (
    fila         INT IDENTITY(1,1) PRIMARY KEY,
    nombrePais   NVARCHAR(100),
    nombre       VARCHAR(50),
    apellido     VARCHAR(50),
    rol          VARCHAR(25)
);

INSERT INTO @Tecnicos (nombrePais, nombre, apellido, rol) VALUES
-- GRUPO A
('Argentina',     'Lionel',      'Scaloni',      'DT'),
('Argentina',     'Pablo',       'Aimar',        'AYUDANTE'),
('Argentina',     'Luis',        'Martín',       'PREPARADOR_FISICO'),
('Francia',       'Didier',      'Deschamps',    'DT'),
('Francia',       'Guy',         'Stéphan',      'AYUDANTE'),
('Francia',       'Cyril',       'Moine',        'PREPARADOR_FISICO'),
('México',        'Javier',      'Aguirre',      'DT'),
('México',        'Rafael',      'Márquez',      'AYUDANTE'),
('México',        'Carlos',      'Pecanha',      'PREPARADOR_FISICO'),
('Japón',         'Hajime',      'Moriyasu',     'DT'),
('Japón',         'Ryoichi',     'Maeda',        'AYUDANTE'),
('Japón',         'Yasuhiro',    'Yoshida',      'PREPARADOR_FISICO'),

-- GRUPO B
('Brasil',        'Dorival',     'Júnior',       'DT'),
('Brasil',        'Lucas',       'Silvestre',    'AYUDANTE'),
('Brasil',        'Ricardo',     'Rosa',         'PREPARADOR_FISICO'),
('España',        'Luis',        'de la Fuente', 'DT'),
('España',        'Pablo',       'Amestoy',      'AYUDANTE'),
('España',        'Carlos',      'Cruz',         'PREPARADOR_FISICO'),
('Estados Unidos','Mauricio',    'Pochettino',   'DT'),
('Estados Unidos','Jesús',       'Pérez',        'AYUDANTE'),
('Estados Unidos','Antonio',     'Pintus',       'PREPARADOR_FISICO'),
('Marruecos',     'Walid',       'Regragui',     'DT'),
('Marruecos',     'Rachid',      'Benmahmoud',   'AYUDANTE'),
('Marruecos',     'Hassan',      'El Amrani',    'PREPARADOR_FISICO'),

-- GRUPO C
('Alemania',      'Julian',      'Nagelsmann',   'DT'),
('Alemania',      'Sandro',      'Wagner',       'AYUDANTE'),
('Alemania',      'Nicklas',     'Dietrich',     'PREPARADOR_FISICO'),
('Uruguay',       'Marcelo',     'Bielsa',       'DT'),
('Uruguay',       'Pablo',       'Quiroga',      'AYUDANTE'),
('Uruguay',       'Diego',       'Rodríguez',    'PREPARADOR_FISICO'),
('Senegal',       'Aliou',       'Cissé',        'DT'),
('Senegal',       'Pape',        'Thiaw',        'AYUDANTE'),
('Senegal',       'Mamadou',     'Diop',         'PREPARADOR_FISICO'),
('Corea del Sur', 'Hong',        'Myung-bo',     'DT'),
('Corea del Sur', 'Kim',         'Dong-jin',     'AYUDANTE'),
('Corea del Sur', 'Lee',         'Jae-hong',     'PREPARADOR_FISICO'),

-- GRUPO D
('Inglaterra',    'Thomas',      'Tuchel',       'DT'),
('Inglaterra',    'Anthony',     'Barry',        'AYUDANTE'),
('Inglaterra',    'James',       'Melbourne',    'PREPARADOR_FISICO'),
('Colombia',      'Néstor',      'Lorenzo',      'DT'),
('Colombia',      'Gabriel',     'Cedeño',       'AYUDANTE'),
('Colombia',      'José',        'Rentería',     'PREPARADOR_FISICO'),
('Nigeria',       'Eric',        'Chelle',       'DT'),
('Nigeria',       'Daniel',      'Amokachi',     'AYUDANTE'),
('Nigeria',       'Femi',        'Oladapo',      'PREPARADOR_FISICO'),
('Canadá',        'Jesse',       'Marsch',       'DT'),
('Canadá',        'Mauro',       'Biello',       'AYUDANTE'),
('Canadá',        'Frank',       'Ciampa',       'PREPARADOR_FISICO'),

-- GRUPO E
('Portugal',      'Roberto',     'Martínez',     'DT'),
('Portugal',      'Anthony',     'Barry',        'AYUDANTE'),
('Portugal',      'Richard',     'Evans',        'PREPARADOR_FISICO'),
('Ecuador',       'Sebastián',   'Beccacece',    'DT'),
('Ecuador',       'Nicolás',     'Diez',         'AYUDANTE'),
('Ecuador',       'Luis',        'Martín',       'PREPARADOR_FISICO'),
('Egipto',        'Hossam',      'Hassan',       'DT'),
('Egipto',        'Mohamed',     'Shawky',       'AYUDANTE'),
('Egipto',        'Tarek',       'Mostafa',      'PREPARADOR_FISICO'),
('Costa Rica',    'Claudio',     'Vivas',        'DT'),
('Costa Rica',    'Paulo',       'Wanchope',     'AYUDANTE'),
('Costa Rica',    'Erick',       'Sánchez',      'PREPARADOR_FISICO'),

-- GRUPO F
('Italia',        'Luciano',     'Spalletti',    'DT'),
('Italia',        'Marco',       'Domenichini',  'AYUDANTE'),
('Italia',        'Francesco',   'Cacciapuoti',  'PREPARADOR_FISICO'),
('Paraguay',      'Gustavo',     'Alfaro',       'DT'),
('Paraguay',      'Carlos',      'González',     'AYUDANTE'),
('Paraguay',      'Osvaldo',     'Ferraro',      'PREPARADOR_FISICO'),
('Camerún',       'Marc',        'Brys',         'DT'),
('Camerún',       'Eric',        'Batang',       'AYUDANTE'),
('Camerún',       'Serge',       'Mvondo',       'PREPARADOR_FISICO'),
('Australia',     'Tony',        'Popovic',      'DT'),
('Australia',     'Hayden',      'Foxe',         'AYUDANTE'),
('Australia',     'Andrew',      'Clark',        'PREPARADOR_FISICO'),

-- GRUPO G
('Países Bajos',  'Ronald',      'Koeman',       'DT'),
('Países Bajos',  'Erwin',       'Koeman',       'AYUDANTE'),
('Países Bajos',  'René',        'Wormhoudt',    'PREPARADOR_FISICO'),
('Bélgica',       'Rudi',        'Garcia',       'DT'),
('Bélgica',       'Frédéric',    'Goncalves',    'AYUDANTE'),
('Bélgica',       'Bram',        'Geirnaert',    'PREPARADOR_FISICO'),
('Croacia',       'Zlatko',      'Dalić',        'DT'),
('Croacia',       'Ivica',       'Olić',         'AYUDANTE'),
('Croacia',       'Luka',        'Milanović',    'PREPARADOR_FISICO'),
('Dinamarca',     'Brian',       'Riemer',       'DT'),
('Dinamarca',     'Morten',      'Wieghorst',    'AYUDANTE'),
('Dinamarca',     'Christian',   'Clausen',      'PREPARADOR_FISICO'),

-- GRUPO H
('Suiza',         'Murat',       'Yakin',        'DT'),
('Suiza',         'Giorgio',     'Contini',      'AYUDANTE'),
('Suiza',         'Oliver',      'Rüegg',        'PREPARADOR_FISICO'),
('Serbia',        'Dragan',      'Stojković',    'DT'),
('Serbia',        'Žarko',       'Đurišić',      'AYUDANTE'),
('Serbia',        'Marko',       'Stojanović',   'PREPARADOR_FISICO'),
('Polonia',       'Michał',      'Probierz',     'DT'),
('Polonia',       'Sebastian',   'Mila',         'AYUDANTE'),
('Polonia',       'Remigiusz',   'Rzepka',       'PREPARADOR_FISICO'),
('Austria',       'Ralf',        'Rangnick',     'DT'),
('Austria',       'Lars',        'Kornetka',     'AYUDANTE'),
('Austria',       'Martin',      'Hiden',        'PREPARADOR_FISICO');

-- 2) Recorro con WHILE (sin cursor)
DECLARE @fila            INT = 0;
DECLARE @totalFilas      INT;
DECLARE @nombrePais      NVARCHAR(100);
DECLARE @nombre          VARCHAR(50);
DECLARE @apellido        VARCHAR(50);
DECLARE @rol             VARCHAR(25);
DECLARE @idCuerpoTecnico INT;
DECLARE @mensaje         VARCHAR(500);
DECLARE @rc              INT;

SELECT @totalFilas = MAX(fila) FROM @Tecnicos;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @nombrePais = nombrePais,
        @nombre     = nombre,
        @apellido   = apellido,
        @rol        = rol
    FROM @Tecnicos
    WHERE fila = @fila;

    -- Resuelvo id_cuerpo_tecnico a partir del país
    SELECT @idCuerpoTecnico = ct.id_cuerpo_tecnico
    FROM Mundial.Cuerpo_tecnico ct
    INNER JOIN Mundial.Seleccion s ON s.id_seleccion = ct.id_seleccion
    INNER JOIN Mundial.Pais p      ON p.id_pais       = s.id_pais
    WHERE p.nombre = @nombrePais;


    BEGIN TRY
        SET @mensaje = NULL;
        EXEC @rc = Mundial.usp_Tecnico_Alta
             @id_cuerpo_tecnico = @idCuerpoTecnico,
             @nombre            = @nombre,
             @apellido          = @apellido,
             @rol               = @rol,
             @mensaje           = @mensaje OUTPUT;

        IF @rc = 0
            PRINT '  OK: ' + ISNULL(@mensaje, 'Tecnico creado.');
        ELSE
            PRINT '  OMITIDO: ' + ISNULL(@mensaje, '(sin mensaje)');
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO

select * from Mundial.Tecnico
go

/* 
============================================================
   TERNAS ARBITRALES (8 activas + 2 descartadas)
============================================================ 
*/
DECLARE @Arbitros TABLE (
    rn          INT IDENTITY(1,1) PRIMARY KEY,
    id_arbitro  INT,
    apellido    VARCHAR(50),
    id_pais     INT
);

INSERT INTO @Arbitros (id_arbitro, apellido, id_pais)
SELECT id_arbitro, apellido, id_pais
FROM Mundial.Arbitro WHERE habilitado = 1
ORDER BY id_arbitro;

DECLARE @totalArbitros INT;
SELECT @totalArbitros = COUNT(*) FROM @Arbitros;

IF @totalArbitros < 5
BEGIN
    PRINT 'ERROR: se necesitan al menos 5 árbitros habilitados.';
    RETURN;
END

DECLARE @idPartido       INT = 0;
DECLARE @idLocal         INT;
DECLARE @idVisitante     INT;
DECLARE @idPaisLocal     INT;
DECLARE @idPaisVisitante INT;
DECLARE @idPrincipal     INT;
DECLARE @idAsist1        INT;
DECLARE @idAsist2        INT;
DECLARE @idCuarto        INT;
DECLARE @idVar           INT;
DECLARE @offset          INT = 0;
DECLARE @idTernaOut      INT;

WHILE 1 = 1
BEGIN
    SELECT TOP 1
        @idPartido   = p.id_partido,
        @idLocal     = p.id_seleccion_local,
        @idVisitante = p.id_seleccion_visitante
    FROM Mundial.Partido p
    WHERE p.id_partido > @idPartido
      AND p.fase = 'fasedegrupos'
      AND NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral t WHERE t.id_partido = p.id_partido)
    ORDER BY p.id_partido;

    IF @@ROWCOUNT = 0 BREAK;

    SELECT @idPaisLocal     = id_pais FROM Mundial.Seleccion WHERE id_seleccion = @idLocal;
    SELECT @idPaisVisitante = id_pais FROM Mundial.Seleccion WHERE id_seleccion = @idVisitante;

    DECLARE @Elegidos TABLE (
        orden      INT IDENTITY(1,1) PRIMARY KEY,
        id_arbitro INT,
        apellido   VARCHAR(50)
    );

    DECLARE @k INT = 0;
    WHILE @k < @totalArbitros AND (SELECT COUNT(*) FROM @Elegidos) < 5
    BEGIN
        SET @k = @k + 1;
        DECLARE @idx INT = ((@offset + @k - 1) % @totalArbitros) + 1;
        DECLARE @idCand   INT;
        DECLARE @apeCand  VARCHAR(50);
        DECLARE @paisCand INT;

        SELECT @idCand = id_arbitro, @apeCand = apellido, @paisCand = id_pais
        FROM @Arbitros WHERE rn = @idx;

        IF @paisCand NOT IN (@idPaisLocal, @idPaisVisitante)
            INSERT INTO @Elegidos (id_arbitro, apellido) VALUES (@idCand, @apeCand);
    END

    IF (SELECT COUNT(*) FROM @Elegidos) < 5
    BEGIN
        PRINT '  SKIP partido ' + CONVERT(VARCHAR(10), @idPartido) + ': sin 5 árbitros válidos.';
        SET @offset = @offset + 1;
        CONTINUE;
    END

    SELECT @idPrincipal = id_arbitro FROM @Elegidos WHERE orden = 1;
    SELECT @idAsist1    = id_arbitro FROM @Elegidos WHERE orden = 2;
    SELECT @idAsist2    = id_arbitro FROM @Elegidos WHERE orden = 3;
    SELECT @idCuarto    = id_arbitro FROM @Elegidos WHERE orden = 4;
    SELECT @idVar       = id_arbitro FROM @Elegidos WHERE orden = 5;

    PRINT '--- Partido id=' + CONVERT(VARCHAR(10), @idPartido) + ' ---';

    BEGIN TRY
        SET @idTernaOut = NULL;
        EXEC MfSPabm.Terna_Arbitral_Alta
             @id_partido           = @idPartido,
             @id_arbitro_principal = @idPrincipal,
             @id_asistente_1       = @idAsist1,
             @id_asistente_2       = @idAsist2,
             @id_cuarto_arbitro    = @idCuarto,
             @id_arbitro_var       = @idVar,
             @estado               = 'Activa',
             @motivo_descarte      = NULL,
             @id_terna             = @idTernaOut OUTPUT;

        PRINT '  OK: terna id=' + CONVERT(VARCHAR(10), @idTernaOut);
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH

    SET @offset = @offset + 1;
END
GO

select * from Mundial.Terna_Arbitral
go

select * from Mundial.Arbitro_terna
go

select * from Mundial.Partido
go

USE MundialDeFutbol;
GO

/* 
============================================================
   GOLES 
============================================================ 
*/

-- 1) Tabla variable con los goles a insertar
--    (partido, autor por apellido, asistente por apellido opcional)
DECLARE @Goles TABLE (
    fila             INT IDENTITY(1,1) PRIMARY KEY,
    id_partido       INT,
    apellido_autor   VARCHAR(50),
    apellido_asist   VARCHAR(50),   -- NULL si no hay asistencia
    minuto           INT,
    tipo             VARCHAR(50),
    periodo          VARCHAR(MAX)
);

INSERT INTO @Goles (id_partido, apellido_autor, apellido_asist, minuto, tipo, periodo) VALUES
-- Partido 1: Argentina vs Francia (grupo A)
(1, 'Messi',     'Álvarez',   23, 'Jugada',      'Primer tiempo'),
(1, 'Mbappé',    'Griezmann', 45, 'Penal',       'Primer tiempo'),
(1, 'Álvarez',   'Messi',     67, 'Jugada',      'Segundo tiempo'),
(1, 'Mbappé',    NULL,        89, 'Cabezazo',    'Segundo tiempo'),

-- Partido 2: México vs Japón (grupo A)
(2, 'Lozano',    'Giménez',   12, 'Jugada',      'Primer tiempo'),
(2, 'Kubo',      'Mitoma',    58, 'Tiro libre',  'Segundo tiempo'),

-- Partido 3: Brasil vs España (grupo B)
(3, 'Vinícius',  'Rodrygo',   34, 'Jugada',      'Primer tiempo'),
(3, 'Pedri',     'Morata',    72, 'Jugada',      'Segundo tiempo'),

-- Partido 4: Estados Unidos vs Marruecos (grupo B)
(4, 'Pulisic',   'McKennie',  41, 'Penal',       'Primer tiempo'),
(4, 'Ziyech',    'Hakimi',    80, 'Jugada',      'Segundo tiempo'),

-- Partido 5: Alemania vs Uruguay (grupo C)
(5, 'Musiala',   'Havertz',   18, 'Jugada',      'Primer tiempo'),
(5, 'Núñez',     'Valverde',  55, 'Cabezazo',    'Segundo tiempo'),
(5, 'Havertz',   'Kimmich',   78, 'Jugada',      'Segundo tiempo'),

-- Partido 6: Senegal vs Corea del Sur (grupo C)
(6, 'Mané',      'Gueye',     29, 'Jugada',      'Primer tiempo'),
(6, 'Son',       'Lee',       63, 'Tiro libre',  'Segundo tiempo'),

-- Partido 7: Inglaterra vs Colombia (grupo D)
(7, 'Kane',      'Bellingham', 11, 'Penal',      'Primer tiempo'),
(7, 'Díaz',      'Rodríguez', 44, 'Jugada',      'Primer tiempo'),
(7, 'Bellingham',NULL,        90, 'Jugada',      'Segundo tiempo'),

-- Partido 8: Nigeria vs Canadá (grupo D)
(8, 'Osimhen',   'Lookman',   37, 'Jugada',      'Primer tiempo'),
(8, 'Davies',    'David',     70, 'Jugada',      'Segundo tiempo');

-- 2) Recorro con WHILE 
DECLARE @fila            INT = 0;
DECLARE @totalFilas      INT;
DECLARE @idPartido       INT;
DECLARE @apellidoAutor   VARCHAR(50);
DECLARE @apellidoAsist   VARCHAR(50);
DECLARE @minuto          INT;
DECLARE @tipo            VARCHAR(50);
DECLARE @periodo         VARCHAR(MAX);
DECLARE @idAutor         INT;
DECLARE @idAsist         INT;
DECLARE @idGolOut        INT;

SELECT @totalFilas = MAX(fila) FROM @Goles;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @idPartido     = id_partido,
        @apellidoAutor = apellido_autor,
        @apellidoAsist = apellido_asist,
        @minuto        = minuto,
        @tipo          = tipo,
        @periodo       = periodo
    FROM @Goles WHERE fila = @fila;

    -- Resuelvo id_jugador_autor (debe pertenecer a una de las 2 selecciones del partido)
    SELECT @idAutor = j.id_jugador
    FROM Mundial.Jugador j
    INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    INNER JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
    INNER JOIN Mundial.Partido p
        ON p.id_partido = @idPartido
       AND s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
    WHERE j.apellido = @apellidoAutor;

    -- Resuelvo id_jugador_asistencia (opcional)
    IF @apellidoAsist IS NOT NULL
    BEGIN
        SELECT @idAsist = j.id_jugador
        FROM Mundial.Jugador j
        INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
        INNER JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
        INNER JOIN Mundial.Partido p
            ON p.id_partido = @idPartido
           AND s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
        WHERE j.apellido = @apellidoAsist;
    END
    ELSE
        SET @idAsist = NULL;

    IF @idAutor IS NULL
    BEGIN
        PRINT '  SKIP gol fila ' + CONVERT(VARCHAR(3), @fila) +
              ': autor ' + @apellidoAutor + ' no pertenece al partido ' + CONVERT(VARCHAR(10), @idPartido);
        CONTINUE;
    END

    PRINT '--- Partido ' + CONVERT(VARCHAR(10), @idPartido) +
          ' | ' + CONVERT(VARCHAR(10), @idAutor) + ' ' + @apellidoAutor + ' (min ' + CONVERT(VARCHAR(3), @minuto) + ', ' + @tipo + ') ---';

    BEGIN TRY
        SET @idGolOut = NULL;
        EXEC Mundial.Gol_Alta
             @id_partido          = @idPartido,
             @id_jugador_autor    = @idAutor,
             @id_jugador_asistencia = @idAsist,
             @minuto              = @minuto,
             @tipo                = @tipo,
             @periodo             = @periodo,
             @id_gol              = @idGolOut OUTPUT;

        PRINT '  OK: gol id=' + CONVERT(VARCHAR(10), @idGolOut);
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH

    -- Reseteo @idAsist para el próximo ciclo
    SET @idAsist = NULL;
END
GO

select * from Mundial.Gol
go

USE MundialDeFutbol;
GO

/* 
============================================================
   ESQUEMAS TÁCTICOS (formaciones comunes)
============================================================ 
*/

DECLARE @Esquemas TABLE (
    fila    INT IDENTITY(1,1) PRIMARY KEY,
    lineas  VARCHAR(15)
);

INSERT INTO @Esquemas (lineas) VALUES
-- Formaciones con 4 defensores
('4-4-2'),
('4-3-3'),
('4-2-3-1'),
('4-1-4-1'),
('4-5-1'),
('4-4-1-1'),
('4-3-1-2'),
('4-1-3-2'),
('4-2-2-2'),
-- Formaciones con 3 defensores
('3-5-2'),
('3-4-3'),
('3-4-2-1'),
('3-6-1'),
('3-4-1-2'),
-- Formaciones con 5 defensores
('5-3-2'),
('5-4-1'),
('5-2-3');

DECLARE @fila      INT = 0;
DECLARE @totalFilas INT;
DECLARE @lineas    VARCHAR(15);

SELECT @totalFilas = MAX(fila) FROM @Esquemas;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT @lineas = lineas FROM @Esquemas WHERE fila = @fila;

    PRINT '--- Esquema: ' + @lineas + ' ---';

    BEGIN TRY
        EXEC Mundial.usp_Esquema_Alta @lineas = @lineas;
        PRINT '  Insertado.';
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--Creado correctamente
select * from Mundial.Esquema
go


USE MundialDeFutbol;
GO

/* 
============================================================
   FORMACIONES 
============================================================ 
*/

-- 1) Cargo los esquemas disponibles en una tabla con ROW_NUMBER
DECLARE @Esquemas TABLE (
    rn         INT IDENTITY(1,1) PRIMARY KEY,
    id_esquema INT,
    lineas     VARCHAR(15)
);

INSERT INTO @Esquemas (id_esquema, lineas)
SELECT id_esquema, lineas
FROM Mundial.Esquema
ORDER BY id_esquema;

DECLARE @totalEsquemas INT;
SELECT @totalEsquemas = COUNT(*) FROM @Esquemas;

IF @totalEsquemas = 0
BEGIN
    PRINT 'ERROR: no hay esquemas cargados. Corré primero usp_Esquema_Alta.';
    RETURN;
END

-- 2) Recorro los partidos y cargo 2 formaciones por partido
DECLARE @idPartido     INT = 0;
DECLARE @idLocal       INT;
DECLARE @idVisitante   INT;
DECLARE @idEsquemaLoc  INT;
DECLARE @idEsquemaVis  INT;
DECLARE @offset        INT = 0;

WHILE 1 = 1
BEGIN
    SELECT TOP 1
        @idPartido   = p.id_partido,
        @idLocal     = p.id_seleccion_local,
        @idVisitante = p.id_seleccion_visitante
    FROM Mundial.Partido p
    WHERE p.id_partido > @idPartido
      AND p.fase = 'fasedegrupos'
    ORDER BY p.id_partido;

    IF @@ROWCOUNT = 0 BREAK;

    -- Rotación de esquemas: local usa uno, visitante usa el siguiente
    DECLARE @posLoc INT = (@offset % @totalEsquemas) + 1;
    DECLARE @posVis INT = ((@offset + 1) % @totalEsquemas) + 1;

    SELECT @idEsquemaLoc = id_esquema FROM @Esquemas WHERE rn = @posLoc;
    SELECT @idEsquemaVis = id_esquema FROM @Esquemas WHERE rn = @posVis;

    PRINT '--- Partido ' + CONVERT(VARCHAR(10), @idPartido) +
          ' | local seleccion=' + CONVERT(VARCHAR(10), @idLocal) +
          ' (esquema ' + CONVERT(VARCHAR(10), @idEsquemaLoc) + ')' +
          ' | visitante seleccion=' + CONVERT(VARCHAR(10), @idVisitante) +
          ' (esquema ' + CONVERT(VARCHAR(10), @idEsquemaVis) + ') ---';

    -- Formación del LOCAL
    BEGIN TRY
        EXEC MfSPabm.usp_Formacion_Alta
             @id_partido   = @idPartido,
             @id_seleccion = @idLocal,
             @id_esquema   = @idEsquemaLoc;
        PRINT '  Local OK';
    END TRY
    BEGIN CATCH
        PRINT '  Local ERROR: ' + ERROR_MESSAGE();
    END CATCH

    -- Formación del VISITANTE
    BEGIN TRY
        EXEC MfSPabm.usp_Formacion_Alta
             @id_partido   = @idPartido,
             @id_seleccion = @idVisitante,
             @id_esquema   = @idEsquemaVis;
        PRINT '  Visitante OK';
    END TRY
    BEGIN CATCH
        PRINT '  Visitante ERROR: ' + ERROR_MESSAGE();
    END CATCH

    SET @offset = @offset + 1;
END
GO

--Cargado correctamente
select * from Mundial.Formacion
go

USE MundialDeFutbol;
GO

/* 
============================================================
   POSICIONES (fútbol 11)
============================================================
*/

DECLARE @Posiciones TABLE (
    fila         INT IDENTITY(1,1) PRIMARY KEY,
    nombre       VARCHAR(30),
    abreviatura  VARCHAR(5)
);

INSERT INTO @Posiciones (nombre, abreviatura) VALUES
-- Arqueros
('Arquero',              'ARQ'),
-- Defensores
('Defensor central',     'DFC'),
('Lateral derecho',      'LD'),
('Lateral izquierdo',    'LI'),
-- Mediocampistas
('Mediocampista defensivo', 'MCD'),
('Mediocampista central',   'MC'),
('Mediocampista ofensivo',  'MCO'),
('Volante derecho',         'VD'),
('Volante izquierdo',       'VI'),
-- Delanteros
('Delantero centro',     'DC'),
('Segundo delantero',    'SD'),
('Extremo derecho',      'ED'),
('Extremo izquierdo',    'EI');

DECLARE @fila        INT = 0;
DECLARE @totalFilas  INT;
DECLARE @nombre      VARCHAR(30);
DECLARE @abreviatura VARCHAR(5);
DECLARE @mensaje     VARCHAR(500);
DECLARE @rc          INT;

SELECT @totalFilas = MAX(fila) FROM @Posiciones;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT @nombre = nombre, @abreviatura = abreviatura
    FROM @Posiciones
    WHERE fila = @fila;

    PRINT '--- Posicion: ' + @nombre + ' (' + @abreviatura + ') ---';

    BEGIN TRY
        SET @mensaje = NULL;
        EXEC @rc = MfSPabm.usp_Posicion_Alta
             @nombre      = @nombre,
             @abreviatura = @abreviatura,
             @mensaje     = @mensaje OUTPUT;

        IF @rc = 0
            PRINT '  OK: insertada.';
        ELSE
            PRINT '  OMITIDO: ' + ISNULL(@mensaje, '(sin mensaje)');
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--cargadas correctamente
select * from Mundial.Posicion
go

/*
============================================================
   Jugador_Formacion(Con los jugadores de prueba)
============================================================
*/

-- 1) Armo la tabla con (país, apellido, posición)
DECLARE @Alineaciones TABLE (
    fila         INT IDENTITY(1,1) PRIMARY KEY,
    nombrePais   VARCHAR(30),
    apellido     VARCHAR(50),
    posicion     VARCHAR(30)
);

INSERT INTO @Alineaciones (nombrePais, apellido, posicion) VALUES
-- GRUPO A
('Argentina',    'Martínez',    'Arquero'),
('Argentina',    'Messi',       'Mediocampista ofensivo'),
('Argentina',    'Álvarez',     'Delantero centro'),
('Argentina',    'Fernández',   'Mediocampista central'),
('Francia',      'Maignan',     'Arquero'),
('Francia',      'Mbappé',      'Delantero centro'),
('Francia',      'Griezmann',   'Segundo delantero'),
('Francia',      'Tchouaméni',  'Mediocampista defensivo'),
('México',       'Ochoa',       'Arquero'),
('México',       'Lozano',      'Extremo derecho'),
('México',       'Giménez',     'Delantero centro'),
('México',       'Álvarez',     'Mediocampista defensivo'),
('Japón',        'Gonda',       'Arquero'),
('Japón',        'Kubo',        'Mediocampista ofensivo'),
('Japón',        'Mitoma',      'Extremo izquierdo'),
('Japón',        'Endo',        'Mediocampista defensivo'),

-- GRUPO B
('Brasil',       'Becker',      'Arquero'),
('Brasil',       'Júnior',      'Extremo izquierdo'),
('Brasil',       'Goes',        'Extremo derecho'),
('Brasil',       'Santos',      'Mediocampista defensivo'),
('España',       'Simón',       'Arquero'),
('España',       'González',    'Mediocampista central'),
('España',       'Morata',      'Delantero centro'),
('España',       'Hernández',   'Mediocampista defensivo'),
('Estados Unidos','Turner',     'Arquero'),
('Estados Unidos','Pulisic',    'Extremo izquierdo'),
('Estados Unidos','McKennie',   'Mediocampista central'),
('Estados Unidos','Adams',      'Mediocampista defensivo'),
('Marruecos',    'Bounou',      'Arquero'),
('Marruecos',    'Ziyech',      'Extremo derecho'),
('Marruecos',    'Hakimi',      'Lateral derecho'),
('Marruecos',    'Amrabat',     'Mediocampista defensivo'),

-- GRUPO C
('Alemania',     'Neuer',       'Arquero'),
('Alemania',     'Musiala',     'Mediocampista ofensivo'),
('Alemania',     'Havertz',     'Delantero centro'),
('Alemania',     'Kimmich',     'Mediocampista central'),
('Uruguay',      'Rochet',      'Arquero'),
('Uruguay',      'Valverde',    'Mediocampista central'),
('Uruguay',      'Núñez',       'Delantero centro'),
('Uruguay',      'Araújo',      'Defensor central'),
('Senegal',      'Mendy',       'Arquero'),
('Senegal',      'Mané',        'Extremo izquierdo'),
('Senegal',      'Koulibaly',   'Defensor central'),
('Senegal',      'Gueye',       'Mediocampista defensivo'),
('Corea del Sur','Seung-gyu',   'Arquero'),
('Corea del Sur','Heung-min',   'Extremo izquierdo'),
('Corea del Sur','Kang-in',     'Mediocampista ofensivo'),
('Corea del Sur','Min-jae',     'Defensor central'),

-- GRUPO D
('Inglaterra',   'Pickford',    'Arquero'),
('Inglaterra',   'Bellingham',  'Mediocampista ofensivo'),
('Inglaterra',   'Kane',        'Delantero centro'),
('Inglaterra',   'Saka',        'Extremo derecho'),
('Colombia',     'Ospina',      'Arquero'),
('Colombia',     'Rodríguez',   'Mediocampista ofensivo'),
('Colombia',     'Díaz',        'Extremo izquierdo'),
('Colombia',     'Durán',       'Delantero centro'),
('Nigeria',      'Uzoho',       'Arquero'),
('Nigeria',      'Osimhen',     'Delantero centro'),
('Nigeria',      'Lookman',     'Extremo izquierdo'),
('Nigeria',      'Iwobi',       'Mediocampista central'),
('Canadá',       'Borjan',      'Arquero'),
('Canadá',       'Davies',      'Lateral izquierdo'),
('Canadá',       'David',       'Delantero centro'),
('Canadá',       'Larin',       'Delantero centro'),

-- GRUPO E
('Portugal',     'Costa',       'Arquero'),
('Portugal',     'Ronaldo',     'Delantero centro'),
('Portugal',     'Fernandes',   'Mediocampista ofensivo'),
('Portugal',     'Silva',       'Mediocampista ofensivo'),
('Ecuador',      'Galíndez',    'Arquero'),
('Ecuador',      'Caicedo',     'Mediocampista defensivo'),
('Ecuador',      'Valencia',    'Delantero centro'),
('Ecuador',      'Hincapié',    'Defensor central'),
('Egipto',       'El-Shenawy',  'Arquero'),
('Egipto',       'Salah',       'Extremo derecho'),
('Egipto',       'Marmoush',    'Delantero centro'),
('Egipto',       'Mohamed',     'Mediocampista defensivo'),
('Costa Rica',   'Navas',       'Arquero'),
('Costa Rica',   'Campbell',    'Mediocampista ofensivo'),
('Costa Rica',   'Ugalde',      'Delantero centro'),
('Costa Rica',   'Calvo',       'Defensor central'),

-- GRUPO F
('Italia',       'Donnarumma',  'Arquero'),
('Italia',       'Barella',     'Mediocampista central'),
('Italia',       'Chiesa',      'Extremo derecho'),
('Italia',       'Bastoni',     'Defensor central'),
('Paraguay',     'Sanabria',    'Delantero centro'),
('Paraguay',     'Almirón',     'Extremo derecho'),
('Paraguay',     'Sosa',        'Mediocampista central'),
('Paraguay',     'Gómez',       'Defensor central'),
('Camerún',      'Onana',       'Arquero'),
('Camerún',      'Aboubakar',   'Delantero centro'),
('Camerún',      'Toko Ekambi', 'Extremo izquierdo'),
('Camerún',      'Zambo Anguissa','Mediocampista defensivo'),
('Australia',    'Ryan',        'Arquero'),
('Australia',    'Irvine',      'Mediocampista central'),
('Australia',    'Duke',        'Delantero centro'),
('Australia',    'Souttar',     'Defensor central'),

-- GRUPO G
('Países Bajos', 'Verbruggen',  'Arquero'),
('Países Bajos', 'van Dijk',    'Defensor central'),
('Países Bajos', 'de Jong',     'Mediocampista central'),
('Países Bajos', 'Gakpo',       'Extremo izquierdo'),
('Bélgica',      'Casteels',    'Arquero'),
('Bélgica',      'De Bruyne',   'Mediocampista ofensivo'),
('Bélgica',      'Lukaku',      'Delantero centro'),
('Bélgica',      'Doku',        'Extremo derecho'),
('Croacia',      'Livaković',   'Arquero'),
('Croacia',      'Modrić',      'Mediocampista central'),
('Croacia',      'Kovačić',     'Mediocampista central'),
('Croacia',      'Gvardiol',    'Defensor central'),
('Dinamarca',    'Schmeichel',  'Arquero'),
('Dinamarca',    'Eriksen',     'Mediocampista ofensivo'),
('Dinamarca',    'Højlund',     'Delantero centro'),
('Dinamarca',    'Højbjerg',    'Mediocampista defensivo'),

-- GRUPO H
('Suiza',        'Sommer',      'Arquero'),
('Suiza',        'Xhaka',       'Mediocampista central'),
('Suiza',        'Akanji',      'Defensor central'),
('Suiza',        'Embolo',      'Delantero centro'),
('Serbia',       'Rajković',    'Arquero'),
('Serbia',       'Vlahović',    'Delantero centro'),
('Serbia',       'Milinković-Savić','Mediocampista central'),
('Serbia',       'Mitrović',    'Delantero centro'),
('Polonia',      'Szczęsny',    'Arquero'),
('Polonia',      'Lewandowski', 'Delantero centro'),
('Polonia',      'Zieliński',   'Mediocampista ofensivo'),
('Polonia',      'Zalewski',    'Lateral izquierdo'),
('Austria',      'Pentz',       'Arquero'),
('Austria',      'Sabitzer',    'Mediocampista ofensivo'),
('Austria',      'Laimer',      'Mediocampista defensivo'),
('Austria',      'Arnautović',  'Delantero centro');

-- 2) Recorro con WHILE (sin cursor)
DECLARE @fila         INT = 0;
DECLARE @totalFilas   INT;
DECLARE @nombrePais   VARCHAR(30);
DECLARE @apellido     VARCHAR(50);
DECLARE @posicion     VARCHAR(30);
DECLARE @idLista      INT;
DECLARE @idSeleccion  INT;
DECLARE @idJugador    INT;
DECLARE @idPosicion   INT;
DECLARE @idFormacion  INT;
DECLARE @mensaje      VARCHAR(500);
DECLARE @rc           INT;

SELECT @totalFilas = MAX(fila) FROM @Alineaciones;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT @nombrePais = nombrePais,
           @apellido   = apellido,
           @posicion   = posicion
    FROM @Alineaciones
    WHERE fila = @fila;

    -- 1) Resuelvo la selección y lista de convocados del país
    SELECT @idSeleccion = s.id_seleccion, @idLista = lc.id_lista
    FROM Mundial.Seleccion s
    INNER JOIN Mundial.Pais p ON p.id_pais = s.id_pais
    INNER JOIN Mundial.ListaConvocados lc ON lc.id_seleccion = s.id_seleccion
    WHERE p.nombre = @nombrePais;

    IF @idLista IS NULL
    BEGIN
        PRINT '  SKIP: no hay lista para ' + @nombrePais;
        CONTINUE;
    END

    -- 2) Resuelvo el jugador por apellido dentro de la lista
    SELECT @idJugador = j.id_jugador
    FROM Mundial.Jugador j
    WHERE j.id_lista_convocados = @idLista
      AND j.apellido = @apellido;

    IF @idJugador IS NULL
    BEGIN
        PRINT '  SKIP: jugador ' + @apellido + ' no encontrado en ' + @nombrePais;
        CONTINUE;
    END

    -- 3) Resuelvo la posición por nombre
    SELECT @idPosicion = id_posicion
    FROM Mundial.Posicion
    WHERE nombre = @posicion;

    IF @idPosicion IS NULL
    BEGIN
        PRINT '  SKIP: posición ' + @posicion + ' no encontrada';
        CONTINUE;
    END

    -- 4) Resuelvo la formación del partido donde juega la selección
    --    (elijo la primera formación de la selección, por id)
    SELECT TOP 1 @idFormacion = f.id_formacion
    FROM Mundial.Formacion f
    WHERE f.id_seleccion = @idSeleccion
    ORDER BY f.id_formacion;

    IF @idFormacion IS NULL
    BEGIN
        PRINT '  SKIP: no hay formación para ' + @nombrePais;
        CONTINUE;
    END

    PRINT '--- ' + @nombrePais + ' | ' + @apellido + ' (' + @posicion + ') | formacion ' +
          CONVERT(VARCHAR(10), @idFormacion) + ' ---';

    BEGIN TRY
        SET @mensaje = NULL;
        EXEC @rc = MfSPabm.usp_Jugador_Formacion_Alta
             @id_formacion = @idFormacion,
             @id_jugador   = @idJugador,
             @id_posicion  = @idPosicion,
             @es_titular   = 1;

        IF @rc = 0
            PRINT '  OK: titular insertado.';
        ELSE
            PRINT '  OMITIDO: ' + ISNULL(@mensaje, '(sin mensaje)');
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO


select * from Mundial.Jugador_Formacion
go

USE MundialDeFutbol;
GO

/* 
============================================================
   TARJETAS con casos de expulsión y acumulación
============================================================ 
*/

DECLARE @Tarjetas TABLE (
    fila         INT IDENTITY(1,1) PRIMARY KEY,
    id_partido   INT,
    apellido     VARCHAR(50),
    minuto       INT,
    motivo       VARCHAR(MAX),
    color        VARCHAR(MAX)
);

INSERT INTO @Tarjetas (id_partido, apellido, minuto, motivo, color) VALUES

-- ============================================================
-- CASO 1: EXPULSIÓN POR ROJA DIRECTA
-- Fernández (Argentina) ve roja directa en el partido 1 (vs Francia)
-- → NO juega el partido 17 (Argentina vs México)
-- ============================================================
(1, 'Fernández',   72, 'Roja directa por conducta violenta', 'Roja'),

-- ============================================================
-- CASO 2: EXPULSIÓN POR DOBLE AMARILLA
-- Tchouaméni (Francia) ve 2 amarillas en el partido 1 (vs Argentina)
-- → NO juega el partido 17 (Francia vs Japón)
-- ============================================================
(1, 'Tchouaméni',  34, 'Primera amarilla - falta táctica',   'Amarilla'),
(1, 'Tchouaméni',  78, 'Segunda amarilla - retraso de juego','Amarilla'),

-- ============================================================
-- CASO 3: ACUMULACIÓN DE AMARILLAS EN PARTIDOS DISTINTOS
-- Messi (Argentina) ve amarilla en partido 1 y en partido 17
-- → NO juega el partido 33 (Argentina vs Japón)
-- ============================================================
(1,  'Messi',      45, 'Amarilla - protestar al árbitro',    'Amarilla'),
(17, 'Messi',      60, 'Amarilla - falta táctica',           'Amarilla'),

-- ============================================================
-- TARJETAS NORMALES (sin suspensión)
-- ============================================================

-- Partido 2: México vs Japón
(2, 'Álvarez',     28, 'Falta dura en mediocampo',           'Amarilla'),
(2, 'Endo',        81, 'Retraso de juego',                   'Amarilla'),

-- Partido 3: Brasil vs España
(3, 'Santos',      45, 'Falta táctica',                      'Amarilla'),
(3, 'Hernández',   88, 'Falta dura',                         'Amarilla'),

-- Partido 4: Estados Unidos vs Marruecos
(4, 'Adams',       52, 'Falta táctica',                      'Amarilla'),
(4, 'Amrabat',     90, 'Conducta violenta',                  'Roja'),

-- Partido 5: Alemania vs Uruguay
(5, 'Kimmich',     23, 'Protestar al árbitro',              'Amarilla'),
(5, 'Araújo',      67, 'Falta dura',                         'Amarilla'),

-- Partido 6: Senegal vs Corea del Sur
(6, 'Gueye',       39, 'Falta táctica',                      'Amarilla'),
(6, 'Min-jae',     75, 'Doble amarilla',                     'Roja'),

-- Partido 7: Inglaterra vs Colombia
(7, 'Kane',        58, 'Simulación',                         'Amarilla'),
(7, 'Durán',       84, 'Falta dura',                         'Amarilla'),

-- Partido 8: Nigeria vs Canadá
(8, 'Iwobi',       31, 'Falta táctica',                      'Amarilla'),
(8, 'Larin',       66, 'Retraso de juego',                   'Amarilla'),

-- Partido 9: Portugal vs Ecuador
(9, 'Fernandes',   44, 'Protestar al árbitro',              'Amarilla'),
(9, 'Caicedo',     79, 'Falta dura',                         'Amarilla'),

-- Partido 10: Egipto vs Costa Rica
(10, 'Mohamed',    29, 'Falta táctica',                      'Amarilla'),
(10, 'Calvo',      87, 'Conducta violenta',                  'Roja'),

-- Partido 11: Italia vs Paraguay
(11, 'Barella',    35, 'Falta táctica',                      'Amarilla'),
(11, 'Gómez',      68, 'Falta dura',                         'Amarilla'),

-- Partido 12: Camerún vs Australia
(12, 'Zambo Anguissa', 41, 'Protestar al árbitro',          'Amarilla'),
(12, 'Souttar',    73, 'Doble amarilla',                     'Roja'),

-- Partido 13: Países Bajos vs Bélgica
(13, 'de Jong',    26, 'Falta táctica',                      'Amarilla'),
(13, 'Doku',       62, 'Simulación',                         'Amarilla'),

-- Partido 14: Croacia vs Dinamarca
(14, 'Kovačić',    48, 'Falta táctica',                      'Amarilla'),
(14, 'Højbjerg',   85, 'Falta dura',                         'Amarilla'),

-- Partido 15: Suiza vs Serbia
(15, 'Xhaka',      33, 'Protestar al árbitro',              'Amarilla'),
(15, 'Mitrović',   71, 'Conducta violenta',                  'Roja'),

-- Partido 16: Polonia vs Austria
(16, 'Zieliński',  54, 'Falta táctica',                      'Amarilla'),
(16, 'Laimer',     89, 'Retraso de juego',                   'Amarilla');

-- Recorro con WHILE (sin cursor)
DECLARE @fila         INT = 0;
DECLARE @totalFilas   INT;
DECLARE @idPartido    INT;
DECLARE @apellido     VARCHAR(50);
DECLARE @minuto       INT;
DECLARE @motivo       VARCHAR(MAX);
DECLARE @color        VARCHAR(MAX);
DECLARE @idJugador    INT;
DECLARE @idTarjetaOut INT;

SELECT @totalFilas = MAX(fila) FROM @Tarjetas;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @idPartido = id_partido,
        @apellido  = apellido,
        @minuto    = minuto,
        @motivo    = motivo,
        @color     = color
    FROM @Tarjetas WHERE fila = @fila;

    -- Resuelvo id_jugador (debe pertenecer al partido)
    SELECT @idJugador = j.id_jugador
    FROM Mundial.Jugador j
    INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    INNER JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
    INNER JOIN Mundial.Partido p
        ON p.id_partido = @idPartido
       AND s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
    WHERE j.apellido = @apellido;

    IF @idJugador IS NULL
    BEGIN
        PRINT '  SKIP fila ' + CONVERT(VARCHAR(3), @fila) +
              ': jugador ' + @apellido + ' no pertenece al partido ' + CONVERT(VARCHAR(10), @idPartido);
        CONTINUE;
    END

    PRINT '--- Partido ' + CONVERT(VARCHAR(10), @idPartido) +
          ' | ' + @apellido + ' (min ' + CONVERT(VARCHAR(3), @minuto) + ', ' + @color + ') ---';

    BEGIN TRY
        SET @idTarjetaOut = NULL;
        EXEC MfSPabm.Tarjeta_Alta
             @id_partido = @idPartido,
             @id_jugador = @idJugador,
             @minuto     = @minuto,
             @motivo     = @motivo,
             @color      = @color,
             @id_tarjeta = @idTarjetaOut OUTPUT;

        PRINT '  OK: tarjeta id=' + CONVERT(VARCHAR(10), @idTarjetaOut);
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO

USE MundialDeFutbol;
GO

/* 
============================================================
   EXPULSIONES (vinculadas a tarjetas existentes)
============================================================ 
*/

-- 1) Tabla con (partido, apellido, minuto de la tarjeta, tipo expulsión)
DECLARE @Expulsiones TABLE (
    fila          INT IDENTITY(1,1) PRIMARY KEY,
    id_partido    INT,
    apellido      VARCHAR(50),
    minuto        INT,
    tipoexpulsion VARCHAR(MAX)
);

INSERT INTO @Expulsiones (id_partido, apellido, minuto, tipoexpulsion) VALUES
-- Caso 1: Enzo Fernández - roja directa en partido 1
(1,  'Fernández',   72, 'Roja'),
-- Caso 2: Tchouaméni - doble amarilla en partido 1 (la 2da amarilla es la del min 78)
(1,  'Tchouaméni',  78, 'Doble amarilla'),
-- Caso 3: Amrabat - roja directa en partido 4
(4,  'Amrabat',     90, 'Roja'),
-- Caso 4: Calvo - roja directa en partido 10
(10, 'Calvo',       87, 'Roja'),
-- Caso 5: Mitrović - roja directa en partido 15
(15, 'Mitrović',    71, 'Roja'),
-- Caso 6: Min-jae - doble amarilla
(6, 'Min-jae',    75, 'doble amarilla'),
-- Caso 7: Souttar - doble amarilla
(12, 'Souttar',    73, 'doble amarilla');

-- 2) Recorro con WHILE
DECLARE @fila          INT = 0;
DECLARE @totalFilas    INT;
DECLARE @idPartido     INT;
DECLARE @apellido      VARCHAR(50);
DECLARE @minuto        INT;
DECLARE @tipoexpulsion VARCHAR(MAX);
DECLARE @idJugador     INT;
DECLARE @idTarjeta     INT;
DECLARE @idExpulsionOut INT;

SELECT @totalFilas = MAX(fila) FROM @Expulsiones;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @idPartido     = id_partido,
        @apellido      = apellido,
        @minuto        = minuto,
        @tipoexpulsion = tipoexpulsion
    FROM @Expulsiones WHERE fila = @fila;

    -- Resuelvo id_jugador (por apellido, dentro del partido)
    SELECT @idJugador = j.id_jugador
    FROM Mundial.Jugador j
    INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
    INNER JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
    INNER JOIN Mundial.Partido p
        ON p.id_partido = @idPartido
       AND s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
    WHERE j.apellido = @apellido;

    IF @idJugador IS NULL
    BEGIN
        PRINT '  SKIP fila ' + CONVERT(VARCHAR(3), @fila) +
              ': jugador ' + @apellido + ' no pertenece al partido ' + CONVERT(VARCHAR(10), @idPartido);
        CONTINUE;
    END

    -- Resuelvo id_tarjeta (la del jugador en ese partido, en ese minuto)
    SELECT @idTarjeta = t.id_tarjeta
    FROM Mundial.Tarjeta t
    WHERE t.id_partido = @idPartido
      AND t.id_jugador = @idJugador
      AND t.minuto     = @minuto;

    IF @idTarjeta IS NULL
    BEGIN
        PRINT '  SKIP fila ' + CONVERT(VARCHAR(3), @fila) +
              ': no hay tarjeta para ' + @apellido + ' en partido ' +
              CONVERT(VARCHAR(10), @idPartido) + ' min ' + CONVERT(VARCHAR(3), @minuto);
        CONTINUE;
    END

    PRINT '--- Expulsion: ' + @apellido + ' (partido ' + CONVERT(VARCHAR(10), @idPartido) +
          ', min ' + CONVERT(VARCHAR(3), @minuto) + ', tipo ' + @tipoexpulsion + ') ---';

    BEGIN TRY
        SET @idExpulsionOut = NULL;
        EXEC MfSPabm.Expulsion_Alta
             @id_tarjeta    = @idTarjeta,
             @tipoexpulsion = @tipoexpulsion,
             @id_expulsion  = @idExpulsionOut OUTPUT;

        PRINT '  OK: expulsion id=' + CONVERT(VARCHAR(10), @idExpulsionOut);
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO

select * from Mundial.Expulsion
go


USE MundialDeFutbol;
GO

/* 
============================================================
   ESPACIOS PUBLICITARIOS (4 por sede)
============================================================ 
*/

-- 1) Tabla variable con las sedes y descripciones
DECLARE @Espacios TABLE (
    fila             INT IDENTITY(1,1) PRIMARY KEY,
    nombre_estadio   NVARCHAR(200),
    numero_espacio   TINYINT,
    descripcion      VARCHAR(100)
);

-- Para cada sede, 4 espacios con descripciones variadas
-- Uso los 12 estadios del script de sedes
INSERT INTO @Espacios (nombre_estadio, numero_espacio, descripcion) VALUES
-- Estadio Monumental (Buenos Aires)
(N'Estadio Monumental Antonio V. Liberti', 1, 'Cartel LED principal - Frente a cámara'),
(N'Estadio Monumental Antonio V. Liberti', 2, 'Valla perimetral sector popular'),
(N'Estadio Monumental Antonio V. Liberti', 3, 'Pantalla gigante marcador'),
(N'Estadio Monumental Antonio V. Liberti', 4, 'Backing campo de juego'),

-- La Bombonera (Buenos Aires)
(N'Estadio Alberto J. Armando (La Bombonera)', 1, 'Cartel LED tribuna lateral'),
(N'Estadio Alberto J. Armando (La Bombonera)', 2, 'Valla perimetral popular'),
(N'Estadio Alberto J. Armando (La Bombonera)', 3, 'Pantalla sector visitante'),
(N'Estadio Alberto J. Armando (La Bombonera)', 4, 'Backing campo de juego'),

-- Ciudad de La Plata
(N'Estadio Ciudad de La Plata', 1, 'Cartel LED principal'),
(N'Estadio Ciudad de La Plata', 2, 'Valla perimetral sector A'),
(N'Estadio Ciudad de La Plata', 3, 'Pantalla gigante'),
(N'Estadio Ciudad de La Plata', 4, 'Backing campo'),

-- Mario Alberto Kempes (Córdoba)
(N'Estadio Mario Alberto Kempes', 1, 'Cartel LED principal'),
(N'Estadio Mario Alberto Kempes', 2, 'Valla perimetral'),
(N'Estadio Mario Alberto Kempes', 3, 'Pantalla marcador'),
(N'Estadio Mario Alberto Kempes', 4, 'Backing campo'),

-- Malvinas Argentinas (Mendoza)
(N'Estadio Malvinas Argentinas', 1, 'Cartel LED principal'),
(N'Estadio Malvinas Argentinas', 2, 'Valla perimetral'),
(N'Estadio Malvinas Argentinas', 3, 'Pantalla sector visitante'),
(N'Estadio Malvinas Argentinas', 4, 'Backing campo'),

-- Gigante de Arroyito (Rosario)
(N'Estadio Gigante de Arroyito', 1, 'Cartel LED principal'),
(N'Estadio Gigante de Arroyito', 2, 'Valla perimetral'),
(N'Estadio Gigante de Arroyito', 3, 'Pantalla marcador'),
(N'Estadio Gigante de Arroyito', 4, 'Backing campo'),

-- Padre Ernesto Martearena (Salta)
(N'Estadio Padre Ernesto Martearena', 1, 'Cartel LED principal'),
(N'Estadio Padre Ernesto Martearena', 2, 'Valla perimetral'),
(N'Estadio Padre Ernesto Martearena', 3, 'Pantalla marcador'),
(N'Estadio Padre Ernesto Martearena', 4, 'Backing campo'),

-- Bicentenario de San Juan
(N'Estadio Bicentenario de San Juan', 1, 'Cartel LED principal'),
(N'Estadio Bicentenario de San Juan', 2, 'Valla perimetral'),
(N'Estadio Bicentenario de San Juan', 3, 'Pantalla marcador'),
(N'Estadio Bicentenario de San Juan', 4, 'Backing campo'),

-- Único de La Plata
(N'Estadio Único de La Plata', 1, 'Cartel LED principal'),
(N'Estadio Único de La Plata', 2, 'Valla perimetral'),
(N'Estadio Único de La Plata', 3, 'Pantalla marcador'),
(N'Estadio Único de La Plata', 4, 'Backing campo'),

-- José Amalfitani (Buenos Aires)
(N'Estadio José Amalfitani', 1, 'Cartel LED principal'),
(N'Estadio José Amalfitani', 2, 'Valla perimetral'),
(N'Estadio José Amalfitani', 3, 'Pantalla marcador'),
(N'Estadio José Amalfitani', 4, 'Backing campo'),

-- Tomás Adolfo Ducó (Buenos Aires)
(N'Estadio Tomás Adolfo Ducó', 1, 'Cartel LED principal'),
(N'Estadio Tomás Adolfo Ducó', 2, 'Valla perimetral'),
(N'Estadio Tomás Adolfo Ducó', 3, 'Pantalla marcador'),
(N'Estadio Tomás Adolfo Ducó', 4, 'Backing campo'),

-- Libertadores de América (Avellaneda)
(N'Estadio Libertadores de América', 1, 'Cartel LED principal'),
(N'Estadio Libertadores de América', 2, 'Valla perimetral'),
(N'Estadio Libertadores de América', 3, 'Pantalla marcador'),
(N'Estadio Libertadores de América', 4, 'Backing campo');

-- 2) Recorro con WHILE
DECLARE @fila              INT = 0;
DECLARE @totalFilas        INT;
DECLARE @nombreEstadio     NVARCHAR(200);
DECLARE @numeroEspacio     TINYINT;
DECLARE @descripcion       VARCHAR(100);
DECLARE @idEspacio         INT;


SELECT @totalFilas = MAX(fila) FROM @Espacios;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @nombreEstadio  = nombre_estadio,
        @numeroEspacio  = numero_espacio,
        @descripcion    = descripcion
    FROM @Espacios WHERE fila = @fila;

    SET @idEspacio = (
        SELECT ep.id_espacio FROM Mundial.Espacio_publicitario ep
        JOIN Mundial.Sede s ON s.id_sede = ep.id_sede
        WHERE s.nombre_estadio = @nombreEstadio AND ep.numero_espacio = @numeroEspacio
    );

    IF @idEspacio IS NULL
    BEGIN
        PRINT '  SKIP: no se encontro el panel en la sede.';
        CONTINUE;
    END

    BEGIN TRY
        EXEC MfSPabm.usp_Espacio_publicitario_Modificacion
             @id_espacio = @idEspacio,
             @descripcion = @descripcion;

        PRINT '  OK: panel actualizado.';
    END TRY
    BEGIN CATCH
        PRINT '  ERROR: ' + ERROR_MESSAGE();
    END CATCH

END
GO

select * from Mundial.Espacio_publicitario
go

GO
/* Husos horarios de Pais para Matriz Prime Time (E7) */
UPDATE Mundial.Pais SET huso_horario = CASE nombre
  WHEN 'Argentina' THEN 'UTC-03:00' WHEN 'Brasil' THEN 'UTC-03:00' WHEN 'Uruguay' THEN 'UTC-03:00'
  WHEN 'Colombia' THEN 'UTC-05:00' WHEN 'Ecuador' THEN 'UTC-05:00' WHEN 'Paraguay' THEN 'UTC-04:00'
  WHEN 'Francia' THEN 'UTC+02:00' WHEN 'España' THEN 'UTC+02:00' WHEN 'Alemania' THEN 'UTC+02:00'
  WHEN 'Inglaterra' THEN 'UTC+01:00' WHEN 'Italia' THEN 'UTC+02:00' WHEN 'Portugal' THEN 'UTC+01:00'
  WHEN 'Paises Bajos' THEN 'UTC+02:00' WHEN 'Bélgica' THEN 'UTC+02:00' WHEN 'Croacia' THEN 'UTC+02:00'
  WHEN 'Noruega' THEN 'UTC+02:00' WHEN 'Suiza' THEN 'UTC+02:00' WHEN 'Serbia' THEN 'UTC+02:00'
  WHEN 'Polonia' THEN 'UTC+02:00' WHEN 'Austria' THEN 'UTC+02:00' WHEN 'México' THEN 'UTC-06:00'
  WHEN 'USA' THEN 'UTC-05:00' WHEN 'Estados Unidos' THEN 'UTC-05:00' WHEN 'Canadá' THEN 'UTC-05:00'
  WHEN 'Costa Rica' THEN 'UTC-06:00' WHEN 'Marruecos' THEN 'UTC+01:00' WHEN 'Senegal' THEN 'UTC+00:00'
  WHEN 'Nigeria' THEN 'UTC+01:00' WHEN 'Egipto' THEN 'UTC+02:00' WHEN 'Costa de Marfil' THEN 'UTC+00:00'
  WHEN 'Japon' THEN 'UTC+09:00' WHEN 'Japón' THEN 'UTC+09:00' WHEN 'Corea del Sur' THEN 'UTC+09:00'
  WHEN 'Australia' THEN 'UTC+10:00' ELSE huso_horario
END
WHERE nombre IN (
  'Argentina','Brasil','Uruguay','Colombia','Ecuador','Paraguay','Francia','España','Alemania',
  'Inglaterra','Italia','Portugal','Paises Bajos','Bélgica','Croacia','Noruega','Suiza','Serbia',
  'Polonia','Austria','México','USA','Estados Unidos','Canadá','Costa Rica','Marruecos','Senegal',
  'Nigeria','Egipto','Costa de Marfil','Japon','Japón','Corea del Sur','Australia'
);
GO
