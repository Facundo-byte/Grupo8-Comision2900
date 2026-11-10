USE MundialDeFutbol;   
GO

-- CREATE SCHEMA exige ir solo en su lote, por eso se usa EXEC (unico SQL dinamico).
IF SCHEMA_ID('Mundial') IS NULL EXEC('CREATE SCHEMA Mundial');
GO

-- Borrado previo (orden inverso a las dependencias) para poder re-ejecutar el script.
DROP TABLE IF EXISTS Mundial.Jugador_Formacion;
DROP TABLE IF EXISTS Mundial.Formacion;
DROP TABLE IF EXISTS Mundial.Espacio_publicitario;
DROP TABLE IF EXISTS Mundial.Cuerpo_tecnico;
DROP TABLE IF EXISTS Mundial.Posicion;
DROP TABLE IF EXISTS Mundial.Esquema;
GO

-- Integrante 2 

CREATE TABLE Mundial.Partido(
	id_partido INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	id_sede INT NOT NULL, 
	id_seleccion_local INT NOT NULL, 
	id_seleccion_visitante INT NOT NULL, 
	fecha_hora_local DATETIME NOT NULL,
	fecha_hora_utc DATETIME NOT NULL,
	goles_local INT,
	goles_visitante INT,
	asistencia INT,
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

	CONSTRAINT CK_Partido_Selecciones CHECK (id_seleccion_local <> id_seleccion_visitante),
	CONSTRAINT CK_Partido_Goles CHECK (goles_local >= 0 AND goles_visitante >= 0),
	CONSTRAINT CK_Partido_Asistencia CHECK (asistencia >= 0)
)

CREATE TABLE Mundial.Gol(
	id_gol INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	id_partido INT NOT NULL, 
	id_jugador_autor INT NOT NULL, 
	id_jugador_asistencia INT NULL,
	minuto INT NOT NULL,
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
)

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
)

-- Integrante 4
CREATE TABLE Mundial.Esquema (
    id_esquema INT IDENTITY(1,1) NOT NULL,
    lineas     VARCHAR(15)       NOT NULL,          -- ej. '4-3-3'
    CONSTRAINT PK_Esquema        PRIMARY KEY (id_esquema),
    CONSTRAINT UQ_Esquema_lineas UNIQUE (lineas),
    CONSTRAINT CK_Esquema_lineas CHECK (lineas LIKE '%-%' AND lineas NOT LIKE '%[^0-9-]%')
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

CREATE TABLE Mundial.Formacion (
    id_formacion INT IDENTITY(1,1) NOT NULL,
    id_partido   INT NOT NULL,
    id_seleccion INT NOT NULL,
    id_esquema   INT NOT NULL,
    CONSTRAINT PK_Formacion          PRIMARY KEY (id_formacion),
    CONSTRAINT UQ_Formacion_part_sel UNIQUE (id_partido, id_seleccion),
    CONSTRAINT FK_Formacion_Partido   FOREIGN KEY (id_partido)   REFERENCES Mundial.Partido(id_partido),
    CONSTRAINT FK_Formacion_Seleccion FOREIGN KEY (id_seleccion) REFERENCES Mundial.Seleccion(id),
    CONSTRAINT FK_Formacion_Esquema   FOREIGN KEY (id_esquema)   REFERENCES Mundial.Esquema(id_esquema)
);
GO

-- es_titular: 1 = titular, 0 = banco de suplentes
CREATE TABLE Mundial.Jugador_Formacion (
    id_formacion INT NOT NULL,
    id_jugador   INT NOT NULL,
    id_posicion  INT NOT NULL,
    es_titular   BIT NOT NULL CONSTRAINT DF_JugForm_titular DEFAULT (1),
    CONSTRAINT PK_Jugador_Formacion PRIMARY KEY (id_formacion, id_jugador),
    CONSTRAINT FK_JugForm_Formacion FOREIGN KEY (id_formacion) REFERENCES Mundial.Formacion(id_formacion),
    CONSTRAINT FK_JugForm_Jugador   FOREIGN KEY (id_jugador)   REFERENCES Mundial.Jugador(id),
    CONSTRAINT FK_JugForm_Posicion  FOREIGN KEY (id_posicion)  REFERENCES Mundial.Posicion(id_posicion)
);
GO

CREATE TABLE Mundial.Cuerpo_tecnico (
    id_cuerpo_tecnico INT IDENTITY(1,1) NOT NULL,
    id_seleccion      INT         NOT NULL,
    nombre            VARCHAR(50) NOT NULL,
    apellido          VARCHAR(50) NOT NULL,
    rol               VARCHAR(25) NOT NULL,
    CONSTRAINT PK_Cuerpo_tecnico     PRIMARY KEY (id_cuerpo_tecnico),
    CONSTRAINT UQ_Cuerpo_tecnico_per UNIQUE (id_seleccion, nombre, apellido),
    CONSTRAINT CK_Cuerpo_tecnico_rol CHECK (rol IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')),
    CONSTRAINT FK_CuerpoTec_Seleccion FOREIGN KEY (id_seleccion) REFERENCES Mundial.Seleccion(id)
);
GO

-- Cada sede admite exactamente 4 espacios publicitarios.
CREATE TABLE Mundial.Espacio_publicitario (
    id_espacio      INT IDENTITY(1,1) NOT NULL,
    id_sede         INT          NOT NULL,
    numero_espacio  TINYINT      NOT NULL,
    descripcion     VARCHAR(100) NULL,
    id_pais_interes INT          NULL,
    CONSTRAINT PK_Espacio_publicitario PRIMARY KEY (id_espacio),
    CONSTRAINT UQ_Espacio_sede_numero  UNIQUE (id_sede, numero_espacio),
    CONSTRAINT CK_Espacio_numero       CHECK (numero_espacio BETWEEN 1 AND 4),
    CONSTRAINT FK_Espacio_Sede         FOREIGN KEY (id_sede)         REFERENCES Mundial.Sede(id),
    CONSTRAINT FK_Espacio_Pais         FOREIGN KEY (id_pais_interes) REFERENCES Mundial.Pais(id_pais)
);
GO

-- Tablas provisorias

CREATE TABLE Mundial.