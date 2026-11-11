/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Práctico: Sistema de Registro y Gestión del Mundial de Fútbol
    Entrega 5 - Base de Datos
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis,
                 Gonzalo Daniel Cardozo, Thiago Dal Secco
    Fecha: 10/11/2026
    Descripción: Stored procedures ABM de la tabla Mundial.Terna_Arbitral
                 (designación arbitral de un partido: principal, dos
                 asistentes, cuarto árbitro y árbitro de VAR).
                 Todas las validaciones se acumulan y se informan en un
                 único mensaje por operación.
                 Requiere que existan Mundial.Partido y Mundial.Seleccion
                 (Integrantes 2 y 1 respectivamente).
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
   ALTA de Terna_Arbitral
   Reglas:
     - Los 5 árbitros deben existir, estar habilitados y ser distintos.
     - Una terna 'Activa' no puede tener árbitros del país de alguna de
       las selecciones que disputan el partido (conflicto de nacionalidad).
     - Solo puede haber una terna 'Activa' por partido.
     - Una terna 'Descartada' exige motivo y no compite por la unicidad
       (es historial).
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Terna_Arbitral_Alta
    @id_partido           INT,
    @id_arbitro_principal INT,
    @id_asistente_1       INT,
    @id_asistente_2       INT,
    @id_cuarto_arbitro    INT,
    @id_arbitro_var       INT,
    @estado               NVARCHAR(50) = N'Activa',
    @motivo_descarte      NVARCHAR(400) = NULL,
    @id_terna             INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET QUOTED_IDENTIFIER ON;
    SET NUMERIC_ROUNDABORT OFF;

    DECLARE @errores NVARCHAR(2048) = N'';

    DECLARE @terna TABLE
    (
        rol        VARCHAR(20) NOT NULL,
        id_arbitro INT         NULL
    );
    INSERT INTO @terna (rol, id_arbitro)
    VALUES (N'principal',  @id_arbitro_principal),
           (N'asistente_1', @id_asistente_1),
           (N'asistente_2', @id_asistente_2),
           (N'cuarto_arbitro', @id_cuarto_arbitro),
           (N'arbitro_var', @id_arbitro_var);

    /* --- partido --- */
    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    /* --- árbitros informados --- */
    DECLARE @roles_sin_id NVARCHAR(200);
    SELECT @roles_sin_id = STRING_AGG(rol, ', ') FROM @terna WHERE id_arbitro IS NULL;
    IF @roles_sin_id IS NOT NULL
        SET @errores += N'Falta el id de árbitro en: ' + @roles_sin_id + N'. ';

    /* --- árbitros existentes --- */
    DECLARE @roles_inexistentes NVARCHAR(200);
    SELECT @roles_inexistentes = STRING_AGG(t.rol, ', ')
    FROM @terna AS t
    WHERE t.id_arbitro IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Mundial.Arbitro AS a WHERE a.id_arbitro = t.id_arbitro);
    IF @roles_inexistentes IS NOT NULL
        SET @errores += N'El id de árbitro no existe en Mundial.Arbitro en: ' + @roles_inexistentes + N'. ';

    /* --- árbitros habilitados --- */
    DECLARE @roles_inhabilitados NVARCHAR(200);
    SELECT @roles_inhabilitados = STRING_AGG(t.rol, ', ')
    FROM @terna AS t
    JOIN Mundial.Arbitro AS a ON a.id_arbitro = t.id_arbitro
    WHERE a.habilitado = 0;
    IF @roles_inhabilitados IS NOT NULL
        SET @errores += N'El árbitro está inhabilitado en: ' + @roles_inhabilitados + N'. ';

    /* --- 5 árbitros distintos --- */
    IF (SELECT COUNT(DISTINCT id_arbitro) FROM @terna WHERE id_arbitro IS NOT NULL) < 5
        SET @errores += N'Los cinco árbitros de la terna deben ser distintos entre sí. ';

    /* --- estado y motivo --- */
    IF @estado IS NULL
        SET @errores += N'estado es obligatorio. ';
    ELSE
    BEGIN
        SET @estado = LTRIM(RTRIM(@estado));
        IF @estado NOT IN (N'Activa', N'Descartada')
            SET @errores += N'estado debe ser Activa o Descartada. ';
    END

    IF @estado = N'Descartada'
    BEGIN
        IF @motivo_descarte IS NULL OR LEN(LTRIM(RTRIM(@motivo_descarte))) = 0
            SET @errores += N'Una terna Descartada debe informar motivo_descarte. ';
        ELSE
        BEGIN
            SET @motivo_descarte = LTRIM(RTRIM(@motivo_descarte));
            IF LEN(@motivo_descarte) > 300
                SET @errores += N'motivo_descarte supera los 300 caracteres que admite la columna. ';
        END
    END
    ELSE IF @motivo_descarte IS NOT NULL
        SET @errores += N'motivo_descarte solo se informa cuando el estado es Descartada. ';

    /* --- una sola terna activa por partido --- */
    IF @estado = N'Activa' AND @id_partido IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Terna_Arbitral
            WHERE id_partido = @id_partido
              AND estado = N'Activa'
       )
        SET @errores += N'El partido ya tiene una terna activa. ';

    /* --- conflicto de nacionalidad (sólo bloquea la terna activa) --- */
    IF @estado = N'Activa' AND @id_partido IS NOT NULL
    BEGIN
        DECLARE @conflicto NVARCHAR(400);
        SELECT @conflicto = STRING_AGG(a.apellido, N', ')
        FROM @terna AS t
        JOIN Mundial.Arbitro AS a ON a.id_arbitro = t.id_arbitro
        WHERE EXISTS (
            SELECT 1
            FROM Mundial.Partido AS p
            JOIN Mundial.Seleccion AS s
              ON s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
            WHERE p.id_partido = @id_partido
              AND s.id_pais = a.id_pais
        );
        IF @conflicto IS NOT NULL
            SET @errores += N'Conflicto de nacionalidad: árbitros del mismo país que una de las selecciones del partido: ' + @conflicto + N'. ';
    END

    IF @errores <> N''
        THROW 51001, @errores, 1;

    INSERT INTO Mundial.Terna_Arbitral
        (id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
         id_cuarto_arbitro, id_arbitro_var, estado, motivo_descarte)
    VALUES
        (@id_partido, @id_arbitro_principal, @id_asistente_1, @id_asistente_2,
         @id_cuarto_arbitro, @id_arbitro_var, @estado, @motivo_descarte);

    SET @id_terna = CONVERT(INT, SCOPE_IDENTITY());
END;
GO

/* =============================================================
   MODIFICACIÓN de Terna_Arbitral
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Terna_Arbitral_Modificar
    @id_terna             INT,
    @id_partido           INT,
    @id_arbitro_principal INT,
    @id_asistente_1       INT,
    @id_asistente_2       INT,
    @id_cuarto_arbitro    INT,
    @id_arbitro_var       INT,
    @estado               NVARCHAR(50),
    @motivo_descarte      NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET QUOTED_IDENTIFIER ON;
    SET NUMERIC_ROUNDABORT OFF;

    DECLARE @errores NVARCHAR(2048) = N'';

    DECLARE @terna TABLE
    (
        rol        VARCHAR(20) NOT NULL,
        id_arbitro INT         NULL
    );
    INSERT INTO @terna (rol, id_arbitro)
    VALUES (N'principal',  @id_arbitro_principal),
           (N'asistente_1', @id_asistente_1),
           (N'asistente_2', @id_asistente_2),
           (N'cuarto_arbitro', @id_cuarto_arbitro),
           (N'arbitro_var', @id_arbitro_var);

    IF @id_terna IS NULL
        SET @errores += N'id_terna es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna)
        SET @errores += N'id_terna no existe en Mundial.Terna_Arbitral. ';

    /* --- partido --- */
    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    /* --- árbitros informados --- */
    DECLARE @roles_sin_id NVARCHAR(200);
    SELECT @roles_sin_id = STRING_AGG(rol, ', ') FROM @terna WHERE id_arbitro IS NULL;
    IF @roles_sin_id IS NOT NULL
        SET @errores += N'Falta el id de árbitro en: ' + @roles_sin_id + N'. ';

    /* --- árbitros existentes --- */
    DECLARE @roles_inexistentes NVARCHAR(200);
    SELECT @roles_inexistentes = STRING_AGG(t.rol, ', ')
    FROM @terna AS t
    WHERE t.id_arbitro IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Mundial.Arbitro AS a WHERE a.id_arbitro = t.id_arbitro);
    IF @roles_inexistentes IS NOT NULL
        SET @errores += N'El id de árbitro no existe en Mundial.Arbitro en: ' + @roles_inexistentes + N'. ';

    /* --- árbitros habilitados --- */
    DECLARE @roles_inhabilitados NVARCHAR(200);
    SELECT @roles_inhabilitados = STRING_AGG(t.rol, ', ')
    FROM @terna AS t
    JOIN Mundial.Arbitro AS a ON a.id_arbitro = t.id_arbitro
    WHERE a.habilitado = 0;
    IF @roles_inhabilitados IS NOT NULL
        SET @errores += N'El árbitro está inhabilitado en: ' + @roles_inhabilitados + N'. ';

    /* --- 5 árbitros distintos --- */
    IF (SELECT COUNT(DISTINCT id_arbitro) FROM @terna WHERE id_arbitro IS NOT NULL) < 5
        SET @errores += N'Los cinco árbitros de la terna deben ser distintos entre sí. ';

    /* --- estado y motivo --- */
    IF @estado IS NULL
        SET @errores += N'estado es obligatorio. ';
    ELSE
    BEGIN
        SET @estado = LTRIM(RTRIM(@estado));
        IF @estado NOT IN (N'Activa', N'Descartada')
            SET @errores += N'estado debe ser Activa o Descartada. ';
    END

    IF @estado = N'Descartada'
    BEGIN
        IF @motivo_descarte IS NULL OR LEN(LTRIM(RTRIM(@motivo_descarte))) = 0
            SET @errores += N'Una terna Descartada debe informar motivo_descarte. ';
        ELSE
        BEGIN
            SET @motivo_descarte = LTRIM(RTRIM(@motivo_descarte));
            IF LEN(@motivo_descarte) > 300
                SET @errores += N'motivo_descarte supera los 300 caracteres que admite la columna. ';
        END
    END
    ELSE IF @motivo_descarte IS NOT NULL
        SET @errores += N'motivo_descarte solo se informa cuando el estado es Descartada. ';

    /* --- una sola terna activa por partido (excluyendo la propia) --- */
    IF @estado = N'Activa' AND @id_partido IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM Mundial.Terna_Arbitral
            WHERE id_partido = @id_partido
              AND estado = N'Activa'
              AND id_terna <> @id_terna
       )
        SET @errores += N'El partido ya tiene otra terna activa. ';

    /* --- conflicto de nacionalidad (sólo bloquea la terna activa) --- */
    IF @estado = N'Activa' AND @id_partido IS NOT NULL
    BEGIN
        DECLARE @conflicto NVARCHAR(400);
        SELECT @conflicto = STRING_AGG(a.apellido, N', ')
        FROM @terna AS t
        JOIN Mundial.Arbitro AS a ON a.id_arbitro = t.id_arbitro
        WHERE EXISTS (
            SELECT 1
            FROM Mundial.Partido AS p
            JOIN Mundial.Seleccion AS s
              ON s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
            WHERE p.id_partido = @id_partido
              AND s.id_pais = a.id_pais
        );
        IF @conflicto IS NOT NULL
            SET @errores += N'Conflicto de nacionalidad: árbitros del mismo país que una de las selecciones del partido: ' + @conflicto + N'. ';
    END

    IF @errores <> N''
        THROW 51002, @errores, 1;

    UPDATE Mundial.Terna_Arbitral
    SET id_partido           = @id_partido,
        id_arbitro_principal = @id_arbitro_principal,
        id_asistente_1       = @id_asistente_1,
        id_asistente_2       = @id_asistente_2,
        id_cuarto_arbitro    = @id_cuarto_arbitro,
        id_arbitro_var       = @id_arbitro_var,
        estado               = @estado,
        motivo_descarte      = @motivo_descarte
    WHERE id_terna = @id_terna;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 51002, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

/* =============================================================
   BAJA de Terna_Arbitral
   ============================================================= */
CREATE OR ALTER PROCEDURE Mundial.Terna_Arbitral_Baja
    @id_terna INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET QUOTED_IDENTIFIER ON;
    SET NUMERIC_ROUNDABORT OFF;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_terna IS NULL
        SET @errores += N'id_terna es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna)
        SET @errores += N'id_terna no existe en Mundial.Terna_Arbitral. ';

    IF @errores <> N''
        THROW 51003, @errores, 1;

    DELETE FROM Mundial.Terna_Arbitral
    WHERE id_terna = @id_terna;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 51003, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO
