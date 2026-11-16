/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Carga inicial de paises y selecciones de ejemplo
*/

USE MundialDeFutbol;
GO

DECLARE @sel TABLE (pais VARCHAR(60), confederacion VARCHAR(30), grupo CHAR(1));
INSERT INTO @sel (pais, confederacion, grupo) VALUES
    ('Argentina','CONMEBOL','A'), ('Brasil','CONMEBOL','A'), ('Uruguay','CONMEBOL','B'), ('Colombia','CONMEBOL','B'),
    ('Chile','CONMEBOL','C'),
    ('México','CONCACAF','C'), ('Canadá','CONCACAF','D'), ('Estados Unidos','CONCACAF','D'),
    ('Francia','UEFA','E'), ('Alemania','UEFA','E'), ('Polonia','UEFA','F'), ('Portugal','UEFA','F'),
    ('Eslovenia','UEFA','G'), ('Inglaterra','UEFA','G'),
    ('Japón','AFC','H'), ('Marruecos','CAF','H');

INSERT INTO Mundial.Pais (nombre)
SELECT s.pais FROM @sel AS s
WHERE NOT EXISTS (SELECT 1 FROM Mundial.Pais AS p WHERE p.nombre = s.pais);
PRINT N'Paises cargados: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);

INSERT INTO Mundial.Seleccion (id_pais, confederacion, grupo)
SELECT p.id_pais, s.confederacion, s.grupo
FROM @sel AS s
JOIN Mundial.Pais AS p ON p.nombre = s.pais
WHERE NOT EXISTS (SELECT 1 FROM Mundial.Seleccion AS x WHERE x.id_pais = p.id_pais);
PRINT N'Selecciones cargadas: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);
GO
