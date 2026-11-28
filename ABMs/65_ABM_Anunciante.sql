/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 27/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Anunciante
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Anunciante_Alta
    @nombre VARCHAR(400),
    @id_pais_origen INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    SET @nombre = LTRIM(RTRIM(@nombre));
    IF @nombre IS NULL OR @nombre = '' OR LEN(@nombre) > 100
        SET @error = @error + 'nombre debe tener entre 1 y 100 caracteres. ';

    IF @id_pais_origen IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais_origen)
        SET @error = @error + 'Pais de origen inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Anunciante (nombre, id_pais_origen)
    VALUES (@nombre, @id_pais_origen);
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Anunciante_Modificacion
    @id_anunciante INT,
    @nombre VARCHAR(400),
    @id_pais_origen INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_anunciante IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Anunciante WHERE id_anunciante = @id_anunciante)
        SET @error = @error + 'Registro inexistente. ';

    SET @nombre = LTRIM(RTRIM(@nombre));
    IF @nombre IS NULL OR @nombre = '' OR LEN(@nombre) > 100
        SET @error = @error + 'nombre debe tener entre 1 y 100 caracteres. ';

    IF @id_pais_origen IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais_origen)
        SET @error = @error + 'Pais de origen inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Anunciante
    SET nombre = @nombre,
        id_pais_origen = @id_pais_origen
    WHERE id_anunciante = @id_anunciante;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Anunciante_Baja
    @id_anunciante INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Mundial.Anunciante
        WHERE id_anunciante = @id_anunciante;

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
