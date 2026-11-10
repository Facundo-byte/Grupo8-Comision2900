USE MundialDeFutbol;
GO

/*POSICION*/
CREATE OR ALTER PROCEDURE Mundial.usp_Posicion_Alta
    @nombre VARCHAR(30),
    @abreviatura VARCHAR(5),
    @mensaje VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @nombre IS NULL OR @nombre = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @abreviatura IS NULL OR @abreviatura = ''
        SET @error = @error + 'Abreviatura obligatoria. ';

    IF EXISTS (SELECT * FROM Mundial.Posicion WHERE nombre = @nombre)
        SET @error = @error + 'La posicion ya existe. ';

    IF EXISTS (SELECT * FROM Mundial.Posicion WHERE abreviatura = @abreviatura)
        SET @error = @error + 'La abreviatura ya existe. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    INSERT INTO Mundial.Posicion (nombre, abreviatura)
    VALUES (@nombre, @abreviatura);
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Posicion_Modificacion
    @id_posicion INT,
    @nombre VARCHAR(30),
    @abreviatura VARCHAR(5),
    @mensaje VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Posicion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'La posicion no existe. ';

    IF @nombre IS NULL OR @nombre = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @abreviatura IS NULL OR @abreviatura = ''
        SET @error = @error + 'Abreviatura obligatoria. ';

    IF EXISTS (SELECT * FROM Mundial.Posicion WHERE nombre = @nombre AND id_posicion <> @id_posicion)
        SET @error = @error + 'Otra posicion ya tiene ese nombre. ';

    IF EXISTS (SELECT * FROM Mundial.Posicion WHERE abreviatura = @abreviatura AND id_posicion <> @id_posicion)
        SET @error = @error + 'Otra posicion ya tiene esa abreviatura. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    UPDATE Mundial.Posicion
    SET nombre = @nombre,
        abreviatura = @abreviatura
    WHERE id_posicion = @id_posicion;
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Posicion_Baja
    @id_posicion INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Posicion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'La posicion no existe. ';

    IF EXISTS (SELECT * FROM Mundial.Jugador_Formacion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'La posicion esta usada en formaciones. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    DELETE FROM Mundial.Posicion
    WHERE id_posicion = @id_posicion;
END
GO

/*ESQUEMA (FORMACION)*/
CREATE OR ALTER PROCEDURE Mundial.usp_Esquema_Alta
    @lineas VARCHAR(15)
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @lineas IS NULL OR @lineas = ''
        SET @error = @error + 'El esquema es obligatorio. ';
    ELSE IF @lineas NOT LIKE '%-%' OR @lineas LIKE '%[^0-9-]%'
        SET @error = @error + 'Formato invalido, usar numeros separados por guion (ej. 4-3-3). ';

    IF EXISTS (SELECT * FROM Mundial.Esquema WHERE lineas = @lineas)
        SET @error = @error + 'El esquema ya existe. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Esquema (lineas)
    VALUES (@lineas);
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Esquema_Modificacion
    @id_esquema INT,
    @lineas VARCHAR(15)
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'El esquema no existe. ';

    IF @lineas IS NULL OR @lineas = ''
        SET @error = @error + 'El esquema es obligatorio. ';
    ELSE IF @lineas NOT LIKE '%-%' OR @lineas LIKE '%[^0-9-]%'
        SET @error = @error + 'Formato invalido, usar numeros separados por guion. ';

    IF EXISTS (SELECT * FROM Mundial.Esquema WHERE lineas = @lineas AND id_esquema <> @id_esquema)
        SET @error = @error + 'Otro esquema ya tiene esas lineas. ';

    IF EXISTS (SELECT * FROM Mundial.Formacion WHERE id_esquema = @id_esquema)
        SET @error = @error + 'El esquema esta en uso en formaciones. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Esquema
    SET lineas = @lineas
    WHERE id_esquema = @id_esquema;
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Esquema_Baja
    @id_esquema INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'El esquema no existe. ';

    IF EXISTS (SELECT * FROM Mundial.Formacion WHERE id_esquema = @id_esquema)
        SET @error = @error + 'El esquema esta en uso en formaciones. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    DELETE FROM Mundial.Esquema
    WHERE id_esquema = @id_esquema;
END
GO

/*FORMACION*/

CREATE OR ALTER PROCEDURE Mundial.usp_Formacion_Alta
    @id_partido INT,
    @id_seleccion INT,
    @id_esquema INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Partido WHERE id = @id_partido)
        SET @error = @error + 'Partido inexistente. ';

    IF NOT EXISTS (SELECT * FROM Mundial.Seleccion WHERE id = @id_seleccion)
        SET @error = @error + 'Seleccion inexistente. ';

    IF NOT EXISTS (SELECT * FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'Esquema inexistente. ';

    -- TODO: reactivar cuando Mundial.Partido tenga las columnas de las selecciones
    -- (ajustar los nombres reales de las columnas).
    -- IF NOT EXISTS (SELECT * FROM Mundial.Partido
    --                WHERE id = @id_partido
    --                  AND (id_seleccion_local = @id_seleccion OR id_seleccion_visitante = @id_seleccion))
    --     SET @error = @error + 'La seleccion no juega ese partido. ';

    IF EXISTS (SELECT * FROM Mundial.Formacion
               WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion)
        SET @error = @error + 'La seleccion ya tiene formacion en ese partido. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Formacion (id_partido, id_seleccion, id_esquema)
    VALUES (@id_partido, @id_seleccion, @id_esquema);
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Formacion_Modificacion
    @id_formacion INT,
    @id_esquema INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Formacion WHERE id_formacion = @id_formacion)
        SET @error = @error + 'Formacion inexistente. ';

    IF NOT EXISTS (SELECT * FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'Esquema inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Formacion
    SET id_esquema = @id_esquema
    WHERE id_formacion = @id_formacion;
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Formacion_Baja
    @id_formacion INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Mundial.Formacion WHERE id_formacion = @id_formacion)
    BEGIN
        PRINT 'Formacion inexistente. ';
        RETURN;
    END

    BEGIN TRANSACTION;

    DELETE FROM Mundial.Jugador_Formacion
    WHERE id_formacion = @id_formacion;

    DELETE FROM Mundial.Formacion
    WHERE id_formacion = @id_formacion;

    COMMIT TRANSACTION;
END
GO

/*JUGADOR_FORMACION*/
CREATE OR ALTER PROCEDURE Mundial.usp_Jugador_Formacion_Alta
    @id_formacion INT,
    @id_jugador INT,
    @id_posicion INT,
    @es_titular BIT = 1
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';
    DECLARE @id_seleccion INT;
    DECLARE @titulares INT;
    DECLARE @suplentes INT;

    SELECT @id_seleccion = id_seleccion
    FROM Mundial.Formacion
    WHERE id_formacion = @id_formacion;

    IF @id_seleccion IS NULL
        SET @error = @error + 'Formacion inexistente. ';

    IF NOT EXISTS (SELECT * FROM Mundial.Jugador WHERE id = @id_jugador)
        SET @error = @error + 'Jugador inexistente. ';

    IF NOT EXISTS (SELECT * FROM Mundial.Posicion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'Posicion inexistente. ';

    IF @es_titular IS NULL
        SET @error = @error + 'Indicar si es titular (1) o suplente (0). ';

    IF EXISTS (SELECT * FROM Mundial.Jugador_Formacion
               WHERE id_formacion = @id_formacion AND id_jugador = @id_jugador)
        SET @error = @error + 'El jugador ya esta en la formacion. ';

    IF @id_seleccion IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT * FROM Mundial.Lista_convocados
                       WHERE id_seleccion = @id_seleccion AND id_jugador = @id_jugador)
            SET @error = @error + 'El jugador no esta convocado por la seleccion. ';

        SELECT @titulares = COUNT(*) FROM Mundial.Jugador_Formacion
        WHERE id_formacion = @id_formacion AND es_titular = 1;

        SELECT @suplentes = COUNT(*) FROM Mundial.Jugador_Formacion
        WHERE id_formacion = @id_formacion AND es_titular = 0;

        IF @es_titular = 1 AND @titulares >= 11
            SET @error = @error + 'Ya hay 11 titulares. ';

        IF @es_titular = 0 AND @suplentes >= 15
            SET @error = @error + 'Ya hay 15 suplentes. ';
    END

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Jugador_Formacion (id_formacion, id_jugador, id_posicion, es_titular)
    VALUES (@id_formacion, @id_jugador, @id_posicion, @es_titular);
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Jugador_Formacion_Modificacion
    @id_formacion INT,
    @id_jugador INT,
    @id_posicion INT,
    @es_titular BIT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';
    DECLARE @actual BIT;
    DECLARE @titulares INT;
    DECLARE @suplentes INT;

    SELECT @actual = es_titular
    FROM Mundial.Jugador_Formacion
    WHERE id_formacion = @id_formacion AND id_jugador = @id_jugador;

    IF @actual IS NULL
        SET @error = @error + 'El jugador no esta en la formacion. ';

    IF NOT EXISTS (SELECT * FROM Mundial.Posicion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'Posicion inexistente. ';

    IF @es_titular IS NULL
        SET @error = @error + 'Indicar si es titular (1) o suplente (0). ';

    IF @actual IS NOT NULL AND @es_titular IS NOT NULL AND @es_titular <> @actual
    BEGIN
        SELECT @titulares = COUNT(*) FROM Mundial.Jugador_Formacion
        WHERE id_formacion = @id_formacion AND es_titular = 1;

        SELECT @suplentes = COUNT(*) FROM Mundial.Jugador_Formacion
        WHERE id_formacion = @id_formacion AND es_titular = 0;

        IF @es_titular = 1 AND @titulares >= 11
            SET @error = @error + 'Ya hay 11 titulares. ';

        IF @es_titular = 0 AND @suplentes >= 15
            SET @error = @error + 'Ya hay 15 suplentes. ';
    END

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Jugador_Formacion
    SET id_posicion = @id_posicion,
        es_titular = @es_titular
    WHERE id_formacion = @id_formacion AND id_jugador = @id_jugador;
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Jugador_Formacion_Baja
    @id_formacion INT,
    @id_jugador INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Mundial.Jugador_Formacion
                   WHERE id_formacion = @id_formacion AND id_jugador = @id_jugador)
    BEGIN
        PRINT 'El jugador no esta en la formacion. ';
        RETURN;
    END

    DELETE FROM Mundial.Jugador_Formacion
    WHERE id_formacion = @id_formacion AND id_jugador = @id_jugador;
END
GO

/*CUERPO_TECNICO*/

CREATE OR ALTER PROCEDURE Mundial.usp_Cuerpo_tecnico_Alta
    @id_seleccion INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @rol VARCHAR(25),
    @mensaje VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Seleccion WHERE id = @id_seleccion)
        SET @error = @error + 'Seleccion inexistente. ';

    IF @nombre IS NULL OR @nombre = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @apellido IS NULL OR @apellido = ''
        SET @error = @error + 'Apellido obligatorio. ';

    IF @rol IS NULL OR @rol NOT IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')
        SET @error = @error + 'Rol invalido (DT, AYUDANTE, PREPARADOR_FISICO, ENTRENADOR_ARQUEROS, MEDICO). ';

    IF @rol = 'DT' AND EXISTS (SELECT * FROM Mundial.Cuerpo_tecnico
                               WHERE id_seleccion = @id_seleccion AND rol = 'DT')
        SET @error = @error + 'La seleccion ya tiene director tecnico. ';

    IF EXISTS (SELECT * FROM Mundial.Cuerpo_tecnico
               WHERE id_seleccion = @id_seleccion AND nombre = @nombre AND apellido = @apellido)
        SET @error = @error + 'La persona ya esta en el cuerpo tecnico. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    INSERT INTO Mundial.Cuerpo_tecnico (id_seleccion, nombre, apellido, rol)
    VALUES (@id_seleccion, @nombre, @apellido, @rol);
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Cuerpo_tecnico_Modificacion
    @id_cuerpo_tecnico INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @rol VARCHAR(25),
    @mensaje VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';
    DECLARE @id_seleccion INT;

    SELECT @id_seleccion = id_seleccion
    FROM Mundial.Cuerpo_tecnico
    WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico;

    IF @id_seleccion IS NULL
        SET @error = @error + 'Integrante inexistente. ';

    IF @nombre IS NULL OR @nombre = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @apellido IS NULL OR @apellido = ''
        SET @error = @error + 'Apellido obligatorio. ';

    IF @rol IS NULL OR @rol NOT IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')
        SET @error = @error + 'Rol invalido. ';

    IF @rol = 'DT' AND EXISTS (SELECT * FROM Mundial.Cuerpo_tecnico
                               WHERE id_seleccion = @id_seleccion AND rol = 'DT'
                                 AND id_cuerpo_tecnico <> @id_cuerpo_tecnico)
        SET @error = @error + 'La seleccion ya tiene otro director tecnico. ';

    IF EXISTS (SELECT * FROM Mundial.Cuerpo_tecnico
               WHERE id_seleccion = @id_seleccion AND nombre = @nombre AND apellido = @apellido
                 AND id_cuerpo_tecnico <> @id_cuerpo_tecnico)
        SET @error = @error + 'Esa persona ya esta en el cuerpo tecnico. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    UPDATE Mundial.Cuerpo_tecnico
    SET nombre = @nombre,
        apellido = @apellido,
        rol = @rol
    WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico;
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Cuerpo_tecnico_Baja
    @id_cuerpo_tecnico INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Mundial.Cuerpo_tecnico WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico)
    BEGIN
        PRINT 'Integrante inexistente. ';
        RETURN;
    END

    DELETE FROM Mundial.Cuerpo_tecnico
    WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico;
END
GO

/*ESPACIO_PUBLICITARIO*/

CREATE OR ALTER PROCEDURE Mundial.usp_Espacio_publicitario_Alta
    @id_sede INT,
    @numero_espacio TINYINT,
    @descripcion VARCHAR(100) = NULL,
    @id_pais_interes INT = NULL
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Sede WHERE id = @id_sede)
        SET @error = @error + 'Sede inexistente. ';

    IF @numero_espacio IS NULL OR @numero_espacio NOT BETWEEN 1 AND 4
        SET @error = @error + 'El numero de espacio debe ser de 1 a 4. ';

    IF EXISTS (SELECT * FROM Mundial.Espacio_publicitario
               WHERE id_sede = @id_sede AND numero_espacio = @numero_espacio)
        SET @error = @error + 'La sede ya tiene ese numero de espacio. ';

    IF (SELECT COUNT(*) FROM Mundial.Espacio_publicitario WHERE id_sede = @id_sede) >= 4
        SET @error = @error + 'La sede ya tiene los 4 espacios. ';

    IF @id_pais_interes IS NOT NULL
       AND NOT EXISTS (SELECT * FROM Mundial.Pais WHERE id_pais = @id_pais_interes)
        SET @error = @error + 'Pais de interes inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Espacio_publicitario (id_sede, numero_espacio, descripcion, id_pais_interes)
    VALUES (@id_sede, @numero_espacio, @descripcion, @id_pais_interes);
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Espacio_publicitario_Modificacion
    @id_espacio INT,
    @descripcion VARCHAR(100) = NULL,
    @id_pais_interes INT = NULL
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT * FROM Mundial.Espacio_publicitario WHERE id_espacio = @id_espacio)
        SET @error = @error + 'Espacio inexistente. ';

    IF @id_pais_interes IS NOT NULL
       AND NOT EXISTS (SELECT * FROM Mundial.Pais WHERE id_pais = @id_pais_interes)
        SET @error = @error + 'Pais de interes inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Espacio_publicitario
    SET descripcion = @descripcion,
        id_pais_interes = @id_pais_interes
    WHERE id_espacio = @id_espacio;
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Espacio_publicitario_Baja
    @id_espacio INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Mundial.Espacio_publicitario WHERE id_espacio = @id_espacio)
    BEGIN
        PRINT 'Espacio inexistente. ';
        RETURN;
    END

    -- Falta validar (cuando exista la tabla) que no tenga publicidades exhibidas.
    DELETE FROM Mundial.Espacio_publicitario
    WHERE id_espacio = @id_espacio;
END
GO
