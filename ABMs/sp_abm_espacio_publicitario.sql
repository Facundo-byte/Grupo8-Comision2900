USE MundialDeFutbol;
GO

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
