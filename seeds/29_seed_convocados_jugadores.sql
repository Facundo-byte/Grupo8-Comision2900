/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Carga inicial de listas de convocados y planteles de jugadores para selecciones de ejemplo
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

-- Crear listas de convocados para Argentina y Brasil si no existen
INSERT INTO Mundial.ListaConvocados (id_seleccion)
SELECT s.id_seleccion
FROM Mundial.Seleccion s
JOIN Mundial.Pais p ON p.id_pais = s.id_pais
WHERE p.nombre IN ('Argentina', 'Brasil')
  AND NOT EXISTS (SELECT 1 FROM Mundial.ListaConvocados lc WHERE lc.id_seleccion = s.id_seleccion);

DECLARE @lista_arg INT = (
    SELECT lc.id_lista
    FROM Mundial.ListaConvocados lc
    JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
    JOIN Mundial.Pais p ON p.id_pais = s.id_pais
    WHERE p.nombre = 'Argentina'
);

DECLARE @lista_bra INT = (
    SELECT lc.id_lista
    FROM Mundial.ListaConvocados lc
    JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
    JOIN Mundial.Pais p ON p.id_pais = s.id_pais
    WHERE p.nombre = 'Brasil'
);

DECLARE @jugadores TABLE (
    id_lista INT,
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    dorsal INT,
    club VARCHAR(50)
);

-- 20 jugadores para Argentina
IF @lista_arg IS NOT NULL
BEGIN
    INSERT INTO @jugadores (id_lista, nombre, apellido, dorsal, club) VALUES
        (@lista_arg, 'Emiliano', 'Martinez', 23, 'Aston Villa'),
        (@lista_arg, 'Geronimo', 'Rulli', 12, 'Olympique Marsella'),
        (@lista_arg, 'Nahuel', 'Molina', 26, 'Atletico Madrid'),
        (@lista_arg, 'Cristian', 'Romero', 13, 'Tottenham'),
        (@lista_arg, 'Nicolas', 'Otamendi', 19, 'Benfica'),
        (@lista_arg, 'Lisandro', 'Martinez', 25, 'Manchester United'),
        (@lista_arg, 'Nicolas', 'Tagliafico', 3, 'Olympique Lyon'),
        (@lista_arg, 'Gonzalo', 'Montiel', 4, 'Sevilla'),
        (@lista_arg, 'German', 'Pezzella', 6, 'River Plate'),
        (@lista_arg, 'Rodrigo', 'De Paul', 7, 'Atletico Madrid'),
        (@lista_arg, 'Enzo', 'Fernandez', 24, 'Chelsea'),
        (@lista_arg, 'Alexis', 'Mac Allister', 20, 'Liverpool'),
        (@lista_arg, 'Leandro', 'Paredes', 5, 'Roma'),
        (@lista_arg, 'Giovani', 'Lo Celso', 16, 'Real Betis'),
        (@lista_arg, 'Exequiel', 'Palacios', 14, 'Bayer Leverkusen'),
        (@lista_arg, 'Lionel', 'Messi', 10, 'Inter Miami'),
        (@lista_arg, 'Julian', 'Alvarez', 9, 'Atletico Madrid'),
        (@lista_arg, 'Lautaro', 'Martinez', 22, 'Inter Milan'),
        (@lista_arg, 'Nicolas', 'Gonzalez', 15, 'Juventus'),
        (@lista_arg, 'Alejandro', 'Garnacho', 17, 'Manchester United');
END

-- 20 jugadores para Brasil
IF @lista_bra IS NOT NULL
BEGIN
    INSERT INTO @jugadores (id_lista, nombre, apellido, dorsal, club) VALUES
        (@lista_bra, 'Alisson', 'Becker', 1, 'Liverpool'),
        (@lista_bra, 'Ederson', 'Moraes', 23, 'Manchester City'),
        (@lista_bra, 'Danilo', 'Luiz', 2, 'Juventus'),
        (@lista_bra, 'Eder', 'Militao', 3, 'Real Madrid'),
        (@lista_bra, 'Marquinhos', 'Correa', 4, 'PSG'),
        (@lista_bra, 'Gabriel', 'Magalhaes', 14, 'Arsenal'),
        (@lista_bra, 'Guilherme', 'Arana', 16, 'Atletico Mineiro'),
        (@lista_bra, 'Wendell', 'Borges', 6, 'Porto'),
        (@lista_bra, 'Bremer', 'Silva', 24, 'Juventus'),
        (@lista_bra, 'Bruno', 'Guimaraes', 5, 'Newcastle'),
        (@lista_bra, 'Lucas', 'Paqueta', 8, 'West Ham'),
        (@lista_bra, 'Douglas', 'Luiz', 18, 'Juventus'),
        (@lista_bra, 'Joao', 'Gomes', 15, 'Wolverhampton'),
        (@lista_bra, 'Andreas', 'Pereira', 19, 'Fulham'),
        (@lista_bra, 'Ederson', 'Dos Santos', 25, 'Atalanta'),
        (@lista_bra, 'Vinicius', 'Junior', 7, 'Real Madrid'),
        (@lista_bra, 'Rodrygo', 'Goes', 10, 'Real Madrid'),
        (@lista_bra, 'Raphinha', 'Belloli', 11, 'Barcelona'),
        (@lista_bra, 'Endrick', 'Felipe', 9, 'Real Madrid'),
        (@lista_bra, 'Savinho', 'Moreira', 20, 'Manchester City');
END

INSERT INTO Mundial.Jugador (id_lista_convocados, nombre, apellido, dorsal, club)
SELECT j.id_lista, j.nombre, j.apellido, j.dorsal, j.club
FROM @jugadores j
WHERE NOT EXISTS (
    SELECT 1 FROM Mundial.Jugador x
    WHERE x.id_lista_convocados = j.id_lista
      AND x.dorsal = j.dorsal
);

PRINT N'Jugadores convocados cargados: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);
GO
