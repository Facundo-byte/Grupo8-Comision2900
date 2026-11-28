/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 27/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Campania
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Campania_Alta
    @id_anunciante INT,
    @nombre VARCHAR(400),
    @fecha_desde DATETIME2(0),
    @fecha_hasta DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_anunciante IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Anunciante WHERE id_anunciante = @id_anunciante)
        SET @error = @error + 'Anunciante inexistente. ';

    SET @nombre = LTRIM(RTRIM(@nombre));
    IF @nombre IS NULL OR @nombre = '' OR LEN(@nombre) > 150
        SET @error = @error + 'nombre debe tener entre 1 y 150 caracteres. ';

    IF @fecha_desde IS NULL OR @fecha_hasta IS NULL OR @fecha_hasta < @fecha_desde
        SET @error = @error + 'Las fechas de la campania son invalidas. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Campania (id_anunciante, nombre, fecha_desde, fecha_hasta)
    VALUES (@id_anunciante, @nombre, @fecha_desde, @fecha_hasta);
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Campania_Modificacion
    @id_campania INT,
    @id_anunciante INT,
    @nombre VARCHAR(400),
    @fecha_desde DATETIME2(0),
    @fecha_hasta DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_campania IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Campania WHERE id_campania = @id_campania)
        SET @error = @error + 'Registro inexistente. ';

    IF @id_anunciante IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Anunciante WHERE id_anunciante = @id_anunciante)
        SET @error = @error + 'Anunciante inexistente. ';

    SET @nombre = LTRIM(RTRIM(@nombre));
    IF @nombre IS NULL OR @nombre = '' OR LEN(@nombre) > 150
        SET @error = @error + 'nombre debe tener entre 1 y 150 caracteres. ';

    IF @fecha_desde IS NULL OR @fecha_hasta IS NULL OR @fecha_hasta < @fecha_desde
        SET @error = @error + 'Las fechas de la campania son invalidas. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Campania
    SET id_anunciante = @id_anunciante,
        nombre = @nombre,
        fecha_desde = @fecha_desde,
        fecha_hasta = @fecha_hasta
    WHERE id_campania = @id_campania;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Campania_Baja
    @id_campania INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Mundial.Campania
        WHERE id_campania = @id_campania;

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
