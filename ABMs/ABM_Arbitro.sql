/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Práctico: Sistema de Registro y Gestión del Mundial de Fútbol
    Entrega 5 - Base de Datos
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis,
                 Gonzalo Daniel Cardozo, Thiago Dal Secco
    Fecha: 10/11/2026
    Descripción: Stored procedures ABM de la tabla Mundial.Arbitro.
                 Todas las validaciones se acumulan y se informan en un
                 único mensaje por operación.
                 Requiere que exista Mundial.Pais (Integrante 1).
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
   ALTA de Arbitro
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Arbitro_Alta
    @nombre           NVARCHAR(200),
    @apellido         NVARCHAR(200),
    @fecha_nacimiento DATE,
    @id_pais          INT,
    @id_confederacion INT,
    @categoria        NVARCHAR(50),
    @habilitado       BIT = 1,
    @id_arbitro       INT = NULL OUTPUT
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
        IF LEN(@nombre) > 50
            SET @errores += N'nombre supera los 50 caracteres que admite la columna. ';
    END

    /* --- apellido --- */
    IF @apellido IS NULL
        SET @errores += N'apellido es obligatorio. ';
    ELSE
    BEGIN
        SET @apellido = LTRIM(RTRIM(@apellido));
        IF @apellido = N''
            SET @errores += N'apellido no puede estar vacío. ';
        IF LEN(@apellido) > 50
            SET @errores += N'apellido supera los 50 caracteres que admite la columna. ';
    END

    /* --- fecha de nacimiento --- */
    IF @fecha_nacimiento IS NULL
        SET @errores += N'fecha_nacimiento es obligatoria. ';
    ELSE
    BEGIN
        IF @fecha_nacimiento > CAST(GETDATE() AS DATE)
            SET @errores += N'fecha_nacimiento no puede ser futura. ';
        ELSE IF @fecha_nacimiento < '19000101'
            SET @errores += N'fecha_nacimiento no puede ser anterior al 01/01/1900. ';
        ELSE IF DATEADD(YEAR, 18, @fecha_nacimiento) > CAST(GETDATE() AS DATE)
            SET @errores += N'El árbitro debe ser mayor de 18 años. ';
    END

    /* --- país y confederación --- */
    IF @id_pais IS NULL
        SET @errores += N'id_pais es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais)
        SET @errores += N'id_pais no existe en Mundial.Pais. ';

    IF @id_confederacion IS NULL
        SET @errores += N'id_confederacion es obligatoria. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE id_confederacion = @id_confederacion)
        SET @errores += N'id_confederacion no existe en Mundial.Confederacion. ';

    /* --- categoría --- */
    IF @categoria IS NULL
        SET @errores += N'categoria es obligatoria. ';
    ELSE
    BEGIN
        SET @categoria = UPPER(LTRIM(RTRIM(@categoria)));
        IF @categoria NOT IN (N'FIFA', N'CONFEDERACION')
            SET @errores += N'categoria debe ser FIFA o CONFEDERACION. ';
    END

    /* --- habilitado --- */
    IF @habilitado IS NULL
        SET @errores += N'habilitado es obligatorio (1 = habilitado, 0 = inhabilitado). ';

    /* --- duplicado --- */
    IF @nombre IS NOT NULL AND @apellido IS NOT NULL
       AND @fecha_nacimiento IS NOT NULL AND @id_pais IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Arbitro
            WHERE nombre = @nombre
              AND apellido = @apellido
              AND fecha_nacimiento = @fecha_nacimiento
              AND id_pais = @id_pais
       )
        SET @errores += N'Ya existe un árbitro con ese nombre, apellido, fecha de nacimiento y país. ';

    IF @errores <> N''
        THROW 50801, @errores, 1;

    INSERT INTO Mundial.Arbitro (nombre, apellido, fecha_nacimiento, id_pais, id_confederacion, categoria, habilitado)
    VALUES (@nombre, @apellido, @fecha_nacimiento, @id_pais, @id_confederacion, @categoria, @habilitado);

    SET @id_arbitro = CONVERT(INT, SCOPE_IDENTITY());
END;
GO

/* =============================================================
   MODIFICACIÓN de Arbitro
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Arbitro_Modificar
    @id_arbitro       INT,
    @nombre           NVARCHAR(200),
    @apellido         NVARCHAR(200),
    @fecha_nacimiento DATE,
    @id_pais          INT,
    @id_confederacion INT,
    @categoria        NVARCHAR(50),
    @habilitado       BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_arbitro IS NULL
        SET @errores += N'id_arbitro es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_arbitro = @id_arbitro)
        SET @errores += N'id_arbitro no existe en Mundial.Arbitro. ';

    /* --- nombre --- */
    IF @nombre IS NULL
        SET @errores += N'nombre es obligatorio. ';
    ELSE
    BEGIN
        SET @nombre = LTRIM(RTRIM(@nombre));
        IF @nombre = N''
            SET @errores += N'nombre no puede estar vacío. ';
        IF LEN(@nombre) > 50
            SET @errores += N'nombre supera los 50 caracteres que admite la columna. ';
    END

    /* --- apellido --- */
    IF @apellido IS NULL
        SET @errores += N'apellido es obligatorio. ';
    ELSE
    BEGIN
        SET @apellido = LTRIM(RTRIM(@apellido));
        IF @apellido = N''
            SET @errores += N'apellido no puede estar vacío. ';
        IF LEN(@apellido) > 50
            SET @errores += N'apellido supera los 50 caracteres que admite la columna. ';
    END

    /* --- fecha de nacimiento --- */
    IF @fecha_nacimiento IS NULL
        SET @errores += N'fecha_nacimiento es obligatoria. ';
    ELSE
    BEGIN
        IF @fecha_nacimiento > CAST(GETDATE() AS DATE)
            SET @errores += N'fecha_nacimiento no puede ser futura. ';
        ELSE IF @fecha_nacimiento < '19000101'
            SET @errores += N'fecha_nacimiento no puede ser anterior al 01/01/1900. ';
        ELSE IF DATEADD(YEAR, 18, @fecha_nacimiento) > CAST(GETDATE() AS DATE)
            SET @errores += N'El árbitro debe ser mayor de 18 años. ';
    END

    /* --- país y confederación --- */
    IF @id_pais IS NULL
        SET @errores += N'id_pais es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais)
        SET @errores += N'id_pais no existe en Mundial.Pais. ';

    IF @id_confederacion IS NULL
        SET @errores += N'id_confederacion es obligatoria. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Confederacion WHERE id_confederacion = @id_confederacion)
        SET @errores += N'id_confederacion no existe en Mundial.Confederacion. ';

    /* --- categoría --- */
    IF @categoria IS NULL
        SET @errores += N'categoria es obligatoria. ';
    ELSE
    BEGIN
        SET @categoria = UPPER(LTRIM(RTRIM(@categoria)));
        IF @categoria NOT IN (N'FIFA', N'CONFEDERACION')
            SET @errores += N'categoria debe ser FIFA o CONFEDERACION. ';
    END

    /* --- habilitado --- */
    IF @habilitado IS NULL
        SET @errores += N'habilitado es obligatorio (1 = habilitado, 0 = inhabilitado). ';
    ELSE IF @habilitado = 0
        AND EXISTS (
            SELECT 1 FROM Mundial.Terna_Arbitral
            WHERE estado = N'Activa'
              AND @id_arbitro IN (id_arbitro_principal, id_asistente_1, id_asistente_2,
                                  id_cuarto_arbitro, id_arbitro_var)
        )
        SET @errores += N'No se puede inhabilitar al árbitro: tiene ternas activas asignadas. ';

    /* --- duplicado (excluyendo el propio árbitro) --- */
    IF @nombre IS NOT NULL AND @apellido IS NOT NULL
       AND @fecha_nacimiento IS NOT NULL AND @id_pais IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Arbitro
            WHERE nombre = @nombre
              AND apellido = @apellido
              AND fecha_nacimiento = @fecha_nacimiento
              AND id_pais = @id_pais
              AND id_arbitro <> @id_arbitro
       )
        SET @errores += N'Ya existe otro árbitro con ese nombre, apellido, fecha de nacimiento y país. ';

    IF @errores <> N''
        THROW 50802, @errores, 1;

    UPDATE Mundial.Arbitro
    SET nombre           = @nombre,
        apellido         = @apellido,
        fecha_nacimiento = @fecha_nacimiento,
        id_pais          = @id_pais,
        id_confederacion = @id_confederacion,
        categoria        = @categoria,
        habilitado       = @habilitado
    WHERE id_arbitro = @id_arbitro;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50802, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

/* =============================================================
   BAJA de Arbitro
   Se eliminan en la misma transacción sus idiomas (Idioma es una
   tabla dependiente). No se permite si tiene ternas asignadas.
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Arbitro_Baja
    @id_arbitro INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_arbitro IS NULL
        SET @errores += N'id_arbitro es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_arbitro = @id_arbitro)
        SET @errores += N'id_arbitro no existe en Mundial.Arbitro. ';
    ELSE IF EXISTS (
        SELECT 1 FROM Mundial.Terna_Arbitral
        WHERE @id_arbitro IN (id_arbitro_principal, id_asistente_1, id_asistente_2,
                              id_cuarto_arbitro, id_arbitro_var)
    )
        SET @errores += N'No se puede dar de baja: el árbitro tiene ternas asignadas. ';

    IF @errores <> N''
        THROW 50803, @errores, 1;

    BEGIN TRY
        BEGIN TRANSACTION;

            DELETE FROM Mundial.Idioma
            WHERE id_arbitro = @id_arbitro;

            DELETE FROM Mundial.Arbitro
            WHERE id_arbitro = @id_arbitro;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
