/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.Posicion
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Posicion_Alta
    @nombre VARCHAR(30),
    @abreviatura VARCHAR(5),
    @mensaje VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @abreviatura IS NULL OR LTRIM(RTRIM(@abreviatura)) = ''
        SET @error = @error + 'Abreviatura obligatoria. ';

    IF EXISTS (SELECT 1 FROM Mundial.Posicion WHERE nombre = @nombre)
        SET @error = @error + 'La posicion ya existe. ';

    IF EXISTS (SELECT 1 FROM Mundial.Posicion WHERE abreviatura = @abreviatura)
        SET @error = @error + 'La abreviatura ya existe. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    INSERT INTO Mundial.Posicion (nombre, abreviatura)
    VALUES (@nombre, @abreviatura);
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Posicion_Modificacion
    @id_posicion INT,
    @nombre VARCHAR(30),
    @abreviatura VARCHAR(5),
    @mensaje VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @id_posicion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Posicion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'La posicion no existe. ';

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @error = @error + 'Nombre obligatorio. ';

    IF @abreviatura IS NULL OR LTRIM(RTRIM(@abreviatura)) = ''
        SET @error = @error + 'Abreviatura obligatoria. ';

    IF EXISTS (SELECT 1 FROM Mundial.Posicion WHERE nombre = @nombre AND id_posicion <> @id_posicion)
        SET @error = @error + 'Otra posicion ya tiene ese nombre. ';

    IF EXISTS (SELECT 1 FROM Mundial.Posicion WHERE abreviatura = @abreviatura AND id_posicion <> @id_posicion)
        SET @error = @error + 'Otra posicion ya tiene esa abreviatura. ';

    IF @error <> ''
    BEGIN
        SET @mensaje = @error;
        PRINT @error;
        RETURN 1;
    END

    UPDATE Mundial.Posicion
    SET nombre = @nombre,
        abreviatura = @abreviatura
    WHERE id_posicion = @id_posicion;
END
GO

CREATE OR ALTER PROCEDURE Mundial.usp_Posicion_Baja
    @id_posicion INT
AS
BEGIN
    DECLARE @error VARCHAR(500) = '';

    IF @id_posicion IS NULL OR NOT EXISTS (SELECT 1 FROM Mundial.Posicion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'La posicion no existe. ';

    IF EXISTS (SELECT 1 FROM Mundial.Jugador_Formacion WHERE id_posicion = @id_posicion)
        SET @error = @error + 'La posicion esta usada en formaciones. ';

    IF @error <> ''
    BEGIN
        PRINT @error;
        RETURN;
    END

    DELETE FROM Mundial.Posicion
    WHERE id_posicion = @id_posicion;
END
GO
