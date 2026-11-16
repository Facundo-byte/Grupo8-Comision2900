/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Carga inicial de posiciones y esquemas tacticos de ejemplo
*/

USE MundialDeFutbol;
GO

-- POSICION
IF NOT EXISTS (SELECT 1 FROM Mundial.Posicion WHERE abreviatura = 'ARQ')
    EXEC Mundial.usp_Posicion_Alta 'Arquero', 'ARQ';
IF NOT EXISTS (SELECT 1 FROM Mundial.Posicion WHERE abreviatura = 'DEF')
    EXEC Mundial.usp_Posicion_Alta 'Defensor', 'DEF';
IF NOT EXISTS (SELECT 1 FROM Mundial.Posicion WHERE abreviatura = 'MED')
    EXEC Mundial.usp_Posicion_Alta 'Mediocampista', 'MED';
IF NOT EXISTS (SELECT 1 FROM Mundial.Posicion WHERE abreviatura = 'DEL')
    EXEC Mundial.usp_Posicion_Alta 'Delantero', 'DEL';
GO

-- ESQUEMA
IF NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = '4-4-2')
    EXEC Mundial.usp_Esquema_Alta '4-4-2';
IF NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = '4-3-3')
    EXEC Mundial.usp_Esquema_Alta '4-3-3';
IF NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = '3-5-2')
    EXEC Mundial.usp_Esquema_Alta '3-5-2';
IF NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = '4-2-3-1')
    EXEC Mundial.usp_Esquema_Alta '4-2-3-1';
IF NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = '5-3-2')
    EXEC Mundial.usp_Esquema_Alta '5-3-2';
IF NOT EXISTS (SELECT 1 FROM Mundial.Esquema WHERE lineas = '4-5-1')
    EXEC Mundial.usp_Esquema_Alta '4-5-1';
GO

SELECT * FROM Mundial.Posicion; -- Esperado: 4 filas (ARQ, DEF, MED, DEL)
SELECT * FROM Mundial.Esquema;  -- Esperado: 6 filas
GO
