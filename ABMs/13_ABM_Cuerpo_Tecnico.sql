/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Cuerpo_tecnico
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Cuerpo_tecnico_Alta
    @id_seleccion INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @rol VARCHAR(25),
    @mensaje VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
        SET @error = @error + 'Seleccion inexistente. ';

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        SET @error = @error + 'Apellido obligatorio. ';

    IF @rol IS NULL OR @rol NOT IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')
        SET @error = @error + 'Rol invalido (DT, AYUDANTE, PREPARADOR_FISICO, ENTRENADOR_ARQUEROS, MEDICO). ';

    IF @rol = 'DT' AND EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico
                               WHERE id_seleccion = @id_seleccion AND rol = 'DT')
        SET @error = @error + 'La seleccion ya tiene director tecnico. ';

    IF EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico
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

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        SET @error = @error + 'Apellido obligatorio. ';

    IF @rol IS NULL OR @rol NOT IN ('DT','AYUDANTE','PREPARADOR_FISICO','ENTRENADOR_ARQUEROS','MEDICO')
        SET @error = @error + 'Rol invalido. ';

    IF @rol = 'DT' AND EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico
                               WHERE id_seleccion = @id_seleccion AND rol = 'DT'
                                 AND id_cuerpo_tecnico <> @id_cuerpo_tecnico)
        SET @error = @error + 'La seleccion ya tiene otro director tecnico. ';

    IF EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico
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
    IF @id_cuerpo_tecnico IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico)
    BEGIN
        PRINT 'Integrante inexistente. ';
        RETURN;
    END

    DELETE FROM Mundial.Cuerpo_tecnico
    WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico;
END
GO
