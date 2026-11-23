/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Esquema
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Esquema_Alta
    @lineas VARCHAR(15)
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @lineas IS NULL OR LTRIM(RTRIM(@lineas)) = ''
        SET @error = @error + 'El esquema es obligatorio. ';
    ELSE IF @lineas NOT LIKE '%-%' OR @lineas LIKE '%[^0-9-]%'
        SET @error = @error + 'Formato invalido, usar numeros separados por guion (ej. 4-3-3). ';

    IF EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = @lineas)
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

CREATE OR ALTER PROCEDURE MfSPabm.usp_Esquema_Modificacion
    @id_esquema INT,
    @lineas VARCHAR(15)
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @id_esquema IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'El esquema no existe. ';

    IF @lineas IS NULL OR LTRIM(RTRIM(@lineas)) = ''
        SET @error = @error + 'El esquema es obligatorio. ';
    ELSE IF @lineas NOT LIKE '%-%' OR @lineas LIKE '%[^0-9-]%'
        SET @error = @error + 'Formato invalido, usar numeros separados por guion. ';

    IF EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = @lineas AND id_esquema <> @id_esquema)
        SET @error = @error + 'Otro esquema ya tiene esas lineas. ';

    IF EXISTS (SELECT 1 FROM Mundial.Formacion WHERE id_esquema = @id_esquema)
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

CREATE OR ALTER PROCEDURE MfSPabm.usp_Esquema_Baja
    @id_esquema INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @id_esquema IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'El esquema no existe. ';

    IF EXISTS (SELECT 1 FROM Mundial.Formacion WHERE id_esquema = @id_esquema)
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
