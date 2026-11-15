/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Práctico: Sistema de Registro y Gestión del Mundial de Fútbol
    Entrega 5 - Base de Datos
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis,
                 Gonzalo Daniel Cardozo, Thiago Dal Secco
    Fecha: 10/11/2026
    Descripción: Stored procedures ABM de la tabla Mundial.Idioma
                 (idiomas que habla cada árbitro; PK compuesta por
                 id_arbitro + idioma).
                 Todas las validaciones se acumulan y se informan en un
                 único mensaje por operación.
*/

/* Opciones ANSI obligatorias: el índice filtrado de Terna_Arbitral exige
   QUOTED_IDENTIFIER ON (también al crear los SP desde sqlcmd, que viene OFF). */
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

/* =============================================================
   ALTA de Idioma
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Idioma_Alta
    @id_arbitro INT,
    @idioma     NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_arbitro IS NULL
        SET @errores += N'id_arbitro es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_arbitro = @id_arbitro)
        SET @errores += N'id_arbitro no existe en Mundial.Arbitro. ';

    IF @idioma IS NULL
        SET @errores += N'idioma es obligatorio. ';
    ELSE
    BEGIN
        SET @idioma = LTRIM(RTRIM(@idioma));
        IF @idioma = N''
            SET @errores += N'idioma no puede estar vacío. ';
        IF LEN(@idioma) > 50
            SET @errores += N'idioma supera los 50 caracteres que admite la columna. ';
        IF EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_arbitro = @id_arbitro AND idioma = @idioma)
            SET @errores += N'El árbitro ya tiene registrado ese idioma. ';
    END

    IF @errores <> N''
        THROW 50901, @errores, 1;

    INSERT INTO Mundial.Idioma (id_arbitro, idioma)
    VALUES (@id_arbitro, @idioma);
END;
GO

/* =============================================================
   MODIFICACIÓN de Idioma
   Cambia el nombre del idioma de un par (árbitro, idioma) existente.
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Idioma_Modificar
    @id_arbitro    INT,
    @idioma        NVARCHAR(200),
    @idioma_nuevo  NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_arbitro IS NULL
        SET @errores += N'id_arbitro es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_arbitro = @id_arbitro)
        SET @errores += N'id_arbitro no existe en Mundial.Arbitro. ';

    IF @idioma IS NULL
        SET @errores += N'idioma es obligatorio. ';
    ELSE
    BEGIN
        SET @idioma = LTRIM(RTRIM(@idioma));
        IF @idioma = N''
            SET @errores += N'idioma no puede estar vacío. ';
        ELSE IF @id_arbitro IS NOT NULL
             AND NOT EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_arbitro = @id_arbitro AND idioma = @idioma)
            SET @errores += N'El árbitro no tiene registrado ese idioma. ';
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
        IF @id_arbitro IS NOT NULL
           AND EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_arbitro = @id_arbitro AND idioma = @idioma_nuevo)
           AND @idioma_nuevo <> @idioma
            SET @errores += N'El árbitro ya tiene registrado ese idioma. ';
    END

    IF @errores <> N''
        THROW 50902, @errores, 1;

    UPDATE Mundial.Idioma
    SET idioma = @idioma_nuevo
    WHERE id_arbitro = @id_arbitro
      AND idioma = @idioma;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50902, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

/* =============================================================
   BAJA de Idioma
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Idioma_Baja
    @id_arbitro INT,
    @idioma     NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_arbitro IS NULL
        SET @errores += N'id_arbitro es obligatorio. ';
    IF @idioma IS NULL
        SET @errores += N'idioma es obligatorio. ';
    ELSE
        SET @idioma = LTRIM(RTRIM(@idioma));

    IF @id_arbitro IS NOT NULL AND @idioma IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_arbitro = @id_arbitro AND idioma = @idioma)
        SET @errores += N'El árbitro no tiene registrado ese idioma. ';

    IF @errores <> N''
        THROW 50903, @errores, 1;

    DELETE FROM Mundial.Idioma
    WHERE id_arbitro = @id_arbitro
      AND idioma = @idioma;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50903, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO
