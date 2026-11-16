/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script SPs/24_SP_Designacion_Arbitral.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;
GO

DECLARE @id_terna INT;
BEGIN TRY
    EXEC Mundial.Designacion_Arbitral_Asignar @id_partido = 999999, @id_arbitro_principal = 1, @id_asistente_1 = 1, @id_asistente_2 = 999999, @id_cuarto_arbitro = 2, @id_arbitro_var = 3, @id_terna = @id_terna OUTPUT;
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: partido inexistente + arbitros repetidos + rol inexistente) -> ' + ERROR_MESSAGE();
END CATCH
GO
