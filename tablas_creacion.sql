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
    CONSTRAINT FK_Formacion_Partido   FOREIGN KEY (id_partido)   REFERENCES Mundial.Partido(id),
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