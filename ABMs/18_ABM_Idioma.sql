/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Idioma
*/

USE MundialDeFutbol;
GO

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

CREATE OR ALTER PROCEDURE Mundial.Idioma_Alta
    @idioma  NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @idioma IS NULL
        SET @errores += N'idioma es obligatorio. ';
    ELSE
    BEGIN
        SET @idioma = LTRIM(RTRIM(@idioma));
        IF @idioma = N''
            SET @errores += N'idioma no puede estar vacío. ';
        IF LEN(@idioma) > 50
            SET @errores += N'idioma supera los 50 caracteres que admite la columna. ';
        IF EXISTS(select idioma from Mundial.Idioma where idioma = @idioma)
            SET @errores += N'El idioma ya existe'

    END

    IF @errores <> N''
        THROW 50901, @errores, 1;

    INSERT INTO Mundial.Idioma(idioma)
    VALUES (@idioma);
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Idioma_Modificar
    @id_idioma   INT,
    @idioma        NVARCHAR(200),
    @idioma_nuevo  NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_idioma IS NULL
        SET @errores += N'id_idioma es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_idioma = @id_idioma)
        SET @errores += N'id_idioma no existe en Mundial.Idioma. ';

    IF @idioma IS NULL
        SET @errores += N'idioma es obligatorio. ';
    ELSE
    BEGIN
        SET @idioma = LTRIM(RTRIM(@idioma));
        IF @idioma = N''
            SET @errores += N'idioma no puede estar vacío. ';
        ELSE IF @id_idioma IS NOT NULL
             AND NOT EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_idioma = @id_idioma AND idioma = @idioma)
            SET @errores += N'El id no tiene registrado ese idioma. ';
    END

    IF @idioma_nuevo IS NULL
        SET @errores += N'idioma_nuevo es obligatorio. ';
    ELSE
    BEGIN
        SET @idioma_nuevo = LTRIM(RTRIM(@idioma_nuevo));
        IF @idioma_nuevo = N''
            SET @errores += N'idioma_nuevo no puede estar vacío. ';
        IF LEN(@idioma_nuevo) > 50
            SET @errores += N'idioma_nuevo supera los 50 caracteres que admite la columna. ';
        IF @id_idioma IS NOT NULL
           AND EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_idioma = @id_idioma AND idioma = @idioma_nuevo)
           AND @idioma_nuevo <> @idioma
            SET @errores += N'El id ya tiene registrado ese idioma. ';
    END

    IF @errores <> N''
        THROW 50902, @errores, 1;

    UPDATE Mundial.Idioma
    SET idioma = @idioma_nuevo
    WHERE id_idioma = @id_idioma
      AND idioma = @idioma;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50902, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Idioma_Baja
    @id_idioma INT,
    @idioma     NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_idioma IS NULL
        SET @errores += N'id_idioma es obligatorio. ';
    IF @idioma IS NULL
        SET @errores += N'idioma es obligatorio. ';
    ELSE
        SET @idioma = LTRIM(RTRIM(@idioma));

    IF @id_idioma IS NOT NULL AND @idioma IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_idioma = @id_idioma AND idioma = @idioma)
        SET @errores += N'El id no tiene registrado ese idioma. ';

    IF @errores <> N''
        THROW 50903, @errores, 1;

    DELETE FROM Mundial.Idioma
    WHERE id_idioma = @id_idioma
      AND idioma = @idioma;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50903, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO
