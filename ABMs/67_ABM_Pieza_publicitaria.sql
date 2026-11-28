/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 27/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Pieza_publicitaria
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Pieza_publicitaria_Alta
    @id_campania INT,
    @titulo VARCHAR(400),
    @id_idioma INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_campania IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Campania WHERE id_campania = @id_campania)
        SET @error = @error + 'Campania inexistente. ';

    SET @titulo = LTRIM(RTRIM(@titulo));
    IF @titulo IS NULL OR @titulo = '' OR LEN(@titulo) > 150
        SET @error = @error + 'titulo debe tener entre 1 y 150 caracteres. ';

    IF @id_idioma IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_idioma = @id_idioma)
        SET @error = @error + 'Idioma inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Pieza_publicitaria (id_campania, titulo, id_idioma)
    VALUES (@id_campania, @titulo, @id_idioma);
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Pieza_publicitaria_Modificacion
    @id_pieza INT,
    @id_campania INT,
    @titulo VARCHAR(400),
    @id_idioma INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_pieza IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pieza_publicitaria WHERE id_pieza = @id_pieza)
        SET @error = @error + 'Registro inexistente. ';

    IF @id_campania IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Campania WHERE id_campania = @id_campania)
        SET @error = @error + 'Campania inexistente. ';

    SET @titulo = LTRIM(RTRIM(@titulo));
    IF @titulo IS NULL OR @titulo = '' OR LEN(@titulo) > 150
        SET @error = @error + 'titulo debe tener entre 1 y 150 caracteres. ';

    IF @id_idioma IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Idioma WHERE id_idioma = @id_idioma)
        SET @error = @error + 'Idioma inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Pieza_publicitaria
    SET id_campania = @id_campania,
        titulo = @titulo,
        id_idioma = @id_idioma
    WHERE id_pieza = @id_pieza;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Pieza_publicitaria_Baja
    @id_pieza INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Mundial.Pieza_publicitaria
        WHERE id_pieza = @id_pieza;

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
