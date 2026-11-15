USE MundialDeFutbol;
GO

IF TYPE_ID('Mundial.tt_JugadorFormacion') IS NULL
    CREATE TYPE Mundial.tt_JugadorFormacion AS TABLE
    (
        id_jugador  INT NOT NULL PRIMARY KEY,
        id_posicion INT NOT NULL,
        es_titular  BIT NOT NULL
    );
GO

IF TYPE_ID('Mundial.tt_MiembroCuerpoTecnico') IS NULL
    CREATE TYPE Mundial.tt_MiembroCuerpoTecnico AS TABLE
    (
        nombre   VARCHAR(50) NOT NULL,
        apellido VARCHAR(50) NOT NULL,
        rol      VARCHAR(25) NOT NULL
    );
GO

/* Formacion completa: cabecera + titulares + suplentes  */
CREATE OR ALTER PROCEDURE Mundial.usp_Registrar_Formacion_Completa
    @id_partido INT,
    @id_seleccion INT,
    @id_esquema INT,
    @plantel Mundial.tt_JugadorFormacion READONLY
AS
BEGIN
    DECLARE @error VARCHAR(1000) = '';
    DECLARE @titulares INT, @suplentes INT, @arqueros INT, @total INT;
    DECLARE @inexistentes INT, @no_convocados INT, @pos_inexistentes INT;
    DECLARE @id_formacion INT, @insertados INT;
    DECLARE @id_jugador INT, @id_posicion INT, @es_titular BIT;

    SELECT @total = COUNT(*),
           @titulares = COUNT(CASE WHEN es_titular = 1 THEN 1 END),
           @suplentes = COUNT(CASE WHEN es_titular = 0 THEN 1 END)
    FROM @plantel;

    SELECT @arqueros = COUNT(*)
    FROM @plantel p
    JOIN Mundial.Posicion po ON po.id_posicion = p.id_posicion
    WHERE p.es_titular = 1 AND po.abreviatura = 'ARQ';

    SELECT @inexistentes = COUNT(*)
    FROM @plantel p
    WHERE NOT EXISTS (SELECT * FROM Mundial.Jugador j WHERE j.id = p.id_jugador);

    SELECT @no_convocados = COUNT(*)
    FROM @plantel p
    WHERE NOT EXISTS (SELECT * FROM Mundial.Lista_convocados l
                      WHERE l.id_seleccion = @id_seleccion AND l.id_jugador = p.id_jugador);

    SELECT @pos_inexistentes = COUNT(*)
    FROM @plantel p
    WHERE NOT EXISTS (SELECT * FROM Mundial.Posicion po WHERE po.id_posicion = p.id_posicion);

    IF NOT EXISTS (SELECT * FROM Mundial.Partido WHERE id = @id_partido)
        SET @error = @error + 'Partido inexistente. ';

    -- Desomentar: reactivar cuando Mundial.Partido tenga las columnas de las selecciones
    -- (ajustar los nombres reales de las columnas).
    -- IF NOT EXISTS (SELECT * FROM Mundial.Partido
    --                WHERE id = @id_partido
    --                  AND (id_seleccion_local = @id_seleccion OR id_seleccion_visitante = @id_seleccion))
    --     SET @error = @error + 'La seleccion no juega ese partido. ';

    IF NOT EXISTS (SELECT * FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'Esquema inexistente. ';

    IF EXISTS (SELECT * FROM Mundial.Formacion
               WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion)
        SET @error = @error + 'La seleccion ya tiene formacion en ese partido. ';

    IF @titulares <> 11
        SET @error = @error + 'Se requieren 11 titulares. ';

    IF @suplentes > 15
        SET @error = @error + 'El banco admite hasta 15 suplentes. ';

    IF @arqueros <> 1
        SET @error = @error + 'Debe haber 1 arquero (ARQ) entre los titulares. ';

    IF @inexistentes > 0
        SET @error = @error + 'Hay jugadores inexistentes en el plantel. ';

    IF @no_convocados > 0
        SET @error = @error + 'Hay jugadores que no estan convocados por la seleccion. ';

    IF @pos_inexistentes > 0
        SET @error = @error + 'Hay posiciones inexistentes en el plantel. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    BEGIN TRANSACTION;

    EXEC Mundial.usp_Formacion_Alta @id_partido, @id_seleccion, @id_esquema;

    SELECT @id_formacion = id_formacion
    FROM Mundial.Formacion
    WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion;

    IF @id_formacion IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'No se pudo crear la formacion. ';
        RETURN;
    END

    -- Se ordena el plantel (titulares primero) y se recorre con un bucle WHILE.
    DECLARE @cola TABLE (orden INT IDENTITY(1,1) PRIMARY KEY, id_jugador INT, id_posicion INT, es_titular BIT);
    DECLARE @i INT = 1;

    INSERT INTO @cola (id_jugador, id_posicion, es_titular)
    SELECT id_jugador, id_posicion, es_titular
    FROM @plantel
    ORDER BY es_titular DESC, id_jugador;

    WHILE @i <= @total
    BEGIN
        SELECT @id_jugador = id_jugador, @id_posicion = id_posicion, @es_titular = es_titular
        FROM @cola
        WHERE orden = @i;

        EXEC Mundial.usp_Jugador_Formacion_Alta @id_formacion, @id_jugador, @id_posicion, @es_titular;
        SET @i = @i + 1;
    END

    SELECT @insertados = COUNT(*)
    FROM Mundial.Jugador_Formacion
    WHERE id_formacion = @id_formacion;

    IF @insertados <> @total
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'No se cargaron todos los jugadores. Se deshizo la operacion. ';
        RETURN;
    END

    COMMIT TRANSACTION;
    PRINT 'Formacion registrada correctamente. ';
END
GO

/*Cuerpo tecnico de una seleccion (lote, exactamente 1 DT)*/
CREATE OR ALTER PROCEDURE Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion
    @id_seleccion INT,
    @miembros Mundial.tt_MiembroCuerpoTecnico READONLY
AS
BEGIN
    DECLARE @error VARCHAR(1000) = '';
    DECLARE @total INT, @dt_lote INT, @dt_actual INT;
    DECLARE @roles_invalidos INT, @repetidos_lote INT, @repetidos_existentes INT;
    DECLARE @antes INT, @despues INT;
    DECLARE @nombre VARCHAR(50), @apellido VARCHAR(50), @rol VARCHAR(25);

    SELECT @total = COUNT(*),
           @dt_lote = COUNT(CASE WHEN rol = 'DT' THEN 1 END),
           @roles_invalidos = COUNT(CASE WHEN rol NOT IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO') THEN 1 END)
    FROM @miembros;

    SELECT @dt_actual = COUNT(*)
    FROM Mundial.Cuerpo_tecnico
    WHERE id_seleccion = @id_seleccion AND rol = 'DT';

    SELECT @repetidos_lote = COUNT(*)
    FROM (SELECT nombre, apellido
          FROM @miembros
          GROUP BY nombre, apellido
          HAVING COUNT(*) > 1) d;

    SELECT @repetidos_existentes = COUNT(*)
    FROM @miembros m
    JOIN Mundial.Cuerpo_tecnico c
      ON c.id_seleccion = @id_seleccion AND c.nombre = m.nombre AND c.apellido = m.apellido;

    IF NOT EXISTS (SELECT * FROM Mundial.Seleccion WHERE id = @id_seleccion)
        SET @error = @error + 'Seleccion inexistente. ';

    IF @total = 0
        SET @error = @error + 'No se recibio ningun integrante. ';

    IF @roles_invalidos > 0
        SET @error = @error + 'Hay roles invalidos en el lote. ';

    IF @dt_lote + @dt_actual <> 1
        SET @error = @error + 'La seleccion debe quedar con exactamente 1 director tecnico. ';

    IF @repetidos_lote > 0
        SET @error = @error + 'Hay personas repetidas en el lote. ';

    IF @repetidos_existentes > 0
        SET @error = @error + 'Hay personas que ya estan en el cuerpo tecnico. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    SELECT @antes = COUNT(*)
    FROM Mundial.Cuerpo_tecnico
    WHERE id_seleccion = @id_seleccion;

    BEGIN TRANSACTION;

    DECLARE @cola TABLE (orden INT IDENTITY(1,1) PRIMARY KEY, nombre VARCHAR(50), apellido VARCHAR(50), rol VARCHAR(25));
    DECLARE @i INT = 1;

    INSERT INTO @cola (nombre, apellido, rol)
    SELECT nombre, apellido, rol
    FROM @miembros;

    WHILE @i <= @total
    BEGIN
        SELECT @nombre = nombre, @apellido = apellido, @rol = rol
        FROM @cola
        WHERE orden = @i;

        EXEC Mundial.usp_Cuerpo_tecnico_Alta @id_seleccion, @nombre, @apellido, @rol;
        SET @i = @i + 1;
    END

    SELECT @despues = COUNT(*)
    FROM Mundial.Cuerpo_tecnico
    WHERE id_seleccion = @id_seleccion;

    IF @despues - @antes <> @total
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'No se cargaron todos los integrantes. Se deshizo la operacion. ';
        RETURN;
    END

    COMMIT TRANSACTION;
    PRINT 'Cuerpo tecnico registrado correctamente. ';
END
GO

/*Completar los 4 espacios publicitarios de una sede*/
CREATE OR ALTER PROCEDURE Mundial.usp_Inicializar_Espacios_Sede
    @id_sede INT
AS
BEGIN
    DECLARE @numero TINYINT;
    DECLARE @descripcion VARCHAR(100);
    DECLARE @cantidad INT;

    IF NOT EXISTS (SELECT * FROM Mundial.Sede WHERE id = @id_sede)
    BEGIN
        PRINT 'Sede inexistente. ';
        RETURN;
    END

    BEGIN TRANSACTION;

    SET @numero = 1;

    WHILE @numero <= 4
    BEGIN
        IF NOT EXISTS (SELECT * FROM Mundial.Espacio_publicitario
                       WHERE id_sede = @id_sede AND numero_espacio = @numero)
        BEGIN
            SET @descripcion = 'Panel perimetral rotativo ' + CAST(@numero AS VARCHAR(1));
            EXEC Mundial.usp_Espacio_publicitario_Alta @id_sede, @numero, @descripcion, NULL;
        END
        SET @numero = @numero + 1;
    END

    SELECT @cantidad = COUNT(*)
    FROM Mundial.Espacio_publicitario
    WHERE id_sede = @id_sede;

    IF @cantidad <> 4
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'La sede no quedo con 4 espacios. Se deshizo la operacion. ';
        RETURN;
    END

    COMMIT TRANSACTION;
    PRINT 'Espacios publicitarios completos (4). ';
END
GO

/* Historial de titularidad de un jugador en el torneo */
CREATE OR ALTER PROCEDURE Mundial.usp_Historial_Titularidad_Jugador
    @id_jugador INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Mundial.Jugador WHERE id = @id_jugador)
    BEGIN
        PRINT 'Jugador inexistente. ';
        RETURN;
    END

    SELECT p.id AS id_partido,
           -- agregar p.fecha_hora_utc y p.fase cuando existan en Mundial.Partido
           f.id_seleccion,
           e.lineas AS esquema,
           po.abreviatura AS posicion,
           CASE jf.es_titular WHEN 1 THEN 'Titular' ELSE 'Suplente' END AS condicion
    FROM Mundial.Jugador_Formacion jf
    JOIN Mundial.Formacion f  ON f.id_formacion = jf.id_formacion
    JOIN Mundial.Partido p    ON p.id = f.id_partido
    JOIN Mundial.Esquema e    ON e.id_esquema = f.id_esquema
    JOIN Mundial.Posicion po  ON po.id_posicion = jf.id_posicion
    WHERE jf.id_jugador = @id_jugador
    ORDER BY p.id;
END
GO
