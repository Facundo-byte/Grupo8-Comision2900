/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script SPs/27_SP_Priorizacion_Publicidad.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

PRINT '=== TESTING SP PRIORIZACION PUBLICIDAD Y PRIME TIME ===';

DECLARE @idPart INT = (
    SELECT TOP 1 p.id_partido
    FROM Mundial.Partido p
    JOIN Mundial.Seleccion sl ON sl.id_seleccion = p.id_seleccion_local
    JOIN Mundial.Pais pl ON pl.id_pais = sl.id_pais
    WHERE pl.nombre = 'Argentina'
    ORDER BY p.id_partido
);

DECLARE @pArg INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'Argentina');
DECLARE @pBra INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'Brasil');
DECLARE @pUsa INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'Estados Unidos');
DECLARE @pJap INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'Japon');
DECLARE @pAle INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'Alemania');
DECLARE @pMex INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'Mexico');

IF @idPart IS NULL OR @pArg IS NULL OR @pBra IS NULL OR @pUsa IS NULL OR @pJap IS NULL OR @pAle IS NULL OR @pMex IS NULL
    PRINT 'FALTAN DATOS: ejecutar seeds 28 a 31 primero.';
ELSE
BEGIN
    DECLARE @candidatos Mundial.tt_CandidatoPublicidad;

    -- 6 candidatos compitiendo por los 4 espacios de la sede (incluye >4 candidatos en prime time)
    INSERT INTO @candidatos (id_pieza, anunciante, campania, id_pais_destino, huso_horario, pbi_per_capita, tarifa_usd) VALUES
        (101, N'Quilmes', N'Aliento Seleccion', @pArg, 'UTC-03:00', 13700.00, 15000.00),
        (102, N'Brahma', N'Torcida Brasil', @pBra, 'UTC-03:00', 10200.00, 14500.00),
        (103, N'Apple', N'iPhone World Cup', @pUsa, 'UTC-04:00', 81600.00, 30000.00),
        (104, N'Siemens', N'Energia limpia', @pAle, 'UTC+02:00', 52800.00, 24000.00),
        (105, N'Sony', N'PlayStation Cup', @pJap, 'UTC+09:00', 33800.00, 22000.00),
        (106, N'Corona', N'Fiesta Futbol', @pMex, 'UTC-06:00', 13900.00, 16000.00);

    -- Caso 1: Simular prime time por mercado para el partido
    EXEC Mundial.usp_Simular_PrimeTime_Partido @id_partido = @idPart, @candidatos = @candidatos;

    -- Caso 2: proponer cuatro piezas distintas sin registrar una exhibicion.
    EXEC Mundial.usp_Asignar_Publicidad_Partido @id_partido = @idPart, @candidatos = @candidatos;

    -- Caso 3: Menos de 4 candidatos (debe fallar)
    BEGIN TRY
        DECLARE @pocos Mundial.tt_CandidatoPublicidad;
        INSERT INTO @pocos SELECT TOP 2 * FROM @candidatos;
        EXEC Mundial.usp_Asignar_Publicidad_Partido @id_partido = @idPart, @candidatos = @pocos, @persistir_en_sede = 0;
    END TRY
    BEGIN CATCH
        PRINT 'PU3 Menos de 4 candidatos OK (error esperado): ' + ERROR_MESSAGE();
    END CATCH
END
GO
