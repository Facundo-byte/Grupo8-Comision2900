USE MundialDeFutbol;
GO

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
