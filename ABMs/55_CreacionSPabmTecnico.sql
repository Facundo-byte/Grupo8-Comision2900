/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Tecnico
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Tecnico_Alta
    @id_cuerpo_tecnico INT,
    @nombre            VARCHAR(50),
    @apellido          VARCHAR(50),
    @rol               VARCHAR(25),
    @mensaje           VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    -- 1) FK a Cuerpo_tecnico
    IF @id_cuerpo_tecnico IS NULL
        SET @error = @error + 'id_cuerpo_tecnico es obligatorio. ';
    ELSE IF NOT EXISTS (
        SELECT 1 FROM Mundial.Cuerpo_tecnico
        WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico
    )
        SET @error = @error + 'Cuerpo tecnico inexistente. ';

    -- 2) Nombre / apellido
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'Nombre obligatorio. ';
    ELSE IF LEN(LTRIM(RTRIM(@nombre))) > 50
        SET @error = @error + 'Nombre supera los 50 caracteres. ';

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        SET @error = @error + 'Apellido obligatorio. ';
    ELSE IF LEN(LTRIM(RTRIM(@apellido))) > 50
        SET @error = @error + 'Apellido supera los 50 caracteres. ';

    -- 3) Rol válido
    IF @rol IS NULL
        SET @error = @error + 'Rol obligatorio. ';
    ELSE IF @rol NOT IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')
        SET @error = @error + 'Rol invalido (DT, AYUDANTE, PREPARADOR_FISICO, ENTRENADOR_ARQUEROS, MEDICO). ';

    -- 4) Un solo DT por cuerpo técnico
    IF @rol = 'DT' AND @id_cuerpo_tecnico IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Tecnico
            WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico AND rol = 'DT'
       )
        SET @error = @error + 'El cuerpo tecnico ya tiene director tecnico. ';

    -- 5) Persona duplicada en el mismo cuerpo técnico
    IF @nombre IS NOT NULL AND @apellido IS NOT NULL
       AND @id_cuerpo_tecnico IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Tecnico
            WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico
              AND nombre   = LTRIM(RTRIM(@nombre))
              AND apellido = LTRIM(RTRIM(@apellido))
       )
        SET @error = @error + 'La persona ya esta en el cuerpo tecnico. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    INSERT INTO Mundial.Tecnico (id_cuerpo_tecnico, nombre, apellido, rol)
    VALUES (@id_cuerpo_tecnico,
            LTRIM(RTRIM(@nombre)),
            LTRIM(RTRIM(@apellido)),
            @rol);

    SET @mensaje = 'Tecnico creado exitosamente.';
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Tecnico_Modificacion
    @id_tecnico         INT,
    @id_cuerpo_tecnico  INT,
    @nombre             VARCHAR(50),
    @apellido           VARCHAR(50),
    @rol                VARCHAR(25),
    @mensaje            VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    -- 1) Existencia del técnico
    IF @id_tecnico IS NULL
        SET @error = @error + 'id_tecnico es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Tecnico WHERE id_tecnico = @id_tecnico)
        SET @error = @error + 'Tecnico inexistente. ';

    -- 2) FK a Cuerpo_tecnico
    IF @id_cuerpo_tecnico IS NULL
        SET @error = @error + 'id_cuerpo_tecnico es obligatorio. ';
    ELSE IF NOT EXISTS (
        SELECT 1 FROM Mundial.Cuerpo_tecnico
        WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico
    )
        SET @error = @error + 'Cuerpo tecnico inexistente. ';

    -- 3) Nombre / apellido
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'Nombre obligatorio. ';
    ELSE IF LEN(LTRIM(RTRIM(@nombre))) > 50
        SET @error = @error + 'Nombre supera los 50 caracteres. ';

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        SET @error = @error + 'Apellido obligatorio. ';
    ELSE IF LEN(LTRIM(RTRIM(@apellido))) > 50
        SET @error = @error + 'Apellido supera los 50 caracteres. ';

    -- 4) Rol válido
    IF @rol IS NULL
        SET @error = @error + 'Rol obligatorio. ';
    ELSE IF @rol NOT IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')
        SET @error = @error + 'Rol invalido. ';

    -- 5) Un solo DT por cuerpo técnico (excluyendo el propio)
    IF @rol = 'DT' AND @id_cuerpo_tecnico IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Tecnico
            WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico
              AND rol = 'DT'
              AND id_tecnico <> @id_tecnico
       )
        SET @error = @error + 'El cuerpo tecnico ya tiene otro director tecnico. ';

    -- 6) Persona duplicada en el mismo cuerpo técnico (excluyendo el propio)
    IF @nombre IS NOT NULL AND @apellido IS NOT NULL
       AND @id_cuerpo_tecnico IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Tecnico
            WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico
              AND nombre   = LTRIM(RTRIM(@nombre))
              AND apellido = LTRIM(RTRIM(@apellido))
              AND id_tecnico <> @id_tecnico
       )
        SET @error = @error + 'Esa persona ya esta en el cuerpo tecnico. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    UPDATE Mundial.Tecnico
    SET id_cuerpo_tecnico = @id_cuerpo_tecnico,
        nombre            = LTRIM(RTRIM(@nombre)),
        apellido          = LTRIM(RTRIM(@apellido)),
        rol               = @rol
    WHERE id_tecnico = @id_tecnico;

    SET @mensaje = 'Tecnico modificado exitosamente.';
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Tecnico_Baja
    @id_tecnico INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_tecnico IS NULL
    BEGIN
        PRINT 'id_tecnico es obligatorio. ';
        RETURN 1;
    END

    IF NOT EXISTS (SELECT 1 FROM Mundial.Tecnico WHERE id_tecnico = @id_tecnico)
    BEGIN
        PRINT 'Tecnico inexistente. ';
        RETURN 1;
    END

    DELETE FROM Mundial.Tecnico
    WHERE id_tecnico = @id_tecnico;
END
GO





























