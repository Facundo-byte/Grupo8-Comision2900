USE MundialDeFutbol;
GO

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
