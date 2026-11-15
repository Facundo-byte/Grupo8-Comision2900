/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Práctico: Sistema de Registro y Gestión del Mundial de Fútbol
    Entrega 5 - Base de Datos
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis,
                 Gonzalo Daniel Cardozo, Thiago Dal Secco
    Fecha: 10/11/2026
    Descripción: Stored procedures ABM de la tabla Mundial.Sede.
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
   ALTA de Sede
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Sede_Alta
    @nombre_estadio NVARCHAR(400),
    @ciudad         NVARCHAR(400),
    @id_pais        INT,
    @capacidad      INT,
    @huso_horario   VARCHAR(20),
    @latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL,
    @id_sede        INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    /* --- nombre del estadio --- */
    IF @nombre_estadio IS NULL
        SET @errores += N'nombre_estadio es obligatorio. ';
    ELSE
    BEGIN
        SET @nombre_estadio = LTRIM(RTRIM(@nombre_estadio));
        IF @nombre_estadio = N''
            SET @errores += N'nombre_estadio no puede estar vacío. ';
        IF LEN(@nombre_estadio) > 100
            SET @errores += N'nombre_estadio supera los 100 caracteres que admite la columna. ';
    END

    /* --- ciudad --- */
    IF @ciudad IS NULL
        SET @errores += N'ciudad es obligatoria. ';
    ELSE
    BEGIN
        SET @ciudad = LTRIM(RTRIM(@ciudad));
        IF @ciudad = N''
            SET @errores += N'ciudad no puede estar vacía. ';
        IF LEN(@ciudad) > 100
            SET @errores += N'ciudad supera los 100 caracteres que admite la columna. ';
    END

    /* --- país --- */
    IF @id_pais IS NULL
        SET @errores += N'id_pais es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais)
        SET @errores += N'id_pais no existe en Mundial.Pais. ';

    /* --- capacidad --- */
    IF @capacidad IS NULL
        SET @errores += N'capacidad es obligatoria. ';
    ELSE IF @capacidad <= 0
        SET @errores += N'capacidad debe ser mayor a 0. ';
    ELSE IF @capacidad > 200000
        SET @errores += N'capacidad no puede superar los 200000 espectadores. ';

    /* --- huso horario (UTC±HH:MM) --- */
    IF @huso_horario IS NULL
        SET @errores += N'huso_horario es obligatorio. ';
    ELSE
    BEGIN
        SET @huso_horario = UPPER(LTRIM(RTRIM(@huso_horario)));
        IF @huso_horario NOT LIKE 'UTC[+-][0-1][0-9]:[0-5][0-9]'
           OR SUBSTRING(@huso_horario, 5, 2) > '14'
            SET @errores += N'huso_horario debe tener el formato UTC±HH:MM (por ejemplo UTC-03:00) y un desfase máximo de 14 horas. ';
    END

    /* --- geolocalización: las dos coordenadas o ninguna --- */
    IF (@latitud IS NULL AND @longitud IS NOT NULL)
       OR (@latitud IS NOT NULL AND @longitud IS NULL)
        SET @errores += N'latitud y longitud deben informarse juntas o ambas quedar vacías. ';
    IF @latitud IS NOT NULL AND (@latitud < -90 OR @latitud > 90)
        SET @errores += N'latitud debe estar entre -90 y 90. ';
    IF @longitud IS NOT NULL AND (@longitud < -180 OR @longitud > 180)
        SET @errores += N'longitud debe estar entre -180 y 180. ';

    /* --- duplicado --- */
    IF @nombre_estadio IS NOT NULL AND @ciudad IS NOT NULL AND @id_pais IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Sede
            WHERE nombre_estadio = @nombre_estadio
              AND ciudad = @ciudad
              AND id_pais = @id_pais
       )
        SET @errores += N'Ya existe una sede con ese estadio, ciudad y país. ';

    IF @errores <> N''
        THROW 50701, @errores, 1;

    INSERT INTO Mundial.Sede (nombre_estadio, ciudad, id_pais, capacidad, huso_horario, latitud, longitud)
    VALUES (@nombre_estadio, @ciudad, @id_pais, @capacidad, @huso_horario, @latitud, @longitud);

    SET @id_sede = CONVERT(INT, SCOPE_IDENTITY());
END;
GO

/* =============================================================
   MODIFICACIÓN de Sede
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Sede_Modificar
    @id_sede        INT,
    @nombre_estadio NVARCHAR(400),
    @ciudad         NVARCHAR(400),
    @id_pais        INT,
    @capacidad      INT,
    @huso_horario   VARCHAR(20),
    @latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_sede IS NULL
        SET @errores += N'id_sede es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Sede WHERE id_sede = @id_sede)
        SET @errores += N'id_sede no existe en Mundial.Sede. ';

    /* --- nombre del estadio --- */
    IF @nombre_estadio IS NULL
        SET @errores += N'nombre_estadio es obligatorio. ';
    ELSE
    BEGIN
        SET @nombre_estadio = LTRIM(RTRIM(@nombre_estadio));
        IF @nombre_estadio = N''
            SET @errores += N'nombre_estadio no puede estar vacío. ';
        IF LEN(@nombre_estadio) > 100
            SET @errores += N'nombre_estadio supera los 100 caracteres que admite la columna. ';
    END

    /* --- ciudad --- */
    IF @ciudad IS NULL
        SET @errores += N'ciudad es obligatoria. ';
    ELSE
    BEGIN
        SET @ciudad = LTRIM(RTRIM(@ciudad));
        IF @ciudad = N''
            SET @errores += N'ciudad no puede estar vacía. ';
        IF LEN(@ciudad) > 100
            SET @errores += N'ciudad supera los 100 caracteres que admite la columna. ';
    END

    /* --- país --- */
    IF @id_pais IS NULL
        SET @errores += N'id_pais es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais)
        SET @errores += N'id_pais no existe en Mundial.Pais. ';

    /* --- capacidad --- */
    IF @capacidad IS NULL
        SET @errores += N'capacidad es obligatoria. ';
    ELSE IF @capacidad <= 0
        SET @errores += N'capacidad debe ser mayor a 0. ';
    ELSE IF @capacidad > 200000
        SET @errores += N'capacidad no puede superar los 200000 espectadores. ';

    /* --- huso horario (UTC±HH:MM) --- */
    IF @huso_horario IS NULL
        SET @errores += N'huso_horario es obligatorio. ';
    ELSE
    BEGIN
        SET @huso_horario = UPPER(LTRIM(RTRIM(@huso_horario)));
        IF @huso_horario NOT LIKE 'UTC[+-][0-1][0-9]:[0-5][0-9]'
           OR SUBSTRING(@huso_horario, 5, 2) > '14'
            SET @errores += N'huso_horario debe tener el formato UTC±HH:MM (por ejemplo UTC-03:00) y un desfase máximo de 14 horas. ';
    END

    /* --- geolocalización: las dos coordenadas o ninguna --- */
    IF (@latitud IS NULL AND @longitud IS NOT NULL)
       OR (@latitud IS NOT NULL AND @longitud IS NULL)
        SET @errores += N'latitud y longitud deben informarse juntas o ambas quedar vacías. ';
    IF @latitud IS NOT NULL AND (@latitud < -90 OR @latitud > 90)
        SET @errores += N'latitud debe estar entre -90 y 90. ';
    IF @longitud IS NOT NULL AND (@longitud < -180 OR @longitud > 180)
        SET @errores += N'longitud debe estar entre -180 y 180. ';

    /* --- duplicado (excluyendo la propia sede) --- */
    IF @nombre_estadio IS NOT NULL AND @ciudad IS NOT NULL AND @id_pais IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Sede
            WHERE nombre_estadio = @nombre_estadio
              AND ciudad = @ciudad
              AND id_pais = @id_pais
              AND id_sede <> @id_sede
       )
        SET @errores += N'Ya existe otra sede con ese estadio, ciudad y país. ';

    IF @errores <> N''
        THROW 50702, @errores, 1;

    UPDATE Mundial.Sede
    SET nombre_estadio = @nombre_estadio,
        ciudad         = @ciudad,
        id_pais        = @id_pais,
        capacidad      = @capacidad,
        huso_horario   = @huso_horario,
        latitud        = @latitud,
        longitud       = @longitud
    WHERE id_sede = @id_sede;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50702, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

/* =============================================================
   BAJA de Sede
   No se permite si la sede ya tiene partidos o espacios
   publicitarios asociados (lo informa la FK).
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Sede_Baja
    @id_sede INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_sede IS NULL
        SET @errores += N'id_sede es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Sede WHERE id_sede = @id_sede)
        SET @errores += N'id_sede no existe en Mundial.Sede. ';

    IF @errores <> N''
        THROW 50703, @errores, 1;

    BEGIN TRY
        DELETE FROM Mundial.Sede
        WHERE id_sede = @id_sede;
    END TRY
    BEGIN CATCH
        /* 547 = conflicto con una FK: la sede tiene partidos o
           espacios publicitarios asociados. */
        IF ERROR_NUMBER() = 547
            THROW 50703, N'No se puede dar de baja: la sede tiene partidos o espacios publicitarios asociados. ', 1;
        THROW;
    END CATCH
END;
GO
