/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Carga inicial de partidos de fase de grupos de ejemplo
*/

USE MundialDeFutbol;
GO

DECLARE @p TABLE (local_ VARCHAR(60), visitante VARCHAR(60), estadio NVARCHAR(100), fecha DATETIME);
INSERT INTO @p (local_, visitante, estadio, fecha) VALUES
    ('Argentina','Brasil',        N'MetLife Stadium',      '2026-06-12 20:00'),
    ('México','Polonia',          N'Estadio Azteca',       '2026-06-13 19:00'),
    ('Francia','Alemania',        N'AT&T Stadium',         '2026-06-14 18:00'),
    ('Uruguay','Colombia',        N'Hard Rock Stadium',    '2026-06-15 17:00'),
    ('Japón','Marruecos',         N'BC Place',             '2026-06-16 16:00'),
    ('Estados Unidos','Canadá',   N'SoFi Stadium',         '2026-06-17 21:00');

INSERT INTO Mundial.Partido (id_sede, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, fase)
SELECT sd.id_sede, sl.id_seleccion, sv.id_seleccion, x.fecha,
       DATEADD(HOUR, -CAST(SUBSTRING(sd.huso_horario, 4, 3) AS INT), x.fecha),
       'fasedegrupos'
FROM @p AS x
JOIN Mundial.Sede AS sd ON sd.nombre_estadio = x.estadio
JOIN Mundial.Pais AS pl ON pl.nombre = x.local_
JOIN Mundial.Pais AS pv ON pv.nombre = x.visitante
JOIN Mundial.Seleccion AS sl ON sl.id_pais = pl.id_pais
JOIN Mundial.Seleccion AS sv ON sv.id_pais = pv.id_pais
WHERE NOT EXISTS (
    SELECT 1 FROM Mundial.Partido AS q
    WHERE q.id_seleccion_local = sl.id_seleccion
      AND q.id_seleccion_visitante = sv.id_seleccion
      AND q.fecha_hora_local = x.fecha
);
PRINT N'Partidos cargados: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);
GO
