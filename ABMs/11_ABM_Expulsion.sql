/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Expulsion
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE Mundial.Expulsion_Alta
    @id_tarjeta INT,
    @tipoexpulsion VARCHAR(MAX),
    @id_expulsion INT = NULL OUTPUT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_tarjeta IS NULL
        SET @errores += N'id_tarjeta es obligatorio. ';

    IF @tipoexpulsion IS NULL
        SET @errores += N'tipoexpulsion es obligatorio. ';
    IF @tipoexpulsion IS NOT NULL AND @tipoexpulsion NOT IN ('Doble amarilla', 'Roja')
        SET @errores += N'tipoexpulsion debe ser uno de estos valores: Doble amarilla, Roja. ';
    IF DATALENGTH(@tipoexpulsion) > 20
        SET @errores += N'tipoexpulsion supera los 20 bytes que admite la columna. ';

    DECLARE @color_tarjeta VARCHAR(20);
    SELECT @color_tarjeta = color
    FROM Mundial.Tarjeta
    WHERE id_tarjeta = @id_tarjeta;

    IF @id_tarjeta IS NOT NULL AND @color_tarjeta IS NULL
        SET @errores += N'id_tarjeta no existe en Mundial.Tarjeta. ';

    IF EXISTS (SELECT 1 FROM Mundial.Expulsion WHERE id_tarjeta = @id_tarjeta)
        SET @errores += N'La tarjeta ya está vinculada a otra expulsión. ';

    IF (@tipoexpulsion = 'Roja' AND @color_tarjeta <> 'Roja')
       OR (@tipoexpulsion = 'Doble amarilla' AND @color_tarjeta <> 'Amarilla')
        SET @errores += N'El color de la tarjeta no corresponde al tipo de expulsión. ';

    IF @tipoexpulsion = 'Doble amarilla' AND @color_tarjeta = 'Amarilla'
       AND NOT EXISTS (
        SELECT 1
        FROM Mundial.Tarjeta AS aplicada
        JOIN Mundial.Tarjeta AS anterior
          ON anterior.id_partido = aplicada.id_partido
         AND anterior.id_jugador = aplicada.id_jugador
        WHERE aplicada.id_tarjeta = @id_tarjeta
          AND anterior.color = 'Amarilla'
          AND (anterior.minuto < aplicada.minuto OR
               (anterior.minuto = aplicada.minuto AND anterior.id_tarjeta < aplicada.id_tarjeta))
    )
        SET @errores += N'La doble amarilla requiere una amarilla previa del jugador en el mismo partido. ';

    IF @errores <> N''
        THROW 50401, @errores, 1;

    INSERT INTO Mundial.Expulsion (id_tarjeta, tipoexpulsion)
    SELECT @id_tarjeta, @tipoexpulsion
    WHERE EXISTS (
        SELECT 1
        FROM Mundial.Tarjeta AS aplicada WITH (HOLDLOCK)
        WHERE aplicada.id_tarjeta = @id_tarjeta
          AND aplicada.color = CASE WHEN @tipoexpulsion = 'Roja' THEN 'Roja' ELSE 'Amarilla' END
          AND (@tipoexpulsion = 'Roja' OR EXISTS (
              SELECT 1
              FROM Mundial.Tarjeta AS anterior WITH (HOLDLOCK)
              WHERE anterior.id_partido = aplicada.id_partido
                AND anterior.id_jugador = aplicada.id_jugador
                AND anterior.color = 'Amarilla'
                AND (anterior.minuto < aplicada.minuto OR
                     (anterior.minuto = aplicada.minuto AND anterior.id_tarjeta < aplicada.id_tarjeta))
          ))
    );

    DECLARE @filas_insertadas INT = @@ROWCOUNT, @error_sql INT = @@ERROR;
    IF @error_sql <> 0
        RETURN;
    IF @filas_insertadas = 0
        THROW 50401, N'Los datos relacionados cambiaron durante la operación. Volvé a intentar. ', 1;

    SET @id_expulsion = CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Expulsion_Modificar
    @id_expulsion INT,
    @id_tarjeta INT,
    @tipoexpulsion VARCHAR(MAX)
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_expulsion IS NULL
        SET @errores += N'id_expulsion es obligatorio. ';
    IF @id_expulsion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Mundial.Expulsion WHERE id_expulsion = @id_expulsion)
        SET @errores += N'id_expulsion no existe en Mundial.Expulsion. ';

    IF @id_tarjeta IS NULL
        SET @errores += N'id_tarjeta es obligatorio. ';

    IF @tipoexpulsion IS NULL
        SET @errores += N'tipoexpulsion es obligatorio. ';
    IF @tipoexpulsion IS NOT NULL AND @tipoexpulsion NOT IN ('Doble amarilla', 'Roja')
        SET @errores += N'tipoexpulsion debe ser uno de estos valores: Doble amarilla, Roja. ';
    IF DATALENGTH(@tipoexpulsion) > 20
        SET @errores += N'tipoexpulsion supera los 20 bytes que admite la columna. ';

    DECLARE @color_tarjeta VARCHAR(20);
    SELECT @color_tarjeta = color
    FROM Mundial.Tarjeta
    WHERE id_tarjeta = @id_tarjeta;

    IF @id_tarjeta IS NOT NULL AND @color_tarjeta IS NULL
        SET @errores += N'id_tarjeta no existe en Mundial.Tarjeta. ';

    IF EXISTS (SELECT 1 FROM Mundial.Expulsion WHERE id_tarjeta = @id_tarjeta AND id_expulsion <> @id_expulsion)
        SET @errores += N'La tarjeta ya está vinculada a otra expulsión. ';

    IF (@tipoexpulsion = 'Roja' AND @color_tarjeta <> 'Roja')
       OR (@tipoexpulsion = 'Doble amarilla' AND @color_tarjeta <> 'Amarilla')
        SET @errores += N'El color de la tarjeta no corresponde al tipo de expulsión. ';

    IF @tipoexpulsion = 'Doble amarilla' AND @color_tarjeta = 'Amarilla'
       AND NOT EXISTS (
        SELECT 1
        FROM Mundial.Tarjeta AS aplicada
        JOIN Mundial.Tarjeta AS anterior
          ON anterior.id_partido = aplicada.id_partido
         AND anterior.id_jugador = aplicada.id_jugador
        WHERE aplicada.id_tarjeta = @id_tarjeta
          AND anterior.color = 'Amarilla'
          AND (anterior.minuto < aplicada.minuto OR
               (anterior.minuto = aplicada.minuto AND anterior.id_tarjeta < aplicada.id_tarjeta))
    )
        SET @errores += N'La doble amarilla requiere una amarilla previa del jugador en el mismo partido. ';

    IF @errores <> N''
        THROW 50402, @errores, 1;

    UPDATE Mundial.Expulsion
    SET id_tarjeta = @id_tarjeta,
        tipoexpulsion = @tipoexpulsion
    WHERE id_expulsion = @id_expulsion 
      AND EXISTS (
        SELECT 1
        FROM Mundial.Tarjeta AS aplicada WITH (HOLDLOCK)
        WHERE aplicada.id_tarjeta = @id_tarjeta
          AND aplicada.color = CASE WHEN @tipoexpulsion = 'Roja' THEN 'Roja' ELSE 'Amarilla' END
          AND (@tipoexpulsion = 'Roja' OR EXISTS (
              SELECT 1
              FROM Mundial.Tarjeta AS anterior WITH (HOLDLOCK)
              WHERE anterior.id_partido = aplicada.id_partido
                AND anterior.id_jugador = aplicada.id_jugador
                AND anterior.color = 'Amarilla'
                AND (anterior.minuto < aplicada.minuto OR
                     (anterior.minuto = aplicada.minuto AND anterior.id_tarjeta < aplicada.id_tarjeta))
          ))
    );

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50402, N'Los datos relacionados cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Expulsion_Baja
    @id_expulsion INT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_expulsion IS NULL
        SET @errores += N'id_expulsion es obligatorio. ';
    IF @id_expulsion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Mundial.Expulsion WHERE id_expulsion = @id_expulsion)
        SET @errores += N'id_expulsion no existe en Mundial.Expulsion. ';

    IF @errores <> N''
        THROW 50403, @errores, 1;

    DELETE FROM Mundial.Expulsion WHERE id_expulsion = @id_expulsion;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50403, N'id_expulsion no existe en Mundial.Expulsion. ', 1;
END;
GO
