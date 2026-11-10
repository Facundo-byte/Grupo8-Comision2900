/*
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
	Descripcion: Store Procedures ABM de la Tabla SUSTITUCION
*/

CREATE OR ALTER PROCEDURE Mundial.Sustitucion_Alta
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador_sale INT,
    @id_jugador_entra INT,
    @motivo VARCHAR(MAX),
    @minuto INT,
    @id_sustitucion INT = NULL OUTPUT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_partido IS NULL -- Si el dato enviado es NULL
        SET @errores += N'id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS ( --Si el id de ese partido no se encontro
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
    )
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    IF @id_seleccion IS NULL -- Si el dato enviado es NULL
        SET @errores += N'id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion) --Si el id de esa seleccion no se encontro
        SET @errores += N'id_seleccion no existe en Mundial.Seleccion. ';

    IF EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido AND @id_seleccion NOT IN (id_seleccion_local, id_seleccion_visitante))
        SET @errores += N'La selección de la sustitución no participa en el partido. ';

    IF @id_jugador_sale IS NULL -- Si el dato enviado es NULL
        SET @errores += N'id_jugador_sale es obligatorio. ';
    IF @id_jugador_sale IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Mundial.JugadorWHERE id_jugador = @id_jugador_sale) --Si el id de ese jugador no se encontro
        SET @errores += N'id_jugador_sale no existe en Mundial.Jugador. ';

    IF @id_jugador_entra IS NULL -- Si el dato enviado es NULL
        SET @errores += N'id_jugador_entra es obligatorio. ';
    IF @id_jugador_entra IS NOT NULL AND NOT EXISTS ( --Si el id de ese jugador no se encontro
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador_entra
    )
        SET @errores += N'id_jugador_entra no existe en Mundial.Jugador. ';

    IF @id_jugador_sale = @id_jugador_entra -- Si los ids del jugador q entra y el q sale son iguales
        SET @errores += N'El jugador que sale y el que entra deben ser distintos. ';

    IF @motivo IS NULL -- Si el dato enviado es NULL
        SET @errores += N'motivo es obligatorio. ';
    IF @motivo IS NOT NULL AND @motivo NOT IN ('Lesion', 'Tactica', 'Cansancio') -- Si el motivo no coincide con los valores que tiene que tener
        SET @errores += N'motivo debe ser uno de estos valores: Lesion, Tactica, Cansancio. ';
    IF DATALENGTH(@motivo) > 20
        SET @errores += N'motivo supera los 20 bytes que admite la columna. ';

    IF @minuto IS NULL -- Si el dato enviado es NULL
        SET @errores += N'minuto es obligatorio. ';
    IF @minuto < 0
        SET @errores += N'minuto debe ser mayor o igual a cero. ';

    IF @errores <> N''
        THROW 50501, @errores, 1; -- Si hubo algun error lo informa

    INSERT INTO Mundial.Sustitucion
        (id_partido, id_seleccion, id_jugador_sale, id_jugador_entra, motivo, minuto)
    SELECT @id_partido, @id_seleccion, @id_jugador_sale, @id_jugador_entra, @motivo, @minuto
    WHERE EXISTS (
        SELECT 1
        FROM Mundial.Partido WITH (HOLDLOCK) -- Con esto hago que haya un bloqueo de lectura sobre los datos de Mundial.Partido hasta q termine esa transaccion
        WHERE id_partido = @id_partido
          AND @id_seleccion IN (id_seleccion_local, id_seleccion_visitante)
    );

    DECLARE @filas_insertadas INT = @@ROWCOUNT, @error_sql INT = @@ERROR;
    IF @error_sql <> 0
        RETURN;
    IF @filas_insertadas = 0
        THROW 50501, N'La selección de la sustitución no participa en el partido. ', 1;

    SET @id_sustitucion = CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Sustitucion_Modificar
    @id_sustitucion INT,
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador_sale INT,
    @id_jugador_entra INT,
    @motivo VARCHAR(MAX),
    @minuto INT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_sustitucion IS NULL
        SET @errores += N'id_sustitucion es obligatorio. ';
    IF @id_sustitucion IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Sustitucion
        WHERE id_sustitucion = @id_sustitucion
    )
        SET @errores += N'id_sustitucion no existe en Mundial.Sustitucion. ';

    IF @id_partido IS NULL
        SET @errores += N'id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
    )
        SET @errores += N'id_partido no existe en Mundial.Partido. ';

    IF @id_seleccion IS NULL
        SET @errores += N'id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Seleccion
        WHERE id_seleccion = @id_seleccion
    )
        SET @errores += N'id_seleccion no existe en Mundial.Seleccion. ';

    IF EXISTS (
        SELECT 1 FROM Mundial.Partido
        WHERE id_partido = @id_partido
          AND @id_seleccion NOT IN (id_seleccion_local, id_seleccion_visitante)
    )
        SET @errores += N'La selección de la sustitución no participa en el partido. ';

    IF @id_jugador_sale IS NULL
        SET @errores += N'id_jugador_sale es obligatorio. ';
    IF @id_jugador_sale IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador_sale
    )
        SET @errores += N'id_jugador_sale no existe en Mundial.Jugador. ';

    IF @id_jugador_entra IS NULL
        SET @errores += N'id_jugador_entra es obligatorio. ';
    IF @id_jugador_entra IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Jugador
        WHERE id_jugador = @id_jugador_entra
    )
        SET @errores += N'id_jugador_entra no existe en Mundial.Jugador. ';

    IF @id_jugador_sale = @id_jugador_entra
        SET @errores += N'El jugador que sale y el que entra deben ser distintos. ';

    IF @motivo IS NULL
        SET @errores += N'motivo es obligatorio. ';
    IF @motivo IS NOT NULL AND @motivo NOT IN ('Lesion', 'Tactica', 'Cansancio')
        SET @errores += N'motivo debe ser uno de estos valores: Lesion, Tactica, Cansancio. ';
    IF DATALENGTH(@motivo) > 20
        SET @errores += N'motivo supera los 20 bytes que admite la columna. ';

    IF @minuto IS NULL
        SET @errores += N'minuto es obligatorio. ';
    IF @minuto < 0
        SET @errores += N'minuto debe ser mayor o igual a cero. ';

    IF @errores <> N''
        THROW 50502, @errores, 1; -- Si hubo algun error lo informa

    UPDATE Mundial.Sustitucion
    SET id_partido = @id_partido,
        id_seleccion = @id_seleccion,
        id_jugador_sale = @id_jugador_sale,
        id_jugador_entra = @id_jugador_entra,
        motivo = @motivo,
        minuto = @minuto
    WHERE id_sustitucion = @id_sustitucion
      AND EXISTS (
        SELECT 1
        FROM Mundial.Partido WITH (HOLDLOCK)
        WHERE id_partido = @id_partido
          AND @id_seleccion IN (id_seleccion_local, id_seleccion_visitante)
    );

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50502, N'Los datos relacionados cambiaron durante la operación. Volvé a intentar. ', 1;
END;
GO

CREATE OR ALTER PROCEDURE Mundial.Sustitucion_Baja
    @id_sustitucion INT
AS
BEGIN
    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_sustitucion IS NULL
        SET @errores += N'id_sustitucion es obligatorio. ';
    IF @id_sustitucion IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Mundial.Sustitucion
        WHERE id_sustitucion = @id_sustitucion
    )
        SET @errores += N'id_sustitucion no existe en Mundial.Sustitucion. ';

    IF @errores <> N''
        THROW 50503, @errores, 1; -- Si hubo algun error lo informa

    DELETE FROM Mundial.Sustitucion
    WHERE id_sustitucion = @id_sustitucion;

    IF @@ERROR = 0 AND @@ROWCOUNT = 0
        THROW 50503, N'id_sustitucion no existe en Mundial.Sustitucion. ', 1;
END;
GO
