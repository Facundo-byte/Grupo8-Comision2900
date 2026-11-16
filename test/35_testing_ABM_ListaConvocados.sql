/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing del script ABMs/05_CreacionSPabmListaConvocados.sql (relacion 1:1)
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

DELETE FROM Mundial.ListaConvocados WHERE id_seleccion IN (SELECT id_seleccion FROM Mundial.Seleccion WHERE id_pais IN (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'PaisListaTest'));
DELETE FROM Mundial.Seleccion WHERE id_pais IN (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'PaisListaTest');
DELETE FROM Mundial.Pais WHERE nombre = 'PaisListaTest';
GO

PRINT '=== TESTING ABM LISTA CONVOCADOS ===';

EXEC MfSPabm.altaPais @nombrePais = 'PaisListaTest';
DECLARE @idPais INT = (SELECT id_pais FROM Mundial.Pais WHERE nombre = 'PaisListaTest');
EXEC MfSPabm.altaSeleccion @IDPais = @idPais, @Confederacion = 'CONMEBOL', @Grupo = 'Z';
DECLARE @idSel INT = (SELECT id_seleccion FROM Mundial.Seleccion WHERE id_pais = @idPais);

-- Caso 1: Alta valida
EXEC MfSPabm.altaListaConvocados @IDSeleccion = @idSel;
DECLARE @idLista INT = (SELECT id_lista FROM Mundial.ListaConvocados WHERE id_seleccion = @idSel);
SELECT prueba = 'LC1 Alta valida', id_lista = @idLista, id_seleccion FROM Mundial.ListaConvocados WHERE id_lista = @idLista;

-- Caso 2: Alta duplicada (debe fallar)
BEGIN TRY
    EXEC MfSPabm.altaListaConvocados @IDSeleccion = @idSel;
END TRY
BEGIN CATCH
    PRINT 'LC2 Alta duplicada OK (error esperado): ' + ERROR_MESSAGE();
END CATCH

-- Caso 3: Alta con seleccion inexistente (debe fallar)
BEGIN TRY
    EXEC MfSPabm.altaListaConvocados @IDSeleccion = 999999;
END TRY
BEGIN CATCH
    PRINT 'LC3 Seleccion inexistente OK (error esperado): ' + ERROR_MESSAGE();
END CATCH

-- Caso 4: Baja valida y limpieza
EXEC MfSPabm.bajaListaConvocados @IDLista = @idLista;
EXEC MfSPabm.bajaSeleccion @IDSeleccion = @idSel;
EXEC MfSPabm.bajaPais @IDPais = @idPais;
SELECT prueba = 'LC4 Baja valida (0 filas)', filas = COUNT(*) FROM Mundial.ListaConvocados WHERE id_lista = @idLista;
GO
