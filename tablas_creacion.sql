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


/* =============================================================
   Integrante 3: árbitros e infraestructura
   Tablas: Confederacion, Sede, Arbitro, Idioma y Terna_Arbitral.

   Se ubican antes de las tablas del Integrante 2 porque
   Mundial.Partido referencia a Mundial.Sede.
   Las FK hacia Mundial.Pais y Mundial.Partido se agregan al final
   de este mismo script.
   ============================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
/* Opciones ANSI requeridas por el índice filtrado de Terna_Arbitral.
   Todo INSERT/UPDATE sobre esa tabla necesita estas opciones activas. */
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

/* -------------------------------------------------------------
   1. Confederacion
   Catálogo de confederaciones continentales (CONMEBOL, UEFA, etc.).
   ------------------------------------------------------------- */
IF OBJECT_ID(N'Mundial.Confederacion', N'U') IS NULL
BEGIN
    CREATE TABLE Mundial.Confederacion
    (
        id_confederacion INT IDENTITY(1,1) NOT NULL,
        nombre            NVARCHAR(60)     NOT NULL,
        sigla             VARCHAR(10)      NOT NULL,
        CONSTRAINT PK_Confederacion PRIMARY KEY (id_confederacion),
        CONSTRAINT UQ_Confederacion_nombre UNIQUE (nombre),
        CONSTRAINT UQ_Confederacion_sigla  UNIQUE (sigla),
        CONSTRAINT CK_Confederacion_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
        CONSTRAINT CK_Confederacion_sigla  CHECK (LEN(sigla) BETWEEN 2 AND 10 AND sigla = UPPER(sigla))
    );
    PRINT N'Tabla Mundial.Confederacion creada.';
END
ELSE
    PRINT N'Mundial.Confederacion ya existe: no se modifica.';
GO

/* -------------------------------------------------------------
   2. Sede
   Estadio, ciudad, país, capacidad, huso horario y geolocalización.
   id_pais queda sin FK hasta la sección final de este script.
   ------------------------------------------------------------- */
IF OBJECT_ID(N'Mundial.Sede', N'U') IS NULL
BEGIN
    CREATE TABLE Mundial.Sede
    (
        id_sede        INT IDENTITY(1,1) NOT NULL,
        nombre_estadio NVARCHAR(100)     NOT NULL,
        ciudad         NVARCHAR(100)     NOT NULL,
        id_pais        INT               NOT NULL,
        capacidad      INT               NOT NULL,
        huso_horario   VARCHAR(10)       NOT NULL,
        latitud        DECIMAL(9,6)      NULL,
        longitud       DECIMAL(9,6)      NULL,
        CONSTRAINT PK_Sede PRIMARY KEY (id_sede),
        CONSTRAINT UQ_Sede_estadio_ciudad_pais UNIQUE (nombre_estadio, ciudad, id_pais),
        CONSTRAINT CK_Sede_nombre_estadio CHECK (LEN(LTRIM(RTRIM(nombre_estadio))) > 0),
        CONSTRAINT CK_Sede_ciudad        CHECK (LEN(LTRIM(RTRIM(ciudad))) > 0),
        CONSTRAINT CK_Sede_capacidad     CHECK (capacidad > 0),
        CONSTRAINT CK_Sede_huso_horario  CHECK (
            huso_horario LIKE 'UTC[+-][0-1][0-9]:[0-5][0-9]'
            AND SUBSTRING(huso_horario, 5, 2) <= '14'
        ),
        CONSTRAINT CK_Sede_latitud       CHECK (latitud IS NULL OR latitud BETWEEN -90 AND 90),
        CONSTRAINT CK_Sede_longitud      CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180),
        CONSTRAINT CK_Sede_geolocalizacion CHECK (
            (latitud IS NULL AND longitud IS NULL)
            OR (latitud IS NOT NULL AND longitud IS NOT NULL)
        )
    );
    PRINT N'Tabla Mundial.Sede creada.';
END
ELSE
    PRINT N'Mundial.Sede ya existe: no se modifica.';
GO

/* -------------------------------------------------------------
   3. Arbitro
   Árbitro habilitado: datos personales, país de origen,
   confederación a la que pertenece y categoría.
   id_pais queda sin FK hasta la sección final de este script.
   ------------------------------------------------------------- */
IF OBJECT_ID(N'Mundial.Arbitro', N'U') IS NULL
BEGIN
    CREATE TABLE Mundial.Arbitro
    (
        id_arbitro       INT IDENTITY(1,1) NOT NULL,
        nombre           NVARCHAR(50)      NOT NULL,
        apellido         NVARCHAR(50)      NOT NULL,
        fecha_nacimiento DATE              NOT NULL,
        id_pais          INT               NOT NULL,
        id_confederacion INT               NOT NULL,
        categoria        NVARCHAR(20)      NOT NULL,
        habilitado       BIT               NOT NULL
            CONSTRAINT DF_Arbitro_habilitado DEFAULT (1),
        CONSTRAINT PK_Arbitro PRIMARY KEY (id_arbitro),
        CONSTRAINT FK_Arbitro_confederacion FOREIGN KEY (id_confederacion)
            REFERENCES Mundial.Confederacion (id_confederacion),
        CONSTRAINT UQ_Arbitro_datos UNIQUE (nombre, apellido, fecha_nacimiento, id_pais),
        CONSTRAINT CK_Arbitro_nombre   CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
        CONSTRAINT CK_Arbitro_apellido CHECK (LEN(LTRIM(RTRIM(apellido))) > 0),
        CONSTRAINT CK_Arbitro_categoria CHECK (categoria IN (N'FIFA', N'CONFEDERACION'))
    );
    PRINT N'Tabla Mundial.Arbitro creada.';
END
ELSE
    PRINT N'Mundial.Arbitro ya existe: no se modifica.';
GO

/* -------------------------------------------------------------
   4. Idioma
   Idiomas que habla cada árbitro. La PK compuesta permite varios
   idiomas por árbitro sin agregar una sexta tabla.
   ------------------------------------------------------------- */
IF OBJECT_ID(N'Mundial.Idioma', N'U') IS NULL
BEGIN
    CREATE TABLE Mundial.Idioma
    (
        id_arbitro INT          NOT NULL,
        idioma     NVARCHAR(50) NOT NULL,
        CONSTRAINT PK_Idioma PRIMARY KEY (id_arbitro, idioma),
        CONSTRAINT FK_Idioma_arbitro FOREIGN KEY (id_arbitro)
            REFERENCES Mundial.Arbitro (id_arbitro),
        CONSTRAINT CK_Idioma_idioma CHECK (LEN(LTRIM(RTRIM(idioma))) > 0)
    );
    PRINT N'Tabla Mundial.Idioma creada.';
END
ELSE
    PRINT N'Mundial.Idioma ya existe: no se modifica.';
GO

/* -------------------------------------------------------------
   5. Terna_Arbitral
   Designación arbitral de un partido: principal, dos asistentes,
   cuarto árbitro y árbitro de VAR. estado = 'Descartada' permite
   conservar el historial de una designación rechazada (por ejemplo,
   por conflicto de nacionalidad) sin borrarla.
   id_partido queda sin FK hasta la sección final de este script.
   ------------------------------------------------------------- */
IF OBJECT_ID(N'Mundial.Terna_Arbitral', N'U') IS NULL
BEGIN
    CREATE TABLE Mundial.Terna_Arbitral
    (
        id_terna             INT IDENTITY(1,1) NOT NULL,
        id_partido           INT               NOT NULL,
        id_arbitro_principal INT               NOT NULL,
        id_asistente_1       INT               NOT NULL,
        id_asistente_2       INT               NOT NULL,
        id_cuarto_arbitro    INT               NOT NULL,
        id_arbitro_var       INT               NOT NULL,
        estado               NVARCHAR(20)      NOT NULL
            CONSTRAINT DF_Terna_Arbitral_estado DEFAULT (N'Activa'),
        motivo_descarte      NVARCHAR(300)     NULL,
        fecha_designacion    DATETIME2(0)      NOT NULL
            CONSTRAINT DF_Terna_Arbitral_fecha_designacion DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_Terna_Arbitral PRIMARY KEY (id_terna),
        CONSTRAINT FK_Terna_Arbitral_principal FOREIGN KEY (id_arbitro_principal)
            REFERENCES Mundial.Arbitro (id_arbitro),
        CONSTRAINT FK_Terna_Arbitral_asistente_1 FOREIGN KEY (id_asistente_1)
            REFERENCES Mundial.Arbitro (id_arbitro),
        CONSTRAINT FK_Terna_Arbitral_asistente_2 FOREIGN KEY (id_asistente_2)
            REFERENCES Mundial.Arbitro (id_arbitro),
        CONSTRAINT FK_Terna_Arbitral_cuarto FOREIGN KEY (id_cuarto_arbitro)
            REFERENCES Mundial.Arbitro (id_arbitro),
        CONSTRAINT FK_Terna_Arbitral_var FOREIGN KEY (id_arbitro_var)
            REFERENCES Mundial.Arbitro (id_arbitro),
        CONSTRAINT CK_Terna_Arbitral_estado CHECK (estado IN (N'Activa', N'Descartada')),
        CONSTRAINT CK_Terna_Arbitral_motivo CHECK (
            (estado = N'Descartada' AND LEN(LTRIM(RTRIM(motivo_descarte))) > 0)
            OR (estado = N'Activa' AND motivo_descarte IS NULL)
        ),
        CONSTRAINT CK_Terna_Arbitral_distintos CHECK (
            id_arbitro_principal <> id_asistente_1
            AND id_arbitro_principal <> id_asistente_2
            AND id_arbitro_principal <> id_cuarto_arbitro
            AND id_arbitro_principal <> id_arbitro_var
            AND id_asistente_1 <> id_asistente_2
            AND id_asistente_1 <> id_cuarto_arbitro
            AND id_asistente_1 <> id_arbitro_var
            AND id_asistente_2 <> id_cuarto_arbitro
            AND id_asistente_2 <> id_arbitro_var
            AND id_cuarto_arbitro <> id_arbitro_var
        )
    );
    PRINT N'Tabla Mundial.Terna_Arbitral creada.';
END
ELSE
    PRINT N'Mundial.Terna_Arbitral ya existe: no se modifica.';
GO

/* Una sola terna ACTIVA por partido. Las descartadas quedan como
   historial y no compiten por la unicidad (índice filtrado). */
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_Terna_Arbitral_partido_activa'
      AND object_id = OBJECT_ID(N'Mundial.Terna_Arbitral')
)
BEGIN
    CREATE UNIQUE INDEX UX_Terna_Arbitral_partido_activa
        ON Mundial.Terna_Arbitral (id_partido)
        WHERE estado = N'Activa';
    PRINT N'Índice UX_Terna_Arbitral_partido_activa creado.';
END
ELSE
    PRINT N'UX_Terna_Arbitral_partido_activa ya existe.';
GO

/* Índice de apoyo para el historial de partidos arbitrados
   (reporte de la Entrega 7). */
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Terna_Arbitral_arbitro_principal'
      AND object_id = OBJECT_ID(N'Mundial.Terna_Arbitral')
)
BEGIN
    CREATE INDEX IX_Terna_Arbitral_arbitro_principal
        ON Mundial.Terna_Arbitral (id_arbitro_principal)
        INCLUDE (id_partido, estado);
    PRINT N'Índice IX_Terna_Arbitral_arbitro_principal creado.';
END
ELSE
    PRINT N'IX_Terna_Arbitral_arbitro_principal ya existe.';
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


/* =============================================================
   Integrante 3: claves foráneas externas
     Sede.id_pais              -> Pais.id_pais        (Integrante 1)
     Arbitro.id_pais           -> Pais.id_pais        (Integrante 1)
     Terna_Arbitral.id_partido -> Partido.id_partido  (Integrante 2)

   Es tolerante: si la tabla destino todavía no existe, avisa por
   PRINT y deja la FK pendiente para una próxima ejecución.
   ============================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Sede.id_pais -> Pais.id_pais */
IF OBJECT_ID(N'Mundial.Pais', N'U') IS NOT NULL
   AND COL_LENGTH(N'Mundial.Pais', N'id_pais') IS NOT NULL
   AND OBJECT_ID(N'Mundial.Sede', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Sede_pais')
    BEGIN
        ALTER TABLE Mundial.Sede WITH CHECK
            ADD CONSTRAINT FK_Sede_pais FOREIGN KEY (id_pais)
            REFERENCES Mundial.Pais (id_pais);
        PRINT N'FK_Sede_pais creada.';
    END
    ELSE
        PRINT N'FK_Sede_pais ya existe.';
END
ELSE
    PRINT N'AVISO: FK_Sede_pais pendiente. Falta Mundial.Pais(id_pais) o Mundial.Sede.';
GO

/* Arbitro.id_pais -> Pais.id_pais */
IF OBJECT_ID(N'Mundial.Pais', N'U') IS NOT NULL
   AND COL_LENGTH(N'Mundial.Pais', N'id_pais') IS NOT NULL
   AND OBJECT_ID(N'Mundial.Arbitro', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Arbitro_pais')
    BEGIN
        ALTER TABLE Mundial.Arbitro WITH CHECK
            ADD CONSTRAINT FK_Arbitro_pais FOREIGN KEY (id_pais)
            REFERENCES Mundial.Pais (id_pais);
        PRINT N'FK_Arbitro_pais creada.';
    END
    ELSE
        PRINT N'FK_Arbitro_pais ya existe.';
END
ELSE
    PRINT N'AVISO: FK_Arbitro_pais pendiente. Falta Mundial.Pais(id_pais) o Mundial.Arbitro.';
GO

/* Terna_Arbitral.id_partido -> Partido.id_partido */
IF OBJECT_ID(N'Mundial.Partido', N'U') IS NOT NULL
   AND COL_LENGTH(N'Mundial.Partido', N'id_partido') IS NOT NULL
   AND OBJECT_ID(N'Mundial.Terna_Arbitral', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Terna_Arbitral_partido')
    BEGIN
        ALTER TABLE Mundial.Terna_Arbitral WITH CHECK
            ADD CONSTRAINT FK_Terna_Arbitral_partido FOREIGN KEY (id_partido)
            REFERENCES Mundial.Partido (id_partido);
        PRINT N'FK_Terna_Arbitral_partido creada.';
    END
    ELSE
        PRINT N'FK_Terna_Arbitral_partido ya existe.';
END
ELSE
    PRINT N'AVISO: FK_Terna_Arbitral_partido pendiente. Falta Mundial.Partido(id_partido) o Mundial.Terna_Arbitral.';
GO

/* Resumen: FK externas que quedaron pendientes. */
SELECT
    fk      = N'FK_Sede_pais / FK_Arbitro_pais / FK_Terna_Arbitral_partido',
    estado  = CASE
                  WHEN OBJECT_ID(N'Mundial.Pais', N'U') IS NULL THEN N'Pendiente: falta Mundial.Pais'
                  WHEN OBJECT_ID(N'Mundial.Partido', N'U') IS NULL THEN N'Pendiente: falta Mundial.Partido'
                  WHEN (SELECT COUNT(*) FROM sys.foreign_keys
                        WHERE name IN (N'FK_Sede_pais', N'FK_Arbitro_pais', N'FK_Terna_Arbitral_partido')) = 3
                       THEN N'Completo: las 3 FK existen'
                  ELSE N'Parcial: revisar los mensajes anteriores'
              END;
GO

-- Tablas provisorias

CREATE TABLE Mundial.