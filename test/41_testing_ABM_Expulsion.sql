/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/11_ABM_Expulsion.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

PRINT '=== TESTING ABM EXPULSION ===';

DECLARE @idPart INT = (SELECT TOP 1 id_partido FROM Mundial.Partido ORDER BY id_partido);
DECLARE @idJug INT = (SELECT TOP 1 id_jugador FROM Mundial.Jugador ORDER BY id_jugador);
DECLARE @tAmarilla1 INT, @tAmarilla2 INT, @tRoja INT, @idExp1 INT, @idExp2 INT;

IF @idPart IS NULL OR @idJug IS NULL
    PRINT 'FALTAN DATOS: se requieren partidos y jugadores.';
ELSE
BEGIN
    -- Preparar tarjetas de prueba
    EXEC Mundial.Tarjeta_Alta @idPart, @idJug, 15, 'Primera amarilla', 'Amarilla', @tAmarilla1 OUTPUT;
    EXEC Mundial.Tarjeta_Alta @idPart, @idJug, 65, 'Segunda amarilla', 'Amarilla', @tAmarilla2 OUTPUT;
    EXEC Mundial.Tarjeta_Alta @idPart, @idJug, 80, 'Roja directa', 'Roja', @tRoja OUTPUT;

    -- Caso 1: Doble amarilla sin amarilla previa (debe fallar con @tAmarilla1)
    BEGIN TRY
        EXEC Mundial.Expulsion_Alta @id_tarjeta = @tAmarilla1, @tipoexpulsion = 'Doble amarilla';
    END TRY
    BEGIN CATCH
        PRINT 'EX1 Doble amarilla sin previa OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Caso 2: Doble amarilla valida (con @tAmarilla2)
    EXEC Mundial.Expulsion_Alta @id_tarjeta = @tAmarilla2, @tipoexpulsion = 'Doble amarilla', @id_expulsion = @idExp1 OUTPUT;
    SELECT prueba = 'EX2 Doble amarilla valida', id_expulsion = @idExp1, id_tarjeta, tipoexpulsion FROM Mundial.Expulsion WHERE id_expulsion = @idExp1;

    -- Caso 3: Roja directa valida
    EXEC Mundial.Expulsion_Alta @id_tarjeta = @tRoja, @tipoexpulsion = 'Roja', @id_expulsion = @idExp2 OUTPUT;
    SELECT prueba = 'EX3 Roja directa valida', id_expulsion = @idExp2, id_tarjeta, tipoexpulsion FROM Mundial.Expulsion WHERE id_expulsion = @idExp2;

    -- Limpieza
    EXEC Mundial.Expulsion_Baja @id_expulsion = @idExp1;
    EXEC Mundial.Expulsion_Baja @id_expulsion = @idExp2;
    EXEC Mundial.Tarjeta_Baja @id_tarjeta = @tAmarilla1;
    EXEC Mundial.Tarjeta_Baja @id_tarjeta = @tAmarilla2;
    EXEC Mundial.Tarjeta_Baja @id_tarjeta = @tRoja;
END
GO
