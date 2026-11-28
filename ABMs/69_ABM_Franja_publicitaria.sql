/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 27/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Franja_publicitaria
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Franja_publicitaria_Alta
    @nombre VARCHAR(400),
    @tarifa_por_espacio DECIMAL(18,2),
    @moneda VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    SET @nombre = LTRIM(RTRIM(@nombre));
    IF @nombre IS NULL OR @nombre = '' OR LEN(@nombre) > 80
        SET @error = @error + 'nombre debe tener entre 1 y 80 caracteres. ';

    IF @tarifa_por_espacio IS NULL OR @tarifa_por_espacio < 0
        SET @error = @error + 'La tarifa debe ser mayor o igual a cero. ';

    SET @moneda = UPPER(LTRIM(RTRIM(@moneda)));
    IF @moneda IS NULL OR @moneda COLLATE Latin1_General_100_BIN2 NOT LIKE '[A-Z][A-Z][A-Z]'
        SET @error = @error + 'Indicar una moneda de tres letras. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Franja_publicitaria (nombre, tarifa_por_espacio, moneda)
    VALUES (@nombre, @tarifa_por_espacio, @moneda);
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Franja_publicitaria_Modificacion
    @id_franja INT,
    @nombre VARCHAR(400),
    @tarifa_por_espacio DECIMAL(18,2),
    @moneda VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_franja IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Franja_publicitaria WHERE id_franja = @id_franja)
        SET @error = @error + 'Registro inexistente. ';

    SET @nombre = LTRIM(RTRIM(@nombre));
    IF @nombre IS NULL OR @nombre = '' OR LEN(@nombre) > 80
        SET @error = @error + 'nombre debe tener entre 1 y 80 caracteres. ';

    IF @tarifa_por_espacio IS NULL OR @tarifa_por_espacio < 0
        SET @error = @error + 'La tarifa debe ser mayor o igual a cero. ';

    SET @moneda = UPPER(LTRIM(RTRIM(@moneda)));
    IF @moneda IS NULL OR @moneda COLLATE Latin1_General_100_BIN2 NOT LIKE '[A-Z][A-Z][A-Z]'
        SET @error = @error + 'Indicar una moneda de tres letras. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Franja_publicitaria
    SET nombre = @nombre,
        tarifa_por_espacio = @tarifa_por_espacio,
        moneda = @moneda
    WHERE id_franja = @id_franja;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Franja_publicitaria_Baja
    @id_franja INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Mundial.Franja_publicitaria
        WHERE id_franja = @id_franja;

        IF @@ROWCOUNT = 0
            PRINT 'El registro indicado no existe.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547
            PRINT 'No se puede eliminar: el registro tiene datos asociados.';
        ELSE
            THROW;
    END CATCH
END
GO
