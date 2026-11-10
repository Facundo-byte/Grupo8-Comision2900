/*
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
	Descripcion: Store Procedures ABM de la Tabla Gol
*/

CREATE OR ALTER PROCEDURE Mundial.Gol_Alta
    @id_partido INT,
    @id_jugador_autor INT,
    @id_jugador_asistencia INT = NULL,
    @minuto INT,
    @periodo VARCHAR(MAX),
    @id_gol INT = NULL OUTPUT
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

    IF @id_jugador_autor IS NULL
        SET @errores += N'id_jugador_autor es obligatorio. ';
    IF @id_jugador_autor IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador_autor
    )
        SET @errores += N'id_jugador_autor no existe en Mundial.Jugador. ';

    IF @id_jugador_asistencia IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador_asistencia
    )
        SET @errores += N'id_jugador_asistencia no existe en Mundial.Jugador. ';

    IF @id_jugador_autor = @id_jugador_asistencia
        SET @errores += N'El autor y el asistente deben ser distintos. ';

    IF @minuto IS NULL
        SET @errores += N'minuto es obligatorio. ';
    IF @minuto < 0
        SET @errores += N'minuto debe ser mayor o igual a cero. ';

    IF @periodo IS NULL
        SET @errores += N'periodo es obligatorio. ';
    IF @periodo IS NOT NULL AND @periodo NOT IN ('Primer tiempo', 'Segundo tiempo', 'Primer suplementario', 'Segundo suplementario')
        SET @errores += N'periodo debe ser uno de estos valores: Primer tiempo, Segundo tiempo, Primer suplementario, Segundo suplementario. ';
    IF DATALENGTH(@periodo) > 20
        SET @errores += N'periodo supera los 20 bytes que admite la columna. ';

    IF @errores <> N''
        THROW 50201, @errores, 1;

    INSERT INTO Mundial.Gol
        (id_partido, id_jugador_autor, id_jugador_asistencia, minuto, periodo)
    VALUES
        (@id_partido, @id_jugador_autor, @id_jugador_asistencia, @minuto, @periodo);

    IF @@ROWCOUNT = 1
        SET @id_gol = CONVERT(INT, SCOPE_IDENTITY()); -- Le devuelve al que llamo al SP el ID de ese gol
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Gol_Modificar
    @id_gol INT,
    @id_partido INT,
    @id_jugador_autor INT,
    @id_jugador_asistencia INT = NULL,
    @minuto INT,
    @periodo VARCHAR(MAX)
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_gol IS NULL
        SET @errores += N'id_gol es obligatorio. ';
    IF @id_gol IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Gol
        WHERE id_gol = @id_gol
    )
        SET @errores += N'id_gol no existe en Mundial.Gol. ';

    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
    )
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    IF @id_jugador_autor IS NULL
        SET @errores += N'id_jugador_autor es obligatorio. ';
    IF @id_jugador_autor IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador_autor
    )
        SET @errores += N'id_jugador_autor no existe en Mundial.Jugador. ';

    IF @id_jugador_asistencia IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador_asistencia
    )
        SET @errores += N'id_jugador_asistencia no existe en Mundial.Jugador. ';

    IF @id_jugador_autor = @id_jugador_asistencia
        SET @errores += N'El autor y el asistente deben ser distintos. ';

    IF @minuto IS NULL
        SET @errores += N'minuto es obligatorio. ';
    IF @minuto < 0
        SET @errores += N'minuto debe ser mayor o igual a cero. ';

    IF @periodo IS NULL
        SET @errores += N'periodo es obligatorio. ';
    IF @periodo IS NOT NULL AND @periodo NOT IN ('Primer tiempo', 'Segundo tiempo', 'Primer suplementario', 'Segundo suplementario')
        SET @errores += N'periodo debe ser uno de estos valores: Primer tiempo, Segundo tiempo, Primer suplementario, Segundo suplementario. ';
    IF DATALENGTH(@periodo) > 20
        SET @errores += N'periodo supera los 20 bytes que admite la columna. ';

    IF @errores <> N''
        THROW 50202, @errores, 1;

    UPDATE Mundial.Gol
    SET id_partido = @id_partido,
        id_jugador_autor = @id_jugador_autor,
        id_jugador_asistencia = @id_jugador_asistencia,
        minuto = @minuto,
        periodo = @periodo
    WHERE id_gol = @id_gol;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50202, N'id_gol no existe en Mundial.Gol. ', 1;
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Gol_Baja
    @id_gol INT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_gol IS NULL
        SET @errores += N'id_gol es obligatorio. ';
    IF @id_gol IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Gol
        WHERE id_gol = @id_gol
    )
        SET @errores += N'id_gol no existe en Mundial.Gol. ';

    IF @errores <> N''
        THROW 50203, @errores, 1;

    DELETE FROM Mundial.Gol
    WHERE id_gol = @id_gol;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50203, N'id_gol no existe en Mundial.Gol. ', 1;
END;
GO
