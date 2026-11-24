/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Arbitro_terna
*/

CREATE OR ALTER PROCEDURE MfSPabm.Arbitro_Terna_Alta
    @id_terna    INT,
    @id_arbitro  INT,
    @rol         VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_terna IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna)
        SET @errores += N'id_terna invalido. ';

    IF @id_arbitro IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_arbitro = @id_arbitro)
        SET @errores += N'id_arbitro invalido. ';
    ELSE IF EXISTS (SELECT 1 FROM Mundial.Arbitro WHERE id_arbitro = @id_arbitro AND habilitado = 0)
        SET @errores += N'El árbitro está inhabilitado. ';

    IF @rol IS NULL
        SET @errores += N'rol es obligatorio. ';
    ELSE
    BEGIN
        SET @rol = LTRIM(RTRIM(@rol));
        IF @rol NOT IN ('Principal','Asistente 1','Asistente 2','Cuarto arbitro','VAR')
            SET @errores += N'rol invalido. ';
    END

    IF @id_terna IS NOT NULL AND @id_arbitro IS NOT NULL
       AND EXISTS (SELECT 1 FROM Mundial.Arbitro_Terna WHERE id_terna = @id_terna AND id_arbitro = @id_arbitro)
        SET @errores += N'El árbitro ya está en la terna. ';

    IF @id_terna IS NOT NULL AND @rol IS NOT NULL
       AND EXISTS (SELECT 1 FROM Mundial.Arbitro_Terna WHERE id_terna = @id_terna AND rol = @rol)
        SET @errores += N'El rol ' + @rol + N' ya está ocupado en la terna. ';

    IF @errores <> N''
        THROW 51004, @errores, 1;

    INSERT INTO Mundial.Arbitro_Terna (id_terna, id_arbitro, rol)
    VALUES (@id_terna, @id_arbitro, @rol);
END;
GO

CREATE OR ALTER PROCEDURE MfSPabm.Arbitro_Terna_Baja
    @id_terna    INT,
    @id_arbitro  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @id_terna IS NULL OR @id_arbitro IS NULL
       OR NOT EXISTS (SELECT 1 FROM Mundial.Arbitro_Terna WHERE id_terna = @id_terna AND id_arbitro = @id_arbitro)
    BEGIN
        THROW 51006, N'El árbitro no pertenece a la terna indicada. ', 1;
    END

    DELETE FROM Mundial.Arbitro_Terna
    WHERE id_terna = @id_terna AND id_arbitro = @id_arbitro;
END;
GO

CREATE OR ALTER PROCEDURE MfSPabm.Arbitro_Terna_Modificar
    @id_terna    INT,
    @id_arbitro  INT,
    @rol         VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errores NVARCHAR(2048) = N'';

    IF @id_terna IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Terna_Arbitral WHERE id_terna = @id_terna)
        SET @errores += N'id_terna invalido. ';

    IF @id_arbitro IS NULL OR NOT EXISTS (
        SELECT 1 FROM Mundial.Arbitro_Terna WHERE id_terna = @id_terna AND id_arbitro = @id_arbitro
    )
        SET @errores += N'El árbitro no pertenece a la terna. ';

    IF @rol IS NULL
        SET @errores += N'rol es obligatorio. ';
    ELSE
    BEGIN
        SET @rol = LTRIM(RTRIM(@rol));
        IF @rol NOT IN ('Principal','Asistente 1','Asistente 2','Cuarto arbitro','VAR')
            SET @errores += N'rol invalido. ';
    END

    IF @id_terna IS NOT NULL AND @rol IS NOT NULL
       AND EXISTS (
           SELECT 1 FROM Mundial.Arbitro_Terna
           WHERE id_terna = @id_terna AND rol = @rol AND id_arbitro <> @id_arbitro
       )
        SET @errores += N'El rol ya está ocupado por otro árbitro en la terna. ';

    IF @errores <> N''
        THROW 51005, @errores, 1;

    UPDATE Mundial.Arbitro_Terna
    SET rol = @rol
    WHERE id_terna = @id_terna AND id_arbitro = @id_arbitro;
END;
GO





















