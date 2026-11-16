/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/19_ABM_Terna_Arbitral.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;
GO

BEGIN TRY
    EXEC Mundial.Terna_Arbitral_Alta @id_partido = 999999, @id_arbitro_principal = NULL, @id_asistente_1 = 1, @id_asistente_2 = 1, @id_cuarto_arbitro = 2, @id_arbitro_var = 3, @estado = N'Invalido';
END TRY
BEGIN CATCH
    PRINT N'B1 (esperado: mensaje agrupado con multiples errores de validacion) -> ' + ERROR_MESSAGE();
END CATCH
GO
