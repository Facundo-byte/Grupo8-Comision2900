/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 27/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Pieza_Mercado
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Pieza_Mercado_Alta
    @id_pieza INT,
    @id_pais INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_pieza IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pieza_publicitaria WHERE id_pieza = @id_pieza)
        SET @error = @error + 'Pieza inexistente. ';

    IF @id_pais IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais)
        SET @error = @error + 'Pais inexistente. ';

    IF EXISTS (SELECT 1 FROM Mundial.Pieza_Mercado WHERE id_pieza = @id_pieza AND id_pais = @id_pais)
        SET @error = @error + 'La pieza ya esta dirigida a ese pais. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Pieza_Mercado (id_pieza, id_pais)
    VALUES (@id_pieza, @id_pais);
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Pieza_Mercado_Modificacion
    @id_pieza INT,
    @id_pais INT,
    @id_pais_nuevo INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF NOT EXISTS (SELECT 1 FROM Mundial.Pieza_Mercado WHERE id_pieza = @id_pieza AND id_pais = @id_pais)
        SET @error = @error + 'La relacion entre la pieza y el mercado no existe. ';

    IF @id_pais_nuevo IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pais WHERE id_pais = @id_pais_nuevo)
        SET @error = @error + 'Nuevo pais inexistente. ';

    IF @id_pais_nuevo <> @id_pais AND EXISTS (SELECT 1 FROM Mundial.Pieza_Mercado WHERE id_pieza = @id_pieza AND id_pais = @id_pais_nuevo)
        SET @error = @error + 'La pieza ya esta dirigida a ese pais. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Pieza_Mercado
    SET id_pais = @id_pais_nuevo
    WHERE id_pieza = @id_pieza AND id_pais = @id_pais;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Pieza_Mercado_Baja
    @id_pieza INT,
    @id_pais INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Mundial.Pieza_Mercado
        WHERE id_pieza = @id_pieza AND id_pais = @id_pais;

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
