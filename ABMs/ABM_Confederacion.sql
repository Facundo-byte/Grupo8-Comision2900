/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Práctico: Sistema de Registro y Gestión del Mundial de Fútbol
    Entrega 5 - Base de Datos
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis,
                 Gonzalo Daniel Cardozo, Thiago Dal Secco
    Fecha: 10/11/2026
    Descripción: Stored procedures ABM de la tabla Mundial.Confederacion.
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
   ALTA de Confederacion
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Confederacion_Alta
    @nombre            NVARCHAR(400),
    @sigla             VARCHAR(50),
    @id_confederacion  INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    /* --- nombre --- */
    IF @nombre IS NULL
        SET @errores += N'nombre es obligatorio. ';
    ELSE
    BEGIN
        SET @nombre = LTRIM(RTRIM(@nombre));
        IF @nombre = N''
            SET @errores += N'nombre no puede estar vacío. ';
        IF LEN(@nombre) > 60
            SET @errores += N'nombre supera los 60 caracteres que admite la columna. ';
        IF EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE nombre = @nombre)
            SET @errores += N'Ya existe una confederación con ese nombre. ';
    END

    /* --- sigla --- */
    IF @sigla IS NULL
        SET @errores += N'sigla es obligatoria. ';
    ELSE
    BEGIN
        SET @sigla = UPPER(LTRIM(RTRIM(@sigla)));
        IF @sigla = ''
            SET @errores += N'sigla no puede estar vacía. ';
        IF LEN(@sigla) > 10
            SET @errores += N'sigla supera los 10 caracteres que admite la columna. ';
        ELSE IF LEN(@sigla) < 2
            SET @errores += N'sigla debe tener al menos 2 caracteres. ';
        IF @sigla LIKE '%[^A-Z]%'
            SET @errores += N'sigla solo admite letras de la A a la Z (sin espacios, números ni símbolos). ';
        IF EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE sigla = @sigla)
            SET @errores += N'Ya existe una confederación con esa sigla. ';
    END

    IF @errores <> N''
        THROW 50601, @errores, 1;

    INSERT INTO Mundial.Confederacion (nombre, sigla)
    VALUES (@nombre, @sigla);

    SET @id_confederacion = CONVERT(INT, SCOPE_IDENTITY());
END;
GO

/* =============================================================
   MODIFICACIÓN de Confederacion
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Confederacion_Modificar
    @id_confederacion INT,
    @nombre            NVARCHAR(400),
    @sigla             VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_confederacion IS NULL
        SET @errores += N'id_confederacion es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE id_confederacion = @id_confederacion)
        SET @errores += N'id_confederacion no existe en Mundial.Confederacion. ';

    /* --- nombre --- */
    IF @nombre IS NULL
        SET @errores += N'nombre es obligatorio. ';
    ELSE
    BEGIN
        SET @nombre = LTRIM(RTRIM(@nombre));
        IF @nombre = N''
            SET @errores += N'nombre no puede estar vacío. ';
        IF LEN(@nombre) > 60
            SET @errores += N'nombre supera los 60 caracteres que admite la columna. ';
        IF EXISTS (
            SELECT 1 FROM Mundial.Confederacion
            WHERE nombre = @nombre
              AND id_confederacion <> @id_confederacion
        )
            SET @errores += N'Ya existe otra confederación con ese nombre. ';
    END

    /* --- sigla --- */
    IF @sigla IS NULL
        SET @errores += N'sigla es obligatoria. ';
    ELSE
    BEGIN
        SET @sigla = UPPER(LTRIM(RTRIM(@sigla)));
        IF @sigla = ''
            SET @errores += N'sigla no puede estar vacía. ';
        IF LEN(@sigla) > 10
            SET @errores += N'sigla supera los 10 caracteres que admite la columna. ';
        ELSE IF LEN(@sigla) < 2
            SET @errores += N'sigla debe tener al menos 2 caracteres. ';
        IF @sigla LIKE '%[^A-Z]%'
            SET @errores += N'sigla solo admite letras de la A a la Z (sin espacios, números ni símbolos). ';
        IF EXISTS (
            SELECT 1 FROM Mundial.Confederacion
            WHERE sigla = @sigla
              AND id_confederacion <> @id_confederacion
        )
            SET @errores += N'Ya existe otra confederación con esa sigla. ';
    END

    IF @errores <> N''
        THROW 50602, @errores, 1;

    UPDATE Mundial.Confederacion
    SET nombre = @nombre,
        sigla  = @sigla
    WHERE id_confederacion = @id_confederacion;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50602, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

/* =============================================================
   BAJA de Confederacion
   No se permite si tiene árbitros (u otras tablas) asociados:
   la FK lo impide y se informa con un mensaje claro.
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Confederacion_Baja
    @id_confederacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_confederacion IS NULL
        SET @errores += N'id_confederacion es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE id_confederacion = @id_confederacion)
        SET @errores += N'id_confederacion no existe en Mundial.Confederacion. ';
    ELSE IF EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_confederacion = @id_confederacion)
        SET @errores += N'No se puede dar de baja: la confederación tiene árbitros asociados. ';

    IF @errores <> N''
        THROW 50603, @errores, 1;

    BEGIN TRY
        DELETE FROM Mundial.Confederacion
        WHERE id_confederacion = @id_confederacion;
    END TRY
    BEGIN CATCH
        /* 547 = conflicto con una FK: alguna otra tabla (por ejemplo,
           Seleccion) referencia esta confederación. */
        IF ERROR_NUMBER() = 547
            THROW 50603, N'No se puede dar de baja: la confederación tiene registros asociados en otras tablas (selecciones u otros). ', 1;
        THROW;
    END CATCH
END;
GO
