/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Formacion
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Formacion_Alta
    @id_partido INT,
    @id_seleccion INT,
    @id_esquema INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @id_partido IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
        SET @error = @error + 'Partido inexistente. ';

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
        SET @error = @error + 'Seleccion inexistente. ';

    IF @id_esquema IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'Esquema inexistente. ';

    IF EXISTS (SELECT 1 FROM Mundial.Partido WHERE id_partido = @id_partido)
       AND EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
       AND NOT EXISTS (SELECT 1 FROM Mundial.Partido
                       WHERE id_partido = @id_partido
                         AND (id_seleccion_local = @id_seleccion OR id_seleccion_visitante = @id_seleccion))
        SET @error = @error + 'La seleccion no juega ese partido. ';

    IF EXISTS (SELECT 1 FROM Mundial.Formacion
               WHERE id_partido = @id_partido AND id_seleccion = @id_seleccion)
        SET @error = @error + 'La seleccion ya tiene formacion en ese partido. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    INSERT INTO Mundial.Formacion (id_partido, id_seleccion, id_esquema)
    VALUES (@id_partido, @id_seleccion, @id_esquema);
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Formacion_Modificacion
    @id_formacion INT,
    @id_esquema INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @id_formacion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Formacion WHERE id_formacion = @id_formacion)
        SET @error = @error + 'Formacion inexistente. ';

    IF @id_esquema IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE id_esquema = @id_esquema)
        SET @error = @error + 'Esquema inexistente. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    UPDATE Mundial.Formacion
    SET id_esquema = @id_esquema
    WHERE id_formacion = @id_formacion;
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.usp_Formacion_Baja
    @id_formacion INT
AS
BEGIN
    IF @id_formacion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Formacion WHERE id_formacion = @id_formacion)
    BEGIN
        PRINT 'Formacion inexistente. ';
        RETURN;
    END

    BEGIN TRANSACTION;

    DELETE FROM Mundial.Jugador_Formacion
    WHERE id_formacion = @id_formacion;

    DELETE FROM Mundial.Formacion
    WHERE id_formacion = @id_formacion;

    COMMIT TRANSACTION;
END
GO
