USE MundialDeFutbol;
GO

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
