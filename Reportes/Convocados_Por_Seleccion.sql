/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Creacion de la base de datos MundialDeFutbol y de los esquemas Mundial y MfSPabm
*/

Use MundialDeFutbol
go


CREATE OR ALTER PROCEDURE MfReportes.usp_Selecciones_Plantillas_XML
    @id_seleccion INT = NULL   -- NULL = todas
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_seleccion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Mundial.Seleccion WHERE id_seleccion = @id_seleccion)
    BEGIN
        ;THROW 51302, N'La seleccion indicada no existe. ', 1;
    END

    SELECT
        s.id_seleccion,
        p.nombre                AS seleccion,
        c.sigla                 AS confederacion,
        s.grupo,
        -- Vector anidado de convocados en XML
        (
            SELECT
                j.dorsal            AS '@dorsal',
                j.nombre + ' ' + j.apellido AS 'nombre',
                N'Sin posición'             AS 'posicion',
                j.club              AS 'club'
            FROM Mundial.Jugador j
            INNER JOIN Mundial.ListaConvocados lc ON lc.id_lista = j.id_lista_convocados
            WHERE lc.id_seleccion = s.id_seleccion
            ORDER BY j.dorsal
            FOR XML PATH('convocado'), TYPE
        ) AS convocados_xml
    FROM Mundial.Seleccion s
    INNER JOIN Mundial.Pais p          ON p.id_pais = s.id_pais
    INNER JOIN Mundial.Confederacion c ON c.sigla = s.confederacion
    WHERE @id_seleccion IS NULL OR s.id_seleccion = @id_seleccion
    ORDER BY p.nombre;
END;
GO


EXEC MfReportes.usp_Selecciones_Plantillas_XML