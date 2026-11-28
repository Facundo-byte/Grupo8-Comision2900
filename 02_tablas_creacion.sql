/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Creacion de las tablas, restricciones e indices del modelo en el esquema Mundial
*/

USE MundialDeFutbol;   
GO

IF SCHEMA_ID('Mundial') IS NULL EXEC('CREATE SCHEMA Mundial');
GO

-- borrado previo en orden inverso de dependencias
DROP TABLE IF EXISTS Mundial.Anuncios_en_Partido;
DROP TABLE IF EXISTS Mundial.Pieza_Mercado;
DROP TABLE IF EXISTS Mundial.Pieza_publicitaria;
DROP TABLE IF EXISTS Mundial.Campania;
DROP TABLE IF EXISTS Mundial.Anunciante;
DROP TABLE IF EXISTS Mundial.Franja_publicitaria;
DROP TABLE IF EXISTS Mundial.Tecnico;
DROP TABLE IF EXISTS Mundial.Arbitro_Terna;
DROP TABLE IF EXISTS Mundial.Jugador_Formacion;
DROP TABLE IF EXISTS Mundial.Formacion;
DROP TABLE IF EXISTS Mundial.Espacio_publicitario;
DROP TABLE IF EXISTS Mundial.Cuerpo_tecnico;
DROP TABLE IF EXISTS Mundial.Esquema;
DROP TABLE IF EXISTS Mundial.Expulsion;
DROP TABLE IF EXISTS Mundial.Tarjeta;
DROP TABLE IF EXISTS Mundial.Gol;
DROP TABLE IF EXISTS Mundial.Sustitucion;
DROP TABLE IF EXISTS Mundial.Terna_Arbitral;
DROP TABLE IF EXISTS Mundial.Partido;
DROP TABLE IF EXISTS Mundial.Arbitro;
DROP TABLE IF EXISTS Mundial.Idioma;
DROP TABLE IF EXISTS Mundial.Sede;
DROP TABLE IF EXISTS Mundial.Confederacion;
DROP TABLE IF EXISTS Mundial.AltasBajasConvocados;
DROP TABLE IF EXISTS Mundial.Jugador;
DROP TABLE IF EXISTS Mundial.Posicion;
DROP TABLE IF EXISTS Mundial.ListaConvocados;
DROP TABLE IF EXISTS Mundial.Seleccion;
DROP TABLE IF EXISTS Mundial.Pais;
GO

-- Integrante 1
CREATE TABLE Mundial.Pais
(
    id_pais INT IDENTITY(1,1) NOT NULL,
    nombre  VARCHAR(60)       NOT NULL,
    huso_horario VARCHAR(20),
    pbi_per_capita DECIMAL(18,2) NULL,
    hora_inicio_prime TIME(0) NOT NULL CONSTRAINT DF_Pais_inicio_prime DEFAULT ('19:00'),
    hora_fin_prime TIME(0) NOT NULL CONSTRAINT DF_Pais_fin_prime DEFAULT ('23:00'),
    CONSTRAINT CK_Pais_pbi CHECK (pbi_per_capita >= 0),
    CONSTRAINT CK_Pais_prime CHECK (hora_inicio_prime <> hora_fin_prime),
    CONSTRAINT PK_Pais PRIMARY KEY (id_pais),
    CONSTRAINT UQ_Pais_nombre UNIQUE (nombre)
);
GO


CREATE TABLE Mundial.Seleccion
(
    id_seleccion  INT IDENTITY(1,1) NOT NULL,
    id_pais       INT         NOT NULL,
    confederacion VARCHAR(30) NULL,
    grupo         CHAR(1)     NULL,
    CONSTRAINT PK_Seleccion PRIMARY KEY (id_seleccion),
    CONSTRAINT UQ_Seleccion_pais UNIQUE (id_pais),
    CONSTRAINT FK_Seleccion_Pais FOREIGN KEY (id_pais) REFERENCES Mundial.Pais (id_pais)
);
GO



CREATE TABLE Mundial.ListaConvocados
(
    id_lista     INT IDENTITY(1,1) NOT NULL,
    id_seleccion INT NOT NULL,
    CONSTRAINT PK_ListaConvocados PRIMARY KEY (id_lista),
    CONSTRAINT UQ_ListaConvocados_seleccion UNIQUE (id_seleccion),
    CONSTRAINT FK_ListaConvocados_Seleccion FOREIGN KEY (id_seleccion) REFERENCES Mundial.Seleccion (id_seleccion)
);
GO

CREATE TABLE Mundial.Jugador
(
    id_jugador           INT IDENTITY(1,1) NOT NULL,
    id_lista_convocados  INT         NOT NULL,
    nombre               VARCHAR(50) NOT NULL,
    apellido             VARCHAR(50) NOT NULL,
    dorsal               INT         NULL,
    club                 VARCHAR(50) NULL,
    CONSTRAINT PK_Jugador PRIMARY KEY (id_jugador),
    CONSTRAINT FK_Jugador_ListaConvocados FOREIGN KEY (id_lista_convocados) REFERENCES Mundial.ListaConvocados (id_lista)
);
GO

CREATE TABLE Mundial.Posicion (
    id_posicion INT IDENTITY(1,1) NOT NULL,
    nombre      VARCHAR(30)       NOT NULL,
    abreviatura VARCHAR(5)        NOT NULL,
    CONSTRAINT PK_Posicion     PRIMARY KEY (id_posicion),
    CONSTRAINT UQ_Posicion_nom UNIQUE (nombre),
    CONSTRAINT UQ_Posicion_abr UNIQUE (abreviatura)
);
GO

ALTER TABLE Mundial.Jugador
    ADD id_posicion INT NULL,
        CONSTRAINT FK_Jugador_Posicion FOREIGN KEY (id_posicion) REFERENCES Mundial.Posicion(id_posicion);
GO

USE MundialDeFutbol;
GO

/* ============================================================
   ASIGNACIÓN DE POSICIÓN A LOS 128 JUGADORES
   (posición real según su rol en la cancha)
   ============================================================ */

-- 1) Tabla con (país, apellido, nombre de posición)
DECLARE @PosicionesJugadores TABLE (
    fila         INT IDENTITY(1,1) PRIMARY KEY,
    nombrePais   VARCHAR(30),
    apellido     VARCHAR(50),
    posicion     VARCHAR(30)
);

INSERT INTO @PosicionesJugadores (nombrePais, apellido, posicion) VALUES
-- GRUPO A
('Japon',         'Gonda',         'Arquero'),
('Japon',         'Kubo',          'Mediocampista ofensivo'),
('Japon',         'Mitoma',        'Extremo izquierdo'),
('Japon',         'Endo',          'Mediocampista defensivo'),

-- GRUPO B

('USA','Turner',        'Arquero'),
('USA','Pulisic',       'Extremo izquierdo'),
('USA','McKennie',      'Mediocampista central'),
('USA','Adams',         'Mediocampista defensivo'),

('Costa de Marfil',       'Onana',         'Arquero'),
('Costa de Marfil',       'Aboubakar',     'Delantero centro'),
('Costa de Marfil',       'Toko Ekambi',   'Extremo izquierdo'),
('Costa de Marfil',       'Zambo Anguissa','Mediocampista defensivo'),
-- GRUPO G
('Paises Bajos',  'Verbruggen',    'Arquero'),
('Paises Bajos',  'van Dijk',      'Defensor central'),
('Paises Bajos',  'de Jong',       'Mediocampista central'),
('Paises Bajos',  'Gakpo',         'Extremo izquierdo'),
('Noruega',     'Schmeichel',    'Arquero'),
('Noruega',     'Eriksen',       'Mediocampista ofensivo'),
('Noruega',     'Højlund',       'Delantero centro'),
('Noruega',     'Højbjerg',      'Mediocampista defensivo');

-- 2) Recorro con WHILE
DECLARE @fila        INT = 0;
DECLARE @totalFilas  INT;
DECLARE @nombrePais  VARCHAR(30);
DECLARE @apellido    VARCHAR(50);
DECLARE @posicion    VARCHAR(30);
DECLARE @idLista     INT;
DECLARE @idJugador   INT;
DECLARE @idPosicion  INT;

SELECT @totalFilas = MAX(fila) FROM @PosicionesJugadores;

WHILE @fila < @totalFilas
BEGIN
    SET @fila = @fila + 1;

    SELECT
        @nombrePais = nombrePais,
        @apellido   = apellido,
        @posicion   = posicion
    FROM @PosicionesJugadores
    WHERE fila = @fila;

    -- Resuelvo la lista de convocados del país
    SELECT @idLista = lc.id_lista
    FROM Mundial.ListaConvocados lc
    INNER JOIN Mundial.Seleccion s ON s.id_seleccion = lc.id_seleccion
    INNER JOIN Mundial.Pais p      ON p.id_pais       = s.id_pais
    WHERE p.nombre = @nombrePais;

    IF @idLista IS NULL
    BEGIN
        PRINT '  SKIP: no hay lista para ' + @nombrePais;
        CONTINUE;
    END

    -- Resuelvo el jugador por apellido dentro de la lista
    SELECT @idJugador = j.id_jugador
    FROM Mundial.Jugador j
    WHERE j.id_lista_convocados = @idLista
      AND j.apellido = @apellido;

    IF @idJugador IS NULL
    BEGIN
        PRINT '  SKIP: jugador ' + @apellido + ' no encontrado en ' + @nombrePais;
        CONTINUE;
    END

    -- Resuelvo la posición por nombre
    SELECT @idPosicion = id_posicion
    FROM Mundial.Posicion
    WHERE nombre = @posicion;

    IF @idPosicion IS NULL
    BEGIN
        PRINT '  SKIP: posición ' + @posicion + ' no encontrada';
        CONTINUE;
    END

    -- UPDATE del jugador
    UPDATE Mundial.Jugador
    SET id_posicion = @idPosicion
    WHERE id_jugador = @idJugador;

    PRINT '--- ' + @nombrePais + ' | ' + @apellido + ' -> ' + @posicion + ' (id=' + CONVERT(VARCHAR(3), @idPosicion) + ') ---';
END
GO

CREATE TABLE Mundial.AltasBajasConvocados
(
    id_alta_baja        INT IDENTITY(1,1) NOT NULL,
    id_lista_convocados INT         NOT NULL,
    id_seleccion        INT         NOT NULL,
    id_jugador          INT         NOT NULL,
    tipo                CHAR(4)     NOT NULL,
    motivo              VARCHAR(100) NULL,
    fecha_modificacion  DATE        NULL,
    CONSTRAINT PK_AltasBajasConvocados PRIMARY KEY (id_alta_baja),
    CONSTRAINT CK_AltasBajas_tipo CHECK (tipo IN ('ALTA','BAJA')),
    CONSTRAINT FK_AltaBaja_Jugador FOREIGN KEY (id_jugador) REFERENCES Mundial.Jugador (id_jugador),
    CONSTRAINT FK_AltaBaja_ListaConvocados FOREIGN KEY (id_lista_convocados) REFERENCES Mundial.ListaConvocados (id_lista),
    CONSTRAINT FK_AltaBaja_Seleccion FOREIGN KEY (id_seleccion) REFERENCES Mundial.Seleccion (id_seleccion)
);
GO
	
-- Integrante 3

CREATE TABLE Mundial.Confederacion
(
    id_confederacion INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(60) UNIQUE NOT NULL,
    sigla VARCHAR(10) UNIQUE NOT NULL
);
GO

select * from Mundial.Confederacion
go

CREATE TABLE Mundial.Sede
(
    id_sede INT IDENTITY(1,1) PRIMARY KEY,
    nombre_estadio VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    id_pais INT NOT NULL,
    capacidad INT NOT NULL,
    huso_horario VARCHAR(10) NOT NULL,
    latitud DECIMAL(9,6) NULL,
    longitud DECIMAL(9,6) NULL,
    CONSTRAINT UQ_Sede_estadio_ciudad_pais UNIQUE (nombre_estadio, ciudad, id_pais),
    CONSTRAINT FK_Sede_Pais FOREIGN KEY (id_pais) REFERENCES Mundial.Pais (id_pais),
    CONSTRAINT CK_Sede_capacidad CHECK (capacidad > 0)
);
GO


CREATE TABLE Mundial.Idioma
(
    id_idioma INT IDENTITY(1,1) PRIMARY KEY,
    idioma VARCHAR(50) NOT NULL
);
GO

CREATE TABLE Mundial.Arbitro
(
    id_arbitro INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    id_pais INT NOT NULL,
    id_confederacion INT NOT NULL,
    id_idioma INT NOT NULL,
    categoria VARCHAR(20) NOT NULL,
    habilitado BIT NOT NULL DEFAULT (1),
    CONSTRAINT UQ_Arbitro_datos UNIQUE (nombre, apellido, fecha_nacimiento, id_pais),
    CONSTRAINT FK_Arbitro_Pais FOREIGN KEY (id_pais) REFERENCES Mundial.Pais (id_pais),
    CONSTRAINT FK_Arbitro_Confederacion FOREIGN KEY (id_confederacion) REFERENCES Mundial.Confederacion (id_confederacion),
    CONSTRAINT FK_Arbitro_Idioma FOREIGN KEY (id_idioma) REFERENCES Mundial.Idioma (id_idioma),
    CONSTRAINT CK_Arbitro_categoria CHECK (categoria IN ('FIFA', 'CONFEDERACION'))
);
GO

select * from Mundial.Arbitro
go

CREATE TABLE Mundial.Terna_Arbitral
(
    id_terna INT IDENTITY(1,1) PRIMARY KEY,
    id_partido INT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT ('Activa'),
    motivo_descarte VARCHAR(300) NULL,
    fecha_designacion DATETIME2(0) NOT NULL DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Terna_Arbitral_estado CHECK (estado IN ('Activa', 'Descartada')),
    CONSTRAINT CK_Terna_Arbitral_motivo CHECK (
        (estado = 'Descartada' AND LEN(LTRIM(RTRIM(motivo_descarte))) > 0)
        OR (estado = 'Activa' AND motivo_descarte IS NULL)
    )
);
GO

CREATE UNIQUE INDEX UX_Terna_Arbitral_partido_activa
    ON Mundial.Terna_Arbitral (id_partido)
    WHERE estado = 'Activa';
GO

select * from Mundial.Terna_Arbitral
go

CREATE TABLE Mundial.Arbitro_Terna
(
    id_terna INT NOT NULL,
    id_arbitro INT NOT NULL,
    rol VARCHAR(30) NOT NULL,
    CONSTRAINT PK_Arbitro_Terna
        PRIMARY KEY (id_terna, id_arbitro),
    CONSTRAINT FK_Arbitro_Terna_Terna
        FOREIGN KEY (id_terna)
        REFERENCES Mundial.Terna_Arbitral (id_terna),
        CONSTRAINT FK_Arbitro_Terna_Arbitro
        FOREIGN KEY (id_arbitro)
        REFERENCES Mundial.Arbitro (id_arbitro),
        CONSTRAINT CK_Arbitro_Terna_Rol
        CHECK (rol IN (
            'Principal',
            'Asistente 1',
            'Asistente 2',
            'Cuarto arbitro',
            'VAR'
        ))
);
GO

-- Integrante 2
CREATE TABLE Mundial.Partido(
	id_partido INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	id_sede INT NOT NULL, 
	id_seleccion_local INT NOT NULL, 
	id_seleccion_visitante INT NOT NULL, 
	fecha_hora_local DATETIME NOT NULL,
	fecha_hora_utc DATETIME NOT NULL,
	fase VARCHAR(20) NOT NULL
    DEFAULT 'fasedegrupos'
    CHECK (fase IN (
        'fasedegrupos',
        'cuartos de final',
		'octavos de final',
		'tercer puesto',
        'semifinal',
        'final'
    )),

	CONSTRAINT Fk_Partido_Sede FOREIGN KEY(id_sede) REFERENCES Mundial.Sede(id_sede),
	CONSTRAINT Fk_Partido_Seleccion_Local FOREIGN KEY(id_seleccion_local) REFERENCES Mundial.Seleccion(id_seleccion),
	CONSTRAINT Fk_Partido_Seleccion_Visitante FOREIGN KEY (id_seleccion_visitante) REFERENCES Mundial.Seleccion(id_seleccion),
	CONSTRAINT CK_Partido_Selecciones CHECK (id_seleccion_local <> id_seleccion_visitante)
);
go

DECLARE @id_jugador_autor INT, @id_partido INT;
SET @id_jugador_autor = 2;
SET @id_partido = 1;
select apellido from Mundial.Jugador j
    join Mundial.ListaConvocados lc on j.id_lista_convocados = lc.id_lista
    join Mundial.Seleccion s on s.id_seleccion = lc.id_seleccion
    join Mundial.Partido p on p.id_partido = @id_partido
    AND s.id_seleccion IN (p.id_seleccion_local,p.id_seleccion_visitante)
    WHERE j.id_jugador = @id_jugador_autor
go

CREATE TABLE Mundial.Gol(
	id_gol INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	id_partido INT NOT NULL, 
	id_jugador_autor INT NOT NULL, 
	id_jugador_asistencia INT NULL,
	minuto INT NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK(
    tipo IN(
        'Jugada',
        'Penal',
        'Tiro libre',
        'En contra',
        'Cabezazo'
    )),
	periodo VARCHAR(20) NOT NULL
    CHECK (periodo IN (
        'Primer tiempo',
        'Segundo tiempo',
		'Primer suplementario',
		'Segundo suplementario'
    )),

	CONSTRAINT Fk_Gol_Partido FOREIGN KEY(id_partido) REFERENCES Mundial.Partido(id_partido),
	CONSTRAINT Fk_Gol_Jugador_Autor FOREIGN KEY(id_jugador_autor) REFERENCES Mundial.Jugador(id_jugador),
	CONSTRAINT Fk_Gol_Jugador_Asistencia FOREIGN KEY(id_jugador_asistencia) REFERENCES Mundial.Jugador(id_jugador),

	CONSTRAINT CK_Gol_Minuto CHECK (minuto >= 0)
);

select * from Mundial.Gol
go

CREATE TABLE Mundial.Tarjeta(
	id_tarjeta INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	id_partido INT NOT NULL, 
	id_jugador INT NOT NULL, 
	minuto INT NOT NULL,
	motivo VARCHAR(100),
	color VARCHAR(20) NOT NULL
    CHECK (color IN (
        'Roja',
        'Amarilla'
    )),

	CONSTRAINT Fk_Tarjeta_Jugador FOREIGN KEY(id_jugador) REFERENCES Mundial.Jugador(id_jugador),
	CONSTRAINT Fk_Tarjeta_Partido FOREIGN KEY(id_partido) REFERENCES Mundial.Partido(id_partido),

	CONSTRAINT CK_Tarjeta_Minuto CHECK (minuto >= 0)
);

CREATE TABLE Mundial.Expulsion(
	id_expulsion INT IDENTITY(1,1) PRIMARY KEY,
	id_tarjeta INT NOT NULL UNIQUE, 
	tipoexpulsion VARCHAR(20) NOT NULL
    CHECK (tipoexpulsion IN (
        'Doble amarilla',
        'Roja'
    )),

	CONSTRAINT Fk_Expulsion_Tarjeta FOREIGN KEY(id_tarjeta) REFERENCES Mundial.Tarjeta(id_tarjeta)
);

CREATE TABLE Mundial.Sustitucion(
	id_sustitucion INT IDENTITY(1,1) PRIMARY KEY,
	id_partido INT NOT NULL,
	id_seleccion INT NOT NULL,
	id_jugador_sale INT NOT NULL,
	id_jugador_entra INT NOT NULL,  
	motivo VARCHAR(20) NOT NULL
	CHECK (motivo IN (
        'Lesion',
        'Tactica',
		'Cansancio'
    )),
	minuto INT NOT NULL,

	CONSTRAINT Fk_Sustitucion_Partido FOREIGN KEY(id_partido) REFERENCES Mundial.Partido(id_partido),
	CONSTRAINT Fk_Sustitucion_Seleccion FOREIGN KEY(id_seleccion) REFERENCES Mundial.Seleccion(id_seleccion),
	CONSTRAINT Fk_Sustitucion_Jugador_Entra FOREIGN KEY(id_jugador_entra) REFERENCES Mundial.Jugador(id_jugador),
	CONSTRAINT Fk_Sustitucion_Jugador_Sale FOREIGN KEY(id_jugador_sale) REFERENCES Mundial.Jugador(id_jugador),

	CONSTRAINT CK_Sustitucion_Jugadores CHECK (id_jugador_sale <> id_jugador_entra),
    CONSTRAINT CK_Sustitucion_Minuto CHECK (minuto >= 0)
);
GO

-- Integrante 4
CREATE TABLE Mundial.Esquema (
    id_esquema INT IDENTITY(1,1) NOT NULL,
    lineas     VARCHAR(15)       NOT NULL,
    CONSTRAINT PK_Esquema        PRIMARY KEY (id_esquema),
    CONSTRAINT UQ_Esquema_lineas UNIQUE (lineas),
    CONSTRAINT CK_Esquema_lineas CHECK (lineas LIKE '%-%' AND lineas NOT LIKE '%[^0-9-]%')
);
GO


CREATE TABLE Mundial.Formacion (
    id_formacion INT IDENTITY(1,1) NOT NULL,
    id_partido   INT NOT NULL,
    id_seleccion INT NOT NULL,
    id_esquema   INT NOT NULL,
    CONSTRAINT PK_Formacion          PRIMARY KEY (id_formacion),
    CONSTRAINT UQ_Formacion_part_sel UNIQUE (id_partido, id_seleccion),
    CONSTRAINT FK_Formacion_Partido   FOREIGN KEY (id_partido)   REFERENCES Mundial.Partido(id_partido),
    CONSTRAINT FK_Formacion_Seleccion FOREIGN KEY (id_seleccion) REFERENCES Mundial.Seleccion(id_seleccion),
    CONSTRAINT FK_Formacion_Esquema   FOREIGN KEY (id_esquema)   REFERENCES Mundial.Esquema(id_esquema)
);
GO

CREATE TABLE Mundial.Jugador_Formacion (
    id_formacion INT NOT NULL,
    id_jugador   INT NOT NULL,
    id_posicion  INT NOT NULL,
    es_titular   BIT NOT NULL CONSTRAINT DF_JugForm_titular DEFAULT (1),
    CONSTRAINT PK_Jugador_Formacion PRIMARY KEY (id_formacion, id_jugador),
    CONSTRAINT FK_JugForm_Formacion FOREIGN KEY (id_formacion) REFERENCES Mundial.Formacion(id_formacion),
    CONSTRAINT FK_JugForm_Jugador   FOREIGN KEY (id_jugador)   REFERENCES Mundial.Jugador(id_jugador),
    CONSTRAINT FK_JugForm_Posicion  FOREIGN KEY (id_posicion)  REFERENCES Mundial.Posicion(id_posicion)
);
GO


CREATE TABLE Mundial.Cuerpo_tecnico (
    id_cuerpo_tecnico INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    id_seleccion      INT UNIQUE NOT NULL,
    CONSTRAINT FK_CuerpoTec_Seleccion FOREIGN KEY (id_seleccion) REFERENCES Mundial.Seleccion(id_seleccion)
);
GO


CREATE TABLE Mundial.Tecnico (
    id_tecnico INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    id_cuerpo_tecnico      INT NOT NULL,
    nombre            VARCHAR(50) NOT NULL,
    apellido          VARCHAR(50) NOT NULL,
    rol               VARCHAR(25) NOT NULL,
    CONSTRAINT FK_Tecnico_Cuerpotecnico FOREIGN KEY (id_cuerpo_tecnico) REFERENCES Mundial.Cuerpo_tecnico(id_cuerpo_tecnico),
    CONSTRAINT CK_Cuerpo_tecnico_rol CHECK (rol IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')))
GO

CREATE TABLE Mundial.Espacio_publicitario (
    id_espacio      INT IDENTITY(1,1) NOT NULL,
    id_sede         INT          NOT NULL,
    numero_espacio  TINYINT      NOT NULL,
    descripcion     VARCHAR(100) NULL,
    CONSTRAINT PK_Espacio_publicitario PRIMARY KEY (id_espacio),
    CONSTRAINT UQ_Espacio_sede_numero  UNIQUE (id_sede, numero_espacio),
    CONSTRAINT CK_Espacio_numero       CHECK (numero_espacio BETWEEN 1 AND 4),
    CONSTRAINT UQ_Espacio_sede_id UNIQUE (id_sede, id_espacio),
    CONSTRAINT FK_Espacio_Sede FOREIGN KEY (id_sede) REFERENCES Mundial.Sede(id_sede) ON DELETE CASCADE
);
GO

-- Integrante 3 (FK cruzada)

ALTER TABLE Mundial.Terna_Arbitral
ADD CONSTRAINT FK_Terna_Arbitral_Partido
FOREIGN KEY (id_partido)
REFERENCES Mundial.Partido (id_partido);
GO

-- Publicidad: los cuatro paneles se crean junto con la sede.
CREATE OR ALTER TRIGGER Mundial.TR_Sede_CrearEspacios
ON Mundial.Sede
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Mundial.Espacio_publicitario (id_sede, numero_espacio)
    SELECT s.id_sede, n.numero
    FROM inserted s
    CROSS JOIN (VALUES (1), (2), (3), (4)) n(numero);
END;
GO

CREATE TABLE Mundial.Anunciante (
    id_anunciante INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_pais_origen INT NOT NULL,
    CONSTRAINT FK_Anunciante_Pais FOREIGN KEY (id_pais_origen) REFERENCES Mundial.Pais(id_pais)
);
GO

CREATE TABLE Mundial.Campania (
    id_campania INT IDENTITY(1,1) PRIMARY KEY,
    id_anunciante INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    fecha_desde DATETIME2(0) NOT NULL,
    fecha_hasta DATETIME2(0) NOT NULL,
    CONSTRAINT CK_Campania_fechas CHECK (fecha_desde <= fecha_hasta),
    CONSTRAINT FK_Campania_Anunciante FOREIGN KEY (id_anunciante) REFERENCES Mundial.Anunciante(id_anunciante)
);
GO

CREATE TABLE Mundial.Pieza_publicitaria (
    id_pieza INT IDENTITY(1,1) PRIMARY KEY,
    id_campania INT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    id_idioma INT NOT NULL,
    CONSTRAINT FK_Pieza_Campania FOREIGN KEY (id_campania) REFERENCES Mundial.Campania(id_campania),
    CONSTRAINT FK_Pieza_Idioma FOREIGN KEY (id_idioma) REFERENCES Mundial.Idioma(id_idioma)
);
GO

CREATE TABLE Mundial.Pieza_Mercado (
    id_pieza INT NOT NULL,
    id_pais INT NOT NULL,
    CONSTRAINT PK_Pieza_Mercado PRIMARY KEY (id_pieza, id_pais),
    CONSTRAINT FK_PiezaMercado_Pieza FOREIGN KEY (id_pieza) REFERENCES Mundial.Pieza_publicitaria(id_pieza),
    CONSTRAINT FK_PiezaMercado_Pais FOREIGN KEY (id_pais) REFERENCES Mundial.Pais(id_pais)
);
GO

CREATE TABLE Mundial.Franja_publicitaria (
    id_franja INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    tarifa_por_espacio DECIMAL(18,2) NOT NULL,
    moneda VARCHAR(3) NOT NULL,
    CONSTRAINT CK_Franja_tarifa CHECK (tarifa_por_espacio >= 0),
    CONSTRAINT CK_Franja_moneda CHECK (moneda COLLATE Latin1_General_100_BIN2 LIKE '[A-Z][A-Z][A-Z]')
);
GO

-- La sede compartida por las dos FK impide exhibir en un panel de otro estadio.
ALTER TABLE Mundial.Partido ADD CONSTRAINT UQ_Partido_sede_id UNIQUE (id_sede, id_partido);
GO

CREATE TABLE Mundial.Anuncios_en_Partido (
    id_partido INT NOT NULL,
    id_espacio INT NOT NULL,
    id_franja INT NOT NULL,
    id_pieza_publicitaria INT NOT NULL,
    id_sede INT NOT NULL,
    importe_aplicado DECIMAL(18,2) NOT NULL,
    moneda_aplicada VARCHAR(3) NOT NULL,
    CONSTRAINT PK_Anuncios_en_Partido PRIMARY KEY (id_partido, id_espacio, id_franja),
    CONSTRAINT FK_Anuncios_Partido FOREIGN KEY (id_sede, id_partido) REFERENCES Mundial.Partido(id_sede, id_partido),
    CONSTRAINT FK_Anuncios_Espacio FOREIGN KEY (id_sede, id_espacio) REFERENCES Mundial.Espacio_publicitario(id_sede, id_espacio),
    CONSTRAINT FK_Anuncios_Franja FOREIGN KEY (id_franja) REFERENCES Mundial.Franja_publicitaria(id_franja),
    CONSTRAINT FK_Anuncios_Pieza FOREIGN KEY (id_pieza_publicitaria) REFERENCES Mundial.Pieza_publicitaria(id_pieza),
    CONSTRAINT CK_Anuncios_importe CHECK (importe_aplicado >= 0),
    CONSTRAINT CK_Anuncios_moneda CHECK (moneda_aplicada COLLATE Latin1_General_100_BIN2 LIKE '[A-Z][A-Z][A-Z]')
);
GO
