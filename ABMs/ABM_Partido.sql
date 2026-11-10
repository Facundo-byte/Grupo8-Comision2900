/*
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
	Descripcion: Store Procedures ABM de la Tabla Partido
*/

CREATE OR ALTER PROCEDURE Mundial.Partido_Alta
    @id_sede INT,
    @id_seleccion_local INT,
    @id_seleccion_visitante INT,
    @fecha_hora_local DATETIME,
    @fecha_hora_utc DATETIME,
    @goles_local INT = NULL,
    @goles_visitante INT = NULL,
    @asistencia INT = NULL,
    @fase VARCHAR(MAX) = 'fasedegrupos',
    @id_partido INT = NULL OUTPUT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_sede IS NULL
        SET @errores += N'id_sede es obligatorio. ';
    IF @id_sede IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Sede
        WHERE id_sede = @id_sede
    )
        SET @errores += N'id_sede no existe en Mundial.Sede. ';

    IF @id_seleccion_local IS NULL
        SET @errores += N'id_seleccion_local es obligatorio. ';
    IF @id_seleccion_local IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Seleccion
        WHERE id_seleccion = @id_seleccion_local
    )
        SET @errores += N'id_seleccion_local no existe en Mundial.Seleccion. ';

    IF @id_seleccion_visitante IS NULL
        SET @errores += N'id_seleccion_visitante es obligatorio. ';
    IF @id_seleccion_visitante IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Seleccion
        WHERE id_seleccion = @id_seleccion_visitante
    )
        SET @errores += N'id_seleccion_visitante no existe en Mundial.Seleccion. ';

    IF @id_seleccion_local = @id_seleccion_visitante
        SET @errores += N'Las dos selecciones deben ser distintas. ';

    IF @fecha_hora_local IS NULL
        SET @errores += N'fecha_hora_local es obligatorio. ';
    IF @fecha_hora_utc IS NULL
        SET @errores += N'fecha_hora_utc es obligatorio. ';

    IF @goles_local < 0
        SET @errores += N'goles_local debe ser mayor o igual a cero. ';
    IF @goles_visitante < 0
        SET @errores += N'goles_visitante debe ser mayor o igual a cero. ';
    IF @asistencia < 0
        SET @errores += N'asistencia debe ser mayor o igual a cero. ';

    IF @fase IS NULL
        SET @errores += N'fase es obligatorio. ';
    IF @fase IS NOT NULL AND @fase NOT IN ('fasedegrupos', 'cuartos de final', 'octavos de final', 'tercer puesto', 'semifinal', 'final')
        SET @errores += N'fase debe ser uno de estos valores: fasedegrupos, cuartos de final, octavos de final, tercer puesto, semifinal, final. ';
    IF DATALENGTH(@fase) > 20
        SET @errores += N'fase supera los 20 bytes que admite la columna. ';

    IF @errores <> N''
        THROW 50101, @errores, 1;

    INSERT INTO Mundial.Partido
        (id_sede, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia, fase)
    VALUES
        (@id_sede, @id_seleccion_local, @id_seleccion_visitante, @fecha_hora_local, @fecha_hora_utc, @goles_local, @goles_visitante, @asistencia, @fase);

    IF @@ROWCOUNT = 1
        SET @id_partido = CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Partido_Modificar
    @id_partido INT,
    @id_sede INT,
    @id_seleccion_local INT,
    @id_seleccion_visitante INT,
    @fecha_hora_local DATETIME,
    @fecha_hora_utc DATETIME,
    @goles_local INT = NULL,
    @goles_visitante INT = NULL,
    @asistencia INT = NULL,
    @fase VARCHAR(MAX) = 'fasedegrupos'
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
    )
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    IF @id_sede IS NULL
        SET @errores += N'id_sede es obligatorio. ';
    IF @id_sede IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Sede
        WHERE id_sede = @id_sede
    )
        SET @errores += N'id_sede no existe en Mundial.Sede. ';

    IF @id_seleccion_local IS NULL
        SET @errores += N'id_seleccion_local es obligatorio. ';
    IF @id_seleccion_local IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Seleccion
        WHERE id_seleccion = @id_seleccion_local
    )
        SET @errores += N'id_seleccion_local no existe en Mundial.Seleccion. ';

    IF @id_seleccion_visitante IS NULL
        SET @errores += N'id_seleccion_visitante es obligatorio. ';
    IF @id_seleccion_visitante IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Seleccion
        WHERE id_seleccion = @id_seleccion_visitante
    )
        SET @errores += N'id_seleccion_visitante no existe en Mundial.Seleccion. ';

    IF @id_seleccion_local = @id_seleccion_visitante
        SET @errores += N'Las dos selecciones deben ser distintas. ';

    IF @fecha_hora_local IS NULL
        SET @errores += N'fecha_hora_local es obligatorio. ';
    IF @fecha_hora_utc IS NULL
        SET @errores += N'fecha_hora_utc es obligatorio. ';

    IF @goles_local < 0
        SET @errores += N'goles_local debe ser mayor o igual a cero. ';
    IF @goles_visitante < 0
        SET @errores += N'goles_visitante debe ser mayor o igual a cero. ';
    IF @asistencia < 0
        SET @errores += N'asistencia debe ser mayor o igual a cero. ';

    IF @fase IS NULL
        SET @errores += N'fase es obligatorio. ';
    IF @fase IS NOT NULL AND @fase NOT IN ('fasedegrupos', 'cuartos de final', 'octavos de final', 'tercer puesto', 'semifinal', 'final')
        SET @errores += N'fase debe ser uno de estos valores: fasedegrupos, cuartos de final, octavos de final, tercer puesto, semifinal, final. ';
    IF DATALENGTH(@fase) > 20
        SET @errores += N'fase supera los 20 bytes que admite la columna. ';

    IF @errores <> N''
        THROW 50102, @errores, 1;

    UPDATE Mundial.Partido
    SET id_sede = @id_sede,
        id_seleccion_local = @id_seleccion_local,
        id_seleccion_visitante = @id_seleccion_visitante,
        fecha_hora_local = @fecha_hora_local,
        fecha_hora_utc = @fecha_hora_utc,
        goles_local = @goles_local,
        goles_visitante = @goles_visitante,
        asistencia = @asistencia,
        fase = @fase
    WHERE id_partido = @id_partido -- Basicamente con esta condicion se asegura que si vos queres hacer un update lo tengas que hacer si o si sobre las selecciones que estan jugando en ese partido
      AND NOT EXISTS (
        SELECT 1 FROM Mundial.Sustitucion WITH (HOLDLOCK)
        WHERE id_partido = @id_partido
          AND id_seleccion NOT IN (@id_seleccion_local, @id_seleccion_visitante)
    );

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50102, N'Los datos relacionados cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Partido_Baja
    @id_partido INT
AS
BEGIN
	DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
    )
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    IF EXISTS (
        SELECT 1 FROM Mundial.Gol
        WHERE id_partido = @id_partido
    )
        SET @errores += N'El partido tiene registros en Mundial.Gol. ';

    IF EXISTS (
        SELECT 1 FROM Mundial.Tarjeta
        WHERE id_partido = @id_partido
    )
        SET @errores += N'El partido tiene registros en Mundial.Tarjeta. ';

    IF EXISTS (
        SELECT 1 FROM Mundial.Sustitucion
        WHERE id_partido = @id_partido
    )
        SET @errores += N'El partido tiene registros en Mundial.Sustitucion. ';

    IF @errores <> N''
        THROW 50103, @errores, 1;

    DELETE FROM Mundial.Partido
    WHERE id_partido = @id_partido;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50103, N'id_partido no existe en Mundial.Partido. ', 1;
END;
GO
