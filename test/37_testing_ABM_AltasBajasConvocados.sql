/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/07_CreacionSPabmAltasBajasConvocados.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

DELETE FROM Mundial.AltasBajasConvocados WHERE motivo = 'Prueba movimiento test';
GO

PRINT '=== TESTING ABM ALTAS BAJAS CONVOCADOS ===';

DECLARE @idLista INT, @idSel INT, @idJug INT;
SELECT TOP 1 @idLista = lc.id_lista, @idSel = lc.id_seleccion, @idJug = j.id_jugador
FROM Mundial.ListaConvocados lc
JOIN Mundial.Jugador j ON j.id_lista_convocados = lc.id_lista
ORDER BY lc.id_lista, j.id_jugador;

IF @idJug IS NULL
    PRINT 'FALTAN DATOS: ejecutar 29_seed_convocados_jugadores.sql primero.';
ELSE
BEGIN
    -- Caso 1: Alta valida
    EXEC MfSPabm.altaAltasBajasConvocados
        @IDListaConvocados = @idLista,
        @IDSeleccion = @idSel,
        @IDJugador = @idJug,
        @Tipo = 'ALTA',
        @Motivo = 'Prueba movimiento test',
        @FechaModificacion = '2026-06-01';

    DECLARE @idMov INT = (SELECT TOP 1 id_alta_baja FROM Mundial.AltasBajasConvocados WHERE motivo = 'Prueba movimiento test');
    SELECT prueba = 'AB1 Alta valida', id_alta_baja = @idMov, tipo, motivo FROM Mundial.AltasBajasConvocados WHERE id_alta_baja = @idMov;

    -- Caso 2: Tipo invalido (debe fallar)
    BEGIN TRY
        EXEC MfSPabm.altaAltasBajasConvocados
            @IDListaConvocados = @idLista,
            @IDSeleccion = @idSel,
            @IDJugador = @idJug,
            @Tipo = 'OTRO',
            @Motivo = 'Invalido',
            @FechaModificacion = '2026-06-01';
    END TRY
    BEGIN CATCH
        PRINT 'AB2 Tipo invalido OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Caso 3: Modificacion valida
    EXEC MfSPabm.modificacionAltasBajasConvocados
        @IDAltaBaja = @idMov,
        @IDListaConvocados = @idLista,
        @IDSeleccion = @idSel,
        @IDJugador = @idJug,
        @Tipo = 'BAJA',
        @Motivo = 'Prueba movimiento test',
        @FechaModificacion = '2026-06-02';
    SELECT prueba = 'AB3 Modificacion valida', id_alta_baja, tipo, fecha_modificacion FROM Mundial.AltasBajasConvocados WHERE id_alta_baja = @idMov;

    -- Caso 4: Baja valida
    EXEC MfSPabm.bajaAltasBajasConvocados @IDAltaBaja = @idMov;
    SELECT prueba = 'AB4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.AltasBajasConvocados WHERE id_alta_baja = @idMov;
END
GO
