USE MundialDeFutbol;
GO
SET NOCOUNT ON;

/*FORMACION COMPLETA*/
PRINT '=== usp_Registrar_Formacion_Completa ===';

DECLARE @sel INT, @part INT, @idf INT;
DECLARE @esq INT = (SELECT id_esquema FROM Mundial.Esquema WHERE lineas = '4-3-3');
DECLARE @ARQ INT = (SELECT id_posicion FROM Mundial.Posicion WHERE abreviatura = 'ARQ');
DECLARE @DEF INT = (SELECT id_posicion FROM Mundial.Posicion WHERE abreviatura = 'DEF');
DECLARE @MED INT = (SELECT id_posicion FROM Mundial.Posicion WHERE abreviatura = 'MED');
DECLARE @DEL INT = (SELECT id_posicion FROM Mundial.Posicion WHERE abreviatura = 'DEL');

SELECT TOP 1 @sel = l.id_seleccion
FROM Mundial.Lista_convocados l
GROUP BY l.id_seleccion
HAVING COUNT(*) >= 18
ORDER BY l.id_seleccion;

SELECT TOP 1 @part = p.id
FROM Mundial.Partido p
WHERE NOT EXISTS (SELECT * FROM Mundial.Formacion f WHERE f.id_partido = p.id AND f.id_seleccion = @sel)
ORDER BY p.id;

IF @sel IS NULL OR @part IS NULL OR @esq IS NULL OR @ARQ IS NULL
    PRINT 'FALTAN DATOS: se necesita el seed (seed_posiciones_y_esquemas.sql), una seleccion con 18 convocados y un partido sin formacion.';
ELSE
BEGIN
    -- 18 convocados: 11 titulares (1 ARQ, 4 DEF, 3 MED, 3 DEL) y 7 suplentes
    DECLARE @plantel Mundial.tt_JugadorFormacion;
    INSERT INTO @plantel (id_jugador, id_posicion, es_titular)
    SELECT id_jugador,
           CASE WHEN rn = 1 THEN @ARQ
                WHEN rn BETWEEN 2 AND 5 THEN @DEF
                WHEN rn BETWEEN 6 AND 8 THEN @MED
                ELSE @DEL END,
           CASE WHEN rn <= 11 THEN 1 ELSE 0 END
    FROM (SELECT id_jugador, ROW_NUMBER() OVER (ORDER BY id_jugador) AS rn
          FROM Mundial.Lista_convocados
          WHERE id_seleccion = @sel) x
    WHERE rn <= 18;

    PRINT 'N1 Plantel con 10 titulares y sin arquero. Esperado: "Se requieren 11 titulares. Debe haber 1 arquero (ARQ) entre los titulares."';
    DECLARE @malo Mundial.tt_JugadorFormacion;
    INSERT INTO @malo (id_jugador, id_posicion, es_titular)
    SELECT id_jugador, @DEF, es_titular
    FROM @plantel
    WHERE id_jugador <> (SELECT MIN(id_jugador) FROM @plantel);
    EXEC Mundial.usp_Registrar_Formacion_Completa @part, @sel, @esq, @malo;
    SELECT COUNT(*) AS formaciones_creadas FROM Mundial.Formacion WHERE id_partido = @part AND id_seleccion = @sel;   -- Esperado: 0

    PRINT 'N2 Jugador no convocado dentro del plantel. Esperado: "Hay jugadores que no estan convocados por la seleccion."';
    DECLARE @intruso INT = (SELECT TOP 1 j.id FROM Mundial.Jugador j
                            WHERE NOT EXISTS (SELECT * FROM Mundial.Lista_convocados l
                                              WHERE l.id_seleccion = @sel AND l.id_jugador = j.id)
                            ORDER BY j.id);
    IF @intruso IS NULL
        PRINT 'FALTAN DATOS: todos los jugadores estan convocados por esa seleccion.';
    ELSE
    BEGIN
        DECLARE @conIntruso Mundial.tt_JugadorFormacion;
        INSERT INTO @conIntruso (id_jugador, id_posicion, es_titular) SELECT id_jugador, id_posicion, es_titular FROM @plantel;
        UPDATE @conIntruso SET id_jugador = @intruso WHERE id_jugador = (SELECT MAX(id_jugador) FROM @conIntruso);
        EXEC Mundial.usp_Registrar_Formacion_Completa @part, @sel, @esq, @conIntruso;
        SELECT COUNT(*) AS formaciones_creadas FROM Mundial.Formacion WHERE id_partido = @part AND id_seleccion = @sel;   -- Esperado: 0
    END

    PRINT 'N3 Partido y esquema inexistentes. Esperado: "Partido inexistente. Esquema inexistente."';
    EXEC Mundial.usp_Registrar_Formacion_Completa -1, @sel, -1, @plantel;

    PRINT 'N4 Formacion valida. Esperado: "Formacion registrada correctamente." con 11 titulares y 7 suplentes';
    EXEC Mundial.usp_Registrar_Formacion_Completa @part, @sel, @esq, @plantel;
    SELECT @idf = id_formacion FROM Mundial.Formacion WHERE id_partido = @part AND id_seleccion = @sel;
    SELECT * FROM Mundial.Formacion WHERE id_formacion = @idf;                                          -- Esperado: 1 fila
    SELECT es_titular, COUNT(*) AS cantidad
    FROM Mundial.Jugador_Formacion WHERE id_formacion = @idf GROUP BY es_titular;                        -- Esperado: 1 -> 11 / 0 -> 7

    PRINT 'N5 Repetir la misma formacion. Esperado: "La seleccion ya tiene formacion en ese partido."';
    EXEC Mundial.usp_Registrar_Formacion_Completa @part, @sel, @esq, @plantel;
    SELECT COUNT(*) AS formaciones FROM Mundial.Formacion WHERE id_partido = @part AND id_seleccion = @sel;   -- Esperado: 1

    PRINT 'N6 Historial de titularidad del primer jugador. Esperado: 1 fila, condicion Titular, posicion ARQ';
    DECLARE @j1 INT = (SELECT MIN(id_jugador) FROM @plantel);
    EXEC Mundial.usp_Historial_Titularidad_Jugador @j1;

    PRINT 'N7 Historial de jugador inexistente. Esperado: "Jugador inexistente."';
    EXEC Mundial.usp_Historial_Titularidad_Jugador -1;

    -- Se elimina la formacion de prueba para poder repetir el script.
    EXEC Mundial.usp_Formacion_Baja @idf;
END

GO
SET NOCOUNT ON;

/*CUERPO TECNICO POR LOTE*/
PRINT '=== usp_Registrar_Cuerpo_Tecnico_Seleccion ===';

DECLARE @x INT;

DECLARE @selCT INT = (SELECT TOP 1 s.id FROM Mundial.Seleccion s
                      WHERE NOT EXISTS (SELECT * FROM Mundial.Cuerpo_tecnico c WHERE c.id_seleccion = s.id)
                      ORDER BY s.id);

IF @selCT IS NULL
    PRINT 'FALTAN DATOS: todas las selecciones ya tienen cuerpo tecnico (probar con una seleccion nueva).';
ELSE
BEGIN
    DECLARE @lote Mundial.tt_MiembroCuerpoTecnico;

    PRINT 'N8 Lote sin DT. Esperado: "La seleccion debe quedar con exactamente 1 director tecnico."';
    INSERT INTO @lote VALUES ('Ana','TestLoteA','AYUDANTE'), ('Luis','TestLoteB','MEDICO');
    EXEC Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion @selCT, @lote;
    SELECT COUNT(*) AS integrantes FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @selCT; -- Esperado: 0

    PRINT 'N9 Lote con dos DT. Esperado: "La seleccion debe quedar con exactamente 1 director tecnico."';
    DELETE FROM @lote;
    INSERT INTO @lote VALUES ('Raul','TestLoteDT1','DT'), ('Omar','TestLoteDT2','DT');
    EXEC Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion @selCT, @lote;

    PRINT 'N10 Lote con personas repetidas y rol invalido. Esperado: "Hay roles invalidos en el lote. Hay personas repetidas en el lote."';
    DELETE FROM @lote;
    INSERT INTO @lote VALUES ('Raul','TestLoteDT1','DT'), ('Ana','TestLoteA','AYUDANTE'), ('Ana','TestLoteA','KINESIOLOGO');
    EXEC Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion @selCT, @lote;

    PRINT 'N11 Lote vacio. Esperado: "No se recibio ningun integrante. La seleccion debe quedar con exactamente 1 director tecnico."';
    DELETE FROM @lote;
    EXEC Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion @selCT, @lote;

    PRINT 'N12 Seleccion inexistente. Esperado: "Seleccion inexistente."';
    INSERT INTO @lote VALUES ('Raul','TestLoteDT1','DT');
    EXEC Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion -1, @lote;

    PRINT 'N13 Lote valido con 1 DT. Esperado: "Cuerpo tecnico registrado correctamente." con 3 integrantes';
    DELETE FROM @lote;
    INSERT INTO @lote VALUES ('Raul','TestLoteDT1','DT'), ('Ana','TestLoteA','AYUDANTE'), ('Luis','TestLoteB','PREPARADOR_FISICO');
    EXEC Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion @selCT, @lote;
    SELECT * FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @selCT; -- Esperado: 3 filas

    PRINT 'N14 Repetir el mismo lote. Esperado: "Hay personas que ya estan en el cuerpo tecnico." y el DT duplicado';
    EXEC Mundial.usp_Registrar_Cuerpo_Tecnico_Seleccion @selCT, @lote;
    SELECT COUNT(*) AS integrantes FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @selCT;-- Esperado: 3

    SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @selCT AND id_cuerpo_tecnico > 0);
    WHILE @x IS NOT NULL
    BEGIN
        EXEC Mundial.usp_Cuerpo_tecnico_Baja @x;
        SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @selCT AND id_cuerpo_tecnico > @x);
    END
END

GO
SET NOCOUNT ON;

/*ESPACIOS PUBLICITARIOS DE UNA SEDE*/
PRINT '=== usp_Inicializar_Espacios_Sede ===';

DECLARE @sede INT = (SELECT TOP 1 id FROM Mundial.Sede ORDER BY id);

IF @sede IS NULL
    PRINT 'FALTAN DATOS: no hay sedes.';
ELSE
BEGIN
    PRINT 'N15 Sede inexistente. Esperado: "Sede inexistente."';
    EXEC Mundial.usp_Inicializar_Espacios_Sede -1;

    PRINT 'N16 Inicializar la sede. Esperado: "Espacios publicitarios completos (4)." con numeros 1 a 4';
    EXEC Mundial.usp_Inicializar_Espacios_Sede @sede;
    SELECT * FROM Mundial.Espacio_publicitario WHERE id_sede = @sede ORDER BY numero_espacio;   -- Esperado: 4 filas

    PRINT 'N17 Ejecutar de nuevo. Esperado: sin cambios, sigue habiendo 4 espacios';
    EXEC Mundial.usp_Inicializar_Espacios_Sede @sede;
    SELECT COUNT(*) AS espacios FROM Mundial.Espacio_publicitario WHERE id_sede = @sede;        -- Esperado: 4
END
GO
