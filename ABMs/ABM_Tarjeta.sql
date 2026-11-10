/*
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
	Descripcion: Store Procedures ABM de la Tabla Tarjeta
*/

CREATE OR ALTER PROCEDURE Mundial.Tarjeta_Alta
    @id_partido INT,
    @id_jugador INT,
    @minuto INT,
    @motivo VARCHAR(MAX) = NULL,
    @color VARCHAR(MAX),
    @id_tarjeta INT = NULL OUTPUT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
    )
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    IF @id_jugador IS NULL
        SET @errores += N'id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador
    )
        SET @errores += N'id_jugador no existe en Mundial.Jugador. ';

    IF @minuto IS NULL
        SET @errores += N'minuto es obligatorio. ';
    IF @minuto < 0
        SET @errores += N'minuto debe ser mayor o igual a cero. ';

    IF DATALENGTH(@motivo) > 100
        SET @errores += N'motivo supera los 100 bytes que admite la columna. ';

    IF @color IS NULL
        SET @errores += N'color es obligatorio. ';
    IF @color IS NOT NULL AND @color NOT IN ('Roja', 'Amarilla')
        SET @errores += N'color debe ser uno de estos valores: Roja, Amarilla. ';
    IF DATALENGTH(@color) > 20
        SET @errores += N'color supera los 20 bytes que admite la columna. ';

    IF @errores <> N''
        THROW 50301, @errores, 1;

    INSERT INTO Mundial.Tarjeta
        (id_partido, id_jugador, minuto, motivo, color)
    VALUES
        (@id_partido, @id_jugador, @minuto, @motivo, @color);

    IF @@ROWCOUNT = 1
        SET @id_tarjeta = CONVERT(INT, SCOPE_IDENTITY()); -- Devuelve el id de la tarjeta que se creo
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Tarjeta_Modificar
    @id_tarjeta INT,
    @id_partido INT,
    @id_jugador INT,
    @minuto INT,
    @motivo VARCHAR(MAX) = NULL,
    @color VARCHAR(MAX)
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_tarjeta IS NULL
        SET @errores += N'id_tarjeta es obligatorio. ';
    IF @id_tarjeta IS NOT NULL AND NOT EXISTS ( -- Si no encuentra una tarjeta con ese id
        SELECT 1 FROM Mundial.Tarjeta
        WHERE id_tarjeta = @id_tarjeta
    )
        SET @errores += N'id_tarjeta no existe en Mundial.Tarjeta. ';

    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
    )
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    IF @id_jugador IS NULL
        SET @errores += N'id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador
    )
        SET @errores += N'id_jugador no existe en Mundial.Jugador. ';

    IF @minuto IS NULL
        SET @errores += N'minuto es obligatorio. ';
    IF @minuto < 0
        SET @errores += N'minuto debe ser mayor o igual a cero. ';

    IF DATALENGTH(@motivo) > 100
        SET @errores += N'motivo supera los 100 bytes que admite la columna. ';

    IF @color IS NULL
        SET @errores += N'color es obligatorio. ';
    IF @color IS NOT NULL AND @color NOT IN ('Roja', 'Amarilla')
        SET @errores += N'color debe ser uno de estos valores: Roja, Amarilla. ';
    IF DATALENGTH(@color) > 20
        SET @errores += N'color supera los 20 bytes que admite la columna. ';

    IF @errores <> N''
        THROW 50302, @errores, 1;

	IF @errores <> N''
    THROW 50102, @errores, 1;

	UPDATE Mundial.Tarjeta -- Actualizo la tarjeta
	SET id_partido = @id_partido,
		id_jugador = @id_jugador,
		minuto = @minuto,
		motivo = @motivo,
		color = @color
	WHERE id_tarjeta = @id_tarjeta;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50302, N'Los datos relacionados cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Tarjeta_Baja
    @id_tarjeta INT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_tarjeta IS NULL
        SET @errores += N'id_tarjeta es obligatorio. ';
    IF @id_tarjeta IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Tarjeta
        WHERE id_tarjeta = @id_tarjeta
    )
        SET @errores += N'id_tarjeta no existe en Mundial.Tarjeta. ';

    IF EXISTS (
        SELECT 1 FROM Mundial.Expulsion
        WHERE id_tarjeta = @id_tarjeta
    )
        SET @errores += N'La tarjeta está vinculada a una expulsión. ';

    IF @errores <> N''
        THROW 50303, @errores, 1;
	
	DELETE FROM Mundial.Tarjeta -- Elimino esa tarjeta
	WHERE id_tarjeta = @id_tarjeta;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50303, N'Los datos relacionados cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO
