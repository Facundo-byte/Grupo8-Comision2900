/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Stored Procedures ABM de la tabla Mundial.ListaConvocados
*/

USE MundialDeFutbol;
GO

CREATE OR ALTER PROCEDURE MfSPabm.altaListaConvocados (@IDSeleccion INT)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDSeleccion IS NULL) OR (@IDSeleccion <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Seleccion invalida.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Seleccion.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Esta Seleccion ya tiene una Lista de Convocados.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            INSERT INTO Mundial.ListaConvocados(id_seleccion) VALUES (@IDSeleccion);
            PRINT 'Lista de Convocados creada exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo crear el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50001, 'No se pudo crear la Lista de Convocados debido a errores de validacion.', 1;
    END
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.bajaListaConvocados (@IDLista INT)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDLista IS NULL) OR (@IDLista <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Lista de Convocados invalida.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_lista = @IDLista))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Lista de Convocados.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            DELETE FROM Mundial.ListaConvocados WHERE id_lista = @IDLista;
            PRINT 'Lista de Convocados eliminada exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo eliminar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50002, 'No se pudo eliminar la Lista de Convocados debido a errores de validacion.', 1;
    END
END
GO

CREATE OR ALTER PROCEDURE MfSPabm.modificacionListaConvocados (@IDLista INT, @IDSeleccion INT)
AS
BEGIN
    DECLARE @errorCount INT = 0;

    IF((@IDLista IS NULL) OR (@IDLista <= 0) OR (@IDSeleccion IS NULL) OR (@IDSeleccion <= 0))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Datos invalidos.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_lista = @IDLista))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Lista de Convocados.';
    END

    IF((@errorCount = 0) AND NOT EXISTS(SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @IDSeleccion))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: No existe esta Seleccion.';
    END

    IF((@errorCount = 0) AND EXISTS(SELECT 1 FROM Mundial.ListaConvocados WHERE id_seleccion = @IDSeleccion AND id_lista <> @IDLista))
    BEGIN
        SET @errorCount = @errorCount + 1;
        PRINT 'ERROR: Esta Seleccion ya tiene otra Lista de Convocados.';
    END

    IF(@errorCount = 0)
    BEGIN
        BEGIN TRY
            UPDATE Mundial.ListaConvocados SET id_seleccion = @IDSeleccion WHERE id_lista = @IDLista;
            PRINT 'Lista de Convocados modificada exitosamente.';
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo modificar el registro.';
            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        ;THROW 50003, 'No se pudo modificar la Lista de Convocados debido a errores de validacion.', 1;
    END
END
GO
