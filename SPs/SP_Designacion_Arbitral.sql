/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Práctico: Sistema de Registro y Gestión del Mundial de Fútbol
    Entrega 5 - Base de Datos
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis,
                 Gonzalo Daniel Cardozo, Thiago Dal Secco
    Fecha: 10/11/2026
    Descripción: Stored procedure de lógica de negocio del módulo de
                 árbitros: designación arbitral de un partido con
                 validación de conflicto de nacionalidad.

                 Regla de negocio (sección G de la consigna):
                   No se puede designar un árbitro cuyo país coincida con
                   alguno de los países de las selecciones que disputan el
                   partido. Si la designación propuesta tiene conflicto, se
                   registra igual como historial con estado = 'Descartada'
                   y el motivo, y se informa el rechazo al llamador.

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

CREATE OR ALTER PROCEDURE Mundial.Designacion_Arbitral_Asignar
    @id_partido           INT,
    @id_arbitro_principal INT,
    @id_asistente_1       INT,
    @id_asistente_2       INT,
    @id_cuarto_arbitro    INT,
    @id_arbitro_var       INT,
    @id_terna             INT           = NULL OUTPUT,
    @advertencia          NVARCHAR(400) = NULL OUTPUT
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
    DECLARE @fase         NVARCHAR(30);
    DECLARE @sel_local    INT;
    DECLARE @sel_visitante INT;

    /* ------------------------------------------------------------------
       1. Validaciones previas (se informan todas juntas en un mensaje)
       ------------------------------------------------------------------ */
    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    ELSE
        SELECT @fase = fase,
               @sel_local = id_seleccion_local,
               @sel_visitante = id_seleccion_visitante
        FROM Mundial.Partido
        WHERE id_partido = @id_partido;

    IF @id_partido IS NOT NULL AND @fase IS NULL
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

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

    DECLARE @roles_sin_id NVARCHAR(200);
    SELECT @roles_sin_id = STRING_AGG(rol, ', ') FROM @terna WHERE id_arbitro IS NULL;
    IF @roles_sin_id IS NOT NULL
        SET @errores += N'Falta el id de árbitro en: ' + @roles_sin_id + N'. ';

    DECLARE @roles_inexistentes NVARCHAR(200);
    SELECT @roles_inexistentes = STRING_AGG(t.rol, ', ')
    FROM @terna AS t
    WHERE t.id_arbitro IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Mundial.Arbitro AS a WHERE a.id_arbitro = t.id_arbitro);
    IF @roles_inexistentes IS NOT NULL
        SET @errores += N'El id de árbitro no existe en Mundial.Arbitro en: ' + @roles_inexistentes + N'. ';

    DECLARE @roles_inhabilitados NVARCHAR(200);
    SELECT @roles_inhabilitados = STRING_AGG(t.rol, ', ')
    FROM @terna AS t
    JOIN Mundial.Arbitro AS a ON a.id_arbitro = t.id_arbitro
    WHERE a.habilitado = 0;
    IF @roles_inhabilitados IS NOT NULL
        SET @errores += N'El árbitro está inhabilitado en: ' + @roles_inhabilitados + N'. ';

    IF (SELECT COUNT(DISTINCT id_arbitro) FROM @terna WHERE id_arbitro IS NOT NULL) < 5
        SET @errores += N'Los cinco árbitros de la terna deben ser distintos entre sí. ';

    IF @errores <> N''
        THROW 51010, @errores, 1;

    /* ------------------------------------------------------------------
       2. Conflicto de nacionalidad
       ------------------------------------------------------------------ */
    DECLARE @conflicto NVARCHAR(400);
    SELECT @conflicto = STRING_AGG(a.apellido, N', ')
    FROM @terna AS t
    JOIN Mundial.Arbitro AS a ON a.id_arbitro = t.id_arbitro
    WHERE a.id_pais IN (
        SELECT s.id_pais
        FROM Mundial.Seleccion AS s
        WHERE s.id_seleccion IN (@sel_local, @sel_visitante)
    );

    IF @conflicto IS NOT NULL
    BEGIN
        /* La designación se conserva como historial: se registra como
           descartada y recién después se informa el rechazo. */
        SET @conflicto = N'Conflicto de nacionalidad: árbitros del mismo país que una de las selecciones del partido: '
                         + @conflicto + N'.';

        BEGIN TRY
            BEGIN TRANSACTION;

                INSERT INTO Mundial.Terna_Arbitral
                    (id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
                     id_cuarto_arbitro, id_arbitro_var, estado, motivo_descarte)
                VALUES
                    (@id_partido, @id_arbitro_principal, @id_asistente_1, @id_asistente_2,
                     @id_cuarto_arbitro, @id_arbitro_var, N'Descartada', LEFT(@conflicto, 300));

                SET @id_terna = CONVERT(INT, SCOPE_IDENTITY());

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            THROW;
        END CATCH

        ;THROW 51011, @conflicto, 1;
    END

    /* ------------------------------------------------------------------
       3. Una sola terna activa por partido
       ------------------------------------------------------------------ */
    IF EXISTS (
        SELECT 1 FROM Mundial.Terna_Arbitral
        WHERE id_partido = @id_partido
          AND estado = N'Activa'
    )
        THROW 51012, N'El partido ya tiene una terna activa. Para cambiarla, primero se debe dar de baja. ', 1;

    /* ------------------------------------------------------------------
       4. Alta de la terna activa (dentro de una transacción)
       ------------------------------------------------------------------ */
    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO Mundial.Terna_Arbitral
                (id_partido, id_arbitro_principal, id_asistente_1, id_asistente_2,
                 id_cuarto_arbitro, id_arbitro_var, estado, motivo_descarte)
            VALUES
                (@id_partido, @id_arbitro_principal, @id_asistente_1, @id_asistente_2,
                 @id_cuarto_arbitro, @id_arbitro_var, N'Activa', NULL);

            SET @id_terna = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

    /* ------------------------------------------------------------------
       5. Advertencia desde dieciseisavos en adelante (no bloqueante)
          A partir de la fase eliminatoria, si un árbitro comparte país con
          una selección que sigue en competencia (y no es una de las dos
          que juegan este partido), puede llegar a cruzarse con ella.
       ------------------------------------------------------------------ */
    SET @advertencia = NULL;

    IF @fase IS NOT NULL AND @fase <> N'fasedegrupos'
       AND EXISTS (
            SELECT 1
            FROM @terna AS t
            JOIN Mundial.Arbitro AS a ON a.id_arbitro = t.id_arbitro
            WHERE EXISTS (
                SELECT 1
                FROM Mundial.Partido AS p2
                JOIN Mundial.Seleccion AS s2
                  ON s2.id_seleccion IN (p2.id_seleccion_local, p2.id_seleccion_visitante)
                WHERE p2.fase <> N'fasedegrupos'
                  AND s2.id_seleccion NOT IN (@sel_local, @sel_visitante)
                  AND s2.id_pais = a.id_pais
            )
       )
        SET @advertencia = N'Advertencia: hay árbitros que comparten país con selecciones que siguen en competencia; podrían cruzarse en una fase posterior. ';
END;
GO
