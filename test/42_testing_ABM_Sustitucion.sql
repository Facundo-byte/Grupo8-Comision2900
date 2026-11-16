/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/12_ABM_Sustitucion.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

PRINT '=== TESTING ABM SUSTITUCION ===';

DECLARE @idPart INT, @idSel INT, @jSale INT, @jEntra INT, @idSust INT;

SELECT TOP 1 @idPart = p.id_partido, @idSel = p.id_seleccion_local
FROM Mundial.Partido p
JOIN Mundial.ListaConvocados lc ON lc.id_seleccion = p.id_seleccion_local
ORDER BY p.id_partido;

SELECT @jSale = MIN(j.id_jugador), @jEntra = MAX(j.id_jugador)
FROM Mundial.Jugador j
JOIN Mundial.ListaConvocados lc ON j.id_lista_convocados = lc.id_lista
WHERE lc.id_seleccion = @idSel;

IF @idPart IS NULL OR @jSale IS NULL OR @jSale = @jEntra
    PRINT 'FALTAN DATOS: ejecutar 29_seed_convocados_jugadores.sql y 31_seed_partidos.sql primero.';
ELSE
BEGIN
    -- Caso 1: Alta valida
    EXEC Mundial.Sustitucion_Alta
        @id_partido = @idPart,
        @id_seleccion = @idSel,
        @id_jugador_sale = @jSale,
        @id_jugador_entra = @jEntra,
        @motivo = 'Tactica',
        @minuto = 60,
        @id_sustitucion = @idSust OUTPUT;

    SELECT prueba = 'SU1 Alta valida', id_sustitucion = @idSust, motivo, minuto FROM Mundial.Sustitucion WHERE id_sustitucion = @idSust;

    -- Caso 2: Mismo jugador sale y entra (debe fallar)
    BEGIN TRY
        EXEC Mundial.Sustitucion_Alta
            @id_partido = @idPart,
            @id_seleccion = @idSel,
            @id_jugador_sale = @jSale,
            @id_jugador_entra = @jSale,
            @motivo = 'Lesion',
            @minuto = 70;
    END TRY
    BEGIN CATCH
        PRINT 'SU2 Mismo jugador OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH

    -- Caso 3: Modificacion valida
    EXEC Mundial.Sustitucion_Modificar
        @id_sustitucion = @idSust,
        @id_partido = @idPart,
        @id_seleccion = @idSel,
        @id_jugador_sale = @jSale,
        @id_jugador_entra = @jEntra,
        @motivo = 'Cansancio',
        @minuto = 75;
    SELECT prueba = 'SU3 Modificacion valida', id_sustitucion, motivo, minuto FROM Mundial.Sustitucion WHERE id_sustitucion = @idSust;

    -- Caso 4: Baja valida
    EXEC Mundial.Sustitucion_Baja @id_sustitucion = @idSust;
    SELECT prueba = 'SU4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.Sustitucion WHERE id_sustitucion = @idSust;
END
GO
