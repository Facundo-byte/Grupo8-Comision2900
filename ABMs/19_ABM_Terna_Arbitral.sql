/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Terna_Arbitral
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

CREATE OR ALTER PROCEDURE MfSPabm.Terna_Arbitral_Alta
    @id_partido           INT,
    @id_arbitro_principal INT,
    @id_asistente_1       INT,
    @id_asistente_2       INT,
    @id_cuarto_arbitro    INT,
    @id_arbitro_var       INT,
    @estado               VARCHAR(20) = 'Activa',
    @motivo_descarte      VARCHAR(300) = NULL,
    @id_terna             INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    -- 1) Partido
    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @errores += N'id_partido no existe en Mundial.Partido. ';
    ELSE IF EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_partido = @id_partido AND estado = 'Activa')
        SET @errores += N'El partido ya tiene una terna activa asignada. ';

    -- 2) Armo la terna de roles (roles EXACTOS del CHECK)
    DECLARE @terna TABLE (rol VARCHAR(30) NOT NULL, id_arbitro INT NULL);
    INSERT INTO @terna (rol, id_arbitro)
    VALUES (N'Principal',       @id_arbitro_principal),
           (N'Asistente 1',     @id_asistente_1),
           (N'Asistente 2',     @id_asistente_2),
           (N'Cuarto arbitro',  @id_cuarto_arbitro),
           (N'VAR',             @id_arbitro_var);

    -- 3) Faltantes
    DECLARE @roles_sin_id NVARCHAR(200);
    SELECT @roles_sin_id = STRING_AGG(rol, ', ') FROM @terna WHERE id_arbitro IS NULL;
    IF @roles_sin_id IS NOT NULL
        SET @errores += N'Falta el id de árbitro en: ' + @roles_sin_id + N'. ';

    -- 4) Inexistentes
    DECLARE @roles_inexistentes NVARCHAR(200);
    SELECT @roles_inexistentes = STRING_AGG(t.rol, ', ')
    FROM @terna t
    WHERE t.id_arbitro IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Mundial.Arbitro a WHERE a.id_arbitro = t.id_arbitro);
    IF @roles_inexistentes IS NOT NULL
        SET @errores += N'El id de árbitro no existe en Mundial.Arbitro en: ' + @roles_inexistentes + N'. ';

    -- 5) Inhabilitados
    DECLARE @roles_inhabilitados NVARCHAR(200);
    SELECT @roles_inhabilitados = STRING_AGG(t.rol, ', ')
    FROM @terna t
    JOIN Mundial.Arbitro a ON a.id_arbitro = t.id_arbitro
    WHERE a.habilitado = 0;
    IF @roles_inhabilitados IS NOT NULL
        SET @errores += N'El árbitro está inhabilitado en: ' + @roles_inhabilitados + N'. ';

    -- 6) Distintos entre sí
    IF (SELECT COUNT(DISTINCT id_arbitro) FROM @terna WHERE id_arbitro IS NOT NULL) < 5
        SET @errores += N'Los cinco árbitros de la terna deben ser distintos entre sí. ';

    -- 7) Estado
    IF @estado IS NULL
        SET @errores += N'estado es obligatorio. ';
    ELSE
    BEGIN
        SET @estado = LTRIM(RTRIM(@estado));
        IF @estado NOT IN ('Activa', 'Descartada')
            SET @errores += N'estado debe ser Activa o Descartada. ';
    END

    -- 8) Motivo descarte
    IF @estado = 'Descartada'
    BEGIN
        IF @motivo_descarte IS NULL OR LEN(LTRIM(RTRIM(@motivo_descarte))) = 0
            SET @errores += N'Una terna Descartada debe informar motivo_descarte. ';
        ELSE
        BEGIN
            SET @motivo_descarte = LTRIM(RTRIM(@motivo_descarte));
            IF LEN(@motivo_descarte) > 300
                SET @errores += N'motivo_descarte supera los 300 caracteres. ';
        END
    END
    ELSE IF @motivo_descarte IS NOT NULL
        SET @errores += N'motivo_descarte solo se informa cuando el estado es Descartada. ';

    -- 9) CONFLICTO DE NACIONALIDAD (Arbitro -> Partido)
    IF @id_partido IS NOT NULL
       AND EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
    BEGIN
        DECLARE @conflicto NVARCHAR(400);
        SELECT @conflicto = STRING_AGG(a.apellido + N' (' + t.rol + N')', ', ')
        FROM @terna t
        JOIN Mundial.Arbitro a ON a.id_arbitro = t.id_arbitro
        WHERE a.id_arbitro IS NOT NULL
          AND EXISTS (
              SELECT 1
              FROM Mundial.Partido p
              JOIN Mundial.Seleccion s
                  ON s.id_seleccion IN (p.id_seleccion_local, p.id_seleccion_visitante)
              WHERE p.id_partido = @id_partido
                AND s.id_pais = a.id_pais
          );
        IF @conflicto IS NOT NULL
            SET @errores += N'Conflicto de nacionalidad: árbitros del mismo país que una de las selecciones del partido: ' + @conflicto + N'. ';
    END

    IF @errores <> N''
        THROW 51001, @errores, 1;

    -- 10) Inserción transaccional: cabezal + 5 Arbitro_Terna
    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO Mundial.Terna_Arbitral (id_partido, estado, motivo_descarte)
            VALUES (@id_partido, @estado, @motivo_descarte);

            SET @id_terna = CONVERT(INT, SCOPE_IDENTITY());

            INSERT INTO Mundial.Arbitro_Terna (id_terna, id_arbitro, rol)
            VALUES (@id_terna, @id_arbitro_principal, 'Principal'),
                   (@id_terna, @id_asistente_1,       'Asistente 1'),
                   (@id_terna, @id_asistente_2,       'Asistente 2'),
                   (@id_terna, @id_cuarto_arbitro,    'Cuarto arbitro'),
                   (@id_terna, @id_arbitro_var,       'VAR');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE MfSPabm.Terna_Arbitral_Modificar
    @id_terna         INT,
    @estado           NVARCHAR(50),
    @motivo_descarte  NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    -- 1) Terna existe
    IF @id_terna IS NULL
        SET @errores += N'id_terna es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna)
        SET @errores += N'id_terna no existe en Mundial.Terna_Arbitral. ';

    -- 2) Estado
    IF @estado IS NULL
        SET @errores += N'estado es obligatorio. ';
    ELSE
    BEGIN
        SET @estado = LTRIM(RTRIM(@estado));
        IF @estado NOT IN (N'Activa', N'Descartada')
            SET @errores += N'estado debe ser Activa o Descartada. ';
    END

    -- 3) Motivo descarte
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

    -- 4) Si pasa a Activa, el partido no puede tener otra terna activa
    IF @estado = N'Activa' AND @id_terna IS NOT NULL
       AND EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna)
    BEGIN
        DECLARE @id_partido_mod INT;
        SELECT @id_partido_mod = id_partido FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna;
        IF EXISTS (
            SELECT 1 FROM Mundial.Terna_Arbitral
            WHERE id_partido = @id_partido_mod AND estado = N'Activa' AND id_terna <> @id_terna
        )
            SET @errores += N'El partido ya tiene otra terna activa. ';
    END

    IF @errores <> N''
        THROW 51002, @errores, 1;

    UPDATE Mundial.Terna_Arbitral
    SET estado          = @estado,
        motivo_descarte = @motivo_descarte
    WHERE id_terna = @id_terna;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 51002, N'Los datos cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

CREATE OR ALTER PROCEDURE MfSPabm.Terna_Arbitral_Baja
    @id_terna INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    -- 1) Terna existe
    IF @id_terna IS NULL
        SET @errores += N'id_terna es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna)
        SET @errores += N'id_terna no existe en Mundial.Terna_Arbitral. ';

    IF @errores <> N''
        THROW 51003, @errores, 1;

    -- 3) Borro primero los árbitros de la terna, después el cabezal
    BEGIN TRY
        BEGIN TRANSACTION;

            DELETE FROM Mundial.Arbitro_Terna WHERE id_terna = @id_terna;
            DELETE FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO