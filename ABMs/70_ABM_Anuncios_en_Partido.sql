/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 27/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Anuncios_en_Partido
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Anuncios_en_Partido_Alta
    @id_partido INT,
    @id_espacio INT,
    @id_franja INT,
    @id_pieza_publicitaria INT,
    @importe_aplicado DECIMAL(18,2) = NULL,
    @moneda_aplicada VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_pieza_publicitaria IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pieza_publicitaria WHERE id_pieza = @id_pieza_publicitaria)
        SET @error = @error + 'Pieza inexistente. ';

    IF @id_franja IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Franja_publicitaria WHERE id_franja = @id_franja)
        SET @error = @error + 'Franja inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM Mundial.Partido p
                   JOIN Mundial.Espacio_publicitario e ON e.id_sede = p.id_sede
                   WHERE p.id_partido = @id_partido AND e.id_espacio = @id_espacio)
        SET @error = @error + 'El partido y el espacio deben existir y corresponder a la misma sede. ';

    IF EXISTS (SELECT 1 FROM Mundial.Anuncios_en_Partido WHERE id_partido = @id_partido AND id_espacio = @id_espacio AND id_franja = @id_franja)
        SET @error = @error + 'Ese espacio ya tiene una exhibicion en esa franja. ';

    IF (@importe_aplicado IS NULL AND @moneda_aplicada IS NOT NULL)
       OR (@importe_aplicado IS NOT NULL AND @moneda_aplicada IS NULL)
        SET @error = @error + 'Informar importe y moneda juntos. ';
    IF @importe_aplicado < 0
        SET @error = @error + 'El importe no puede ser negativo. ';
    SET @moneda_aplicada = UPPER(LTRIM(RTRIM(@moneda_aplicada)));
    IF @moneda_aplicada COLLATE Latin1_General_100_BIN2 NOT LIKE '[A-Z][A-Z][A-Z]'
        SET @error = @error + 'Indicar una moneda de tres letras. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    -- Si no se informa un precio pactado, se guarda una copia de la tarifa de la franja.
    INSERT INTO Mundial.Anuncios_en_Partido
        (id_partido, id_espacio, id_franja, id_pieza_publicitaria, id_sede, importe_aplicado, moneda_aplicada)
    SELECT p.id_partido, @id_espacio, f.id_franja, @id_pieza_publicitaria, p.id_sede,
           COALESCE(@importe_aplicado, f.tarifa_por_espacio), COALESCE(@moneda_aplicada, f.moneda)
    FROM Mundial.Partido p
    CROSS JOIN Mundial.Franja_publicitaria f
    WHERE p.id_partido = @id_partido AND f.id_franja = @id_franja;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Anuncios_en_Partido_Modificacion
    @id_partido INT,
    @id_espacio INT,
    @id_franja INT,
    @id_pieza_publicitaria INT,
    @importe_aplicado DECIMAL(18,2) = NULL,
    @moneda_aplicada VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @error VARCHAR(500) = '';

    IF @id_pieza_publicitaria IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Pieza_publicitaria WHERE id_pieza = @id_pieza_publicitaria)
        SET @error = @error + 'Pieza inexistente. ';

    IF @id_franja IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Franja_publicitaria WHERE id_franja = @id_franja)
        SET @error = @error + 'Franja inexistente. ';

    IF NOT EXISTS (SELECT 1 FROM Mundial.Partido p
                   JOIN Mundial.Espacio_publicitario e ON e.id_sede = p.id_sede
                   WHERE p.id_partido = @id_partido AND e.id_espacio = @id_espacio)
        SET @error = @error + 'El partido y el espacio deben existir y corresponder a la misma sede. ';

    IF NOT EXISTS (SELECT 1 FROM Mundial.Anuncios_en_Partido WHERE id_partido = @id_partido AND id_espacio = @id_espacio AND id_franja = @id_franja)
        SET @error = @error + 'No existe esa exhibicion. ';

    IF (@importe_aplicado IS NULL AND @moneda_aplicada IS NOT NULL)
       OR (@importe_aplicado IS NOT NULL AND @moneda_aplicada IS NULL)
        SET @error = @error + 'Informar importe y moneda juntos. ';
    IF @importe_aplicado < 0
        SET @error = @error + 'El importe no puede ser negativo. ';
    SET @moneda_aplicada = UPPER(LTRIM(RTRIM(@moneda_aplicada)));
    IF @moneda_aplicada COLLATE Latin1_General_100_BIN2 NOT LIKE '[A-Z][A-Z][A-Z]'
        SET @error = @error + 'Indicar una moneda de tres letras. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Anuncios_en_Partido
    SET id_pieza_publicitaria = @id_pieza_publicitaria,
        importe_aplicado = COALESCE(@importe_aplicado, importe_aplicado),
        moneda_aplicada = COALESCE(@moneda_aplicada, moneda_aplicada)
    WHERE id_partido = @id_partido AND id_espacio = @id_espacio AND id_franja = @id_franja;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Anuncios_en_Partido_Baja
    @id_partido INT,
    @id_espacio INT,
    @id_franja INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Mundial.Anuncios_en_Partido
        WHERE id_partido = @id_partido AND id_espacio = @id_espacio AND id_franja = @id_franja;

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
