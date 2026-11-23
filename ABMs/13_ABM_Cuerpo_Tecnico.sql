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
    @mensaje      VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_seleccion IS NULL
        SET @error = @error + 'id_seleccion es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
        SET @error = @error + 'Seleccion inexistente. ';
    ELSE IF EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @id_seleccion)
        SET @error = @error + 'La seleccion ya tiene un cuerpo tecnico registrado. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    INSERT INTO Mundial.Cuerpo_tecnico (id_seleccion)
    VALUES (@id_seleccion);

    SET @mensaje = 'Cuerpo tecnico creado exitosamente.';
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Cuerpo_tecnico_Modificacion
    @id_cuerpo_tecnico INT,
    @id_seleccion      INT,
    @mensaje           VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_cuerpo_tecnico IS NULL
        SET @error = @error + 'id_cuerpo_tecnico es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico)
        SET @error = @error + 'Integrante inexistente. ';

    IF @id_seleccion IS NULL
        SET @error = @error + 'id_seleccion es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
        SET @error = @error + 'Seleccion inexistente. ';
    ELSE IF EXISTS (
        SELECT 1 FROM Mundial.Cuerpo_tecnico
        WHERE id_seleccion = @id_seleccion
          AND id_cuerpo_tecnico <> @id_cuerpo_tecnico
    )
        SET @error = @error + 'La seleccion ya tiene otro cuerpo tecnico asignado. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    UPDATE Mundial.Cuerpo_tecnico
    SET id_seleccion = @id_seleccion
    WHERE id_cuerpo_tecnico = @id_cuerpo_tecnico;

    SET @mensaje = 'Cuerpo tecnico modificado exitosamente.';
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
