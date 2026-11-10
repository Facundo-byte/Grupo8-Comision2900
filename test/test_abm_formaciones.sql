USE MundialDeFutbol;
GO
SET NOCOUNT ON;

DECLARE @id INT, @idf INT, @x INT;

/*Limpieza de restos de ejecuciones anteriores*/
SET @x = (SELECT MIN(id_posicion) FROM Mundial.Posicion WHERE abreviatura = 'TST' AND id_posicion > 0);
WHILE @x IS NOT NULL
BEGIN
    EXEC Mundial.usp_Posicion_Baja @x;
    SET @x = (SELECT MIN(id_posicion) FROM Mundial.Posicion WHERE abreviatura = 'TST' AND id_posicion > @x);
END

SET @x = (SELECT MIN(id_esquema) FROM Mundial.Esquema WHERE lineas IN ('3-4-3','3-3-4') AND id_esquema > 0);
WHILE @x IS NOT NULL
BEGIN
    EXEC Mundial.usp_Esquema_Baja @x;
    SET @x = (SELECT MIN(id_esquema) FROM Mundial.Esquema WHERE lineas IN ('3-4-3','3-3-4') AND id_esquema > @x);
END

SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE apellido LIKE 'Test%' AND id_cuerpo_tecnico > 0);
WHILE @x IS NOT NULL
BEGIN
    EXEC Mundial.usp_Cuerpo_tecnico_Baja @x;
    SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE apellido LIKE 'Test%' AND id_cuerpo_tecnico > @x);
END

/*POSICION*/
PRINT '=== POSICION ===';

PRINT 'P1 Alta valida. Esperado: 1 fila (Posicion Test / TST)';
EXEC Mundial.usp_Posicion_Alta 'Posicion Test', 'TST';
SELECT * FROM Mundial.Posicion WHERE abreviatura = 'TST';
SELECT @id = id_posicion FROM Mundial.Posicion WHERE abreviatura = 'TST';

PRINT 'P2 Alta duplicada. Esperado: "La posicion ya existe. La abreviatura ya existe."';
EXEC Mundial.usp_Posicion_Alta 'Posicion Test', 'TST';
SELECT COUNT(*) AS filas_TST FROM Mundial.Posicion WHERE abreviatura = 'TST';   -- Esperado: 1

PRINT 'P3 Alta con datos vacios. Esperado: "Nombre obligatorio. Abreviatura obligatoria."';
EXEC Mundial.usp_Posicion_Alta '', '';

PRINT 'P4 Modificacion valida. Esperado: nombre = Posicion Test 2';
EXEC Mundial.usp_Posicion_Modificacion @id, 'Posicion Test 2', 'TST';
SELECT * FROM Mundial.Posicion WHERE id_posicion = @id;

PRINT 'P5 Modificacion de inexistente. Esperado: "La posicion no existe."';
EXEC Mundial.usp_Posicion_Modificacion -1, 'Nada', 'NAD';

PRINT 'P6 Modificacion con abreviatura ajena (ARQ). Esperado: "Otra posicion ya tiene esa abreviatura."';
EXEC Mundial.usp_Posicion_Modificacion @id, 'Posicion Test 2', 'ARQ';

PRINT 'P7 Baja de inexistente. Esperado: "La posicion no existe."';
EXEC Mundial.usp_Posicion_Baja -1;

/*ESQUEMA*/
PRINT '=== ESQUEMA ===';

PRINT 'E1 Alta valida 3-4-3. Esperado: 1 fila';
EXEC Mundial.usp_Esquema_Alta '3-4-3';
SELECT * FROM Mundial.Esquema WHERE lineas = '3-4-3';
SELECT @id = id_esquema FROM Mundial.Esquema WHERE lineas = '3-4-3';

PRINT 'E2 Alta duplicada. Esperado: "El esquema ya existe."';
EXEC Mundial.usp_Esquema_Alta '3-4-3';

PRINT 'E3 Alta con formato invalido (abc). Esperado: "Formato invalido, usar numeros separados por guion (ej. 4-3-3)."';
EXEC Mundial.usp_Esquema_Alta 'abc';

PRINT 'E4 Alta vacia. Esperado: "El esquema es obligatorio."';
EXEC Mundial.usp_Esquema_Alta '';

PRINT 'E5 Modificacion valida 3-4-3 -> 3-3-4. Esperado: lineas = 3-3-4';
EXEC Mundial.usp_Esquema_Modificacion @id, '3-3-4';
SELECT * FROM Mundial.Esquema WHERE id_esquema = @id;

PRINT 'E6 Modificacion de inexistente. Esperado: "El esquema no existe."';
EXEC Mundial.usp_Esquema_Modificacion -1, '5-4-1';

PRINT 'E7 Modificacion con lineas de otro esquema (4-4-2). Esperado: "Otro esquema ya tiene esas lineas."';
EXEC Mundial.usp_Esquema_Modificacion @id, '4-4-2';

PRINT 'E8 Baja de inexistente. Esperado: "El esquema no existe."';
EXEC Mundial.usp_Esquema_Baja -1;

/*FORMACION / JUGADOR_FORMACION*/
PRINT '=== FORMACION y JUGADOR_FORMACION ===';

DECLARE @sel INT, @part INT, @jug INT, @noConv INT;
DECLARE @esq1 INT = (SELECT id_esquema FROM Mundial.Esquema WHERE lineas = '4-4-2');
DECLARE @esq2 INT = (SELECT id_esquema FROM Mundial.Esquema WHERE lineas = '4-3-3');
DECLARE @arq  INT = (SELECT id_posicion FROM Mundial.Posicion WHERE abreviatura = 'ARQ');

SELECT TOP 1 @sel = s.id
FROM Mundial.Seleccion s
WHERE EXISTS (SELECT * FROM Mundial.Lista_convocados l WHERE l.id_seleccion = s.id)
ORDER BY s.id;

SELECT TOP 1 @part = p.id
FROM Mundial.Partido p
WHERE NOT EXISTS (SELECT * FROM Mundial.Formacion f WHERE f.id_partido = p.id AND f.id_seleccion = @sel)
ORDER BY p.id;

SELECT TOP 1 @jug = id_jugador FROM Mundial.Lista_convocados WHERE id_seleccion = @sel ORDER BY id_jugador;

SELECT TOP 1 @noConv = j.id
FROM Mundial.Jugador j
WHERE NOT EXISTS (SELECT * FROM Mundial.Lista_convocados l WHERE l.id_seleccion = @sel AND l.id_jugador = j.id)
ORDER BY j.id;

IF @sel IS NULL OR @part IS NULL OR @jug IS NULL OR @esq1 IS NULL OR @esq2 IS NULL OR @arq IS NULL
    PRINT 'FALTAN DATOS: se necesita seleccion con convocados, partido sin formacion y el seed (seed_posiciones_y_esquemas.sql).';
ELSE
BEGIN
    PRINT 'F1 Alta valida. Esperado: 1 fila con esquema 4-4-2';
    EXEC Mundial.usp_Formacion_Alta @part, @sel, @esq1;
    SELECT * FROM Mundial.Formacion WHERE id_partido = @part AND id_seleccion = @sel;
    SELECT @idf = id_formacion FROM Mundial.Formacion WHERE id_partido = @part AND id_seleccion = @sel;

    PRINT 'F2 Alta duplicada. Esperado: "La seleccion ya tiene formacion en ese partido."';
    EXEC Mundial.usp_Formacion_Alta @part, @sel, @esq1;

    PRINT 'F3 Alta con partido, seleccion y esquema inexistentes. Esperado: "Partido inexistente. Seleccion inexistente. Esquema inexistente."';
    EXEC Mundial.usp_Formacion_Alta -1, -1, -1;

    PRINT 'F4 Modificacion valida. Esperado: esquema = 4-3-3';
    EXEC Mundial.usp_Formacion_Modificacion @idf, @esq2;
    SELECT f.id_formacion, e.lineas FROM Mundial.Formacion f JOIN Mundial.Esquema e ON e.id_esquema = f.id_esquema WHERE f.id_formacion = @idf;

    PRINT 'F5 Modificacion de inexistente con esquema inexistente. Esperado: "Formacion inexistente. Esquema inexistente."';
    EXEC Mundial.usp_Formacion_Modificacion -1, -1;

    PRINT 'JF1 Alta valida de jugador convocado como titular. Esperado: 1 fila, es_titular = 1';
    EXEC Mundial.usp_Jugador_Formacion_Alta @idf, @jug, @arq, 1;
    SELECT * FROM Mundial.Jugador_Formacion WHERE id_formacion = @idf;

    PRINT 'JF2 Jugador repetido. Esperado: "El jugador ya esta en la formacion."';
    EXEC Mundial.usp_Jugador_Formacion_Alta @idf, @jug, @arq, 1;

    PRINT 'JF3 Jugador no convocado por la seleccion. Esperado: "El jugador no esta convocado por la seleccion."';
    IF @noConv IS NULL PRINT 'FALTAN DATOS: todos los jugadores estan convocados por esa seleccion.';
    ELSE EXEC Mundial.usp_Jugador_Formacion_Alta @idf, @noConv, @arq, 1;

    PRINT 'JF4 Jugador y posicion inexistentes. Esperado: "Jugador inexistente. Posicion inexistente."';
    EXEC Mundial.usp_Jugador_Formacion_Alta @idf, -1, -1, 1;

    PRINT 'JF5 Formacion inexistente. Esperado: "Formacion inexistente."';
    EXEC Mundial.usp_Jugador_Formacion_Alta -1, @jug, @arq, 1;

    PRINT 'JF6 Modificacion valida a suplente. Esperado: es_titular = 0';
    EXEC Mundial.usp_Jugador_Formacion_Modificacion @idf, @jug, @arq, 0;
    SELECT * FROM Mundial.Jugador_Formacion WHERE id_formacion = @idf;

    PRINT 'JF7 Modificacion de jugador que no esta. Esperado: "El jugador no esta en la formacion."';
    EXEC Mundial.usp_Jugador_Formacion_Modificacion @idf, -1, @arq, 1;

    PRINT 'JF8 Intentar borrar posicion ARQ en uso. Esperado: "La posicion esta usada en formaciones."';
    EXEC Mundial.usp_Posicion_Baja @arq;

    PRINT 'JF9 Intentar borrar y modificar el esquema 4-3-3 en uso. Esperado: "El esquema esta en uso en formaciones." (dos veces)';
    EXEC Mundial.usp_Esquema_Baja @esq2;
    EXEC Mundial.usp_Esquema_Modificacion @esq2, '5-4-1';

    PRINT 'JF10 Baja valida del jugador. Esperado: 0 filas';
    EXEC Mundial.usp_Jugador_Formacion_Baja @idf, @jug;
    SELECT COUNT(*) AS filas FROM Mundial.Jugador_Formacion WHERE id_formacion = @idf;

    PRINT 'JF11 Baja de jugador que no esta. Esperado: "El jugador no esta en la formacion."';
    EXEC Mundial.usp_Jugador_Formacion_Baja @idf, @jug;

    PRINT 'F6 Baja de formacion con detalle (se borra detalle y cabecera). Esperado: 0 filas en ambas';
    EXEC Mundial.usp_Jugador_Formacion_Alta @idf, @jug, @arq, 1;
    EXEC Mundial.usp_Formacion_Baja @idf;
    SELECT COUNT(*) AS formaciones FROM Mundial.Formacion WHERE id_formacion = @idf;
    SELECT COUNT(*) AS detalle FROM Mundial.Jugador_Formacion WHERE id_formacion = @idf;

    PRINT 'F7 Baja de inexistente. Esperado: "Formacion inexistente."';
    EXEC Mundial.usp_Formacion_Baja @idf;
END

/*CUERPO TECNICO*/
PRINT '=== CUERPO TECNICO ===';

IF @sel IS NULL
    PRINT 'FALTAN DATOS: no hay selecciones.';
ELSE
BEGIN
    PRINT 'C1 Alta valida AYUDANTE. Esperado: 1 fila';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @sel, 'TestNombre', 'TestAyudante', 'AYUDANTE';
    SELECT * FROM Mundial.Cuerpo_tecnico WHERE apellido = 'TestAyudante';
    SELECT @id = id_cuerpo_tecnico FROM Mundial.Cuerpo_tecnico WHERE apellido = 'TestAyudante';

    PRINT 'C2 Alta invalida (nombre vacio, rol inexistente). Esperado: "Nombre obligatorio. Rol invalido (...)."';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @sel, '', 'TestOtro', 'ENTRENADOR';

    PRINT 'C3 Persona repetida. Esperado: "La persona ya esta en el cuerpo tecnico."';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @sel, 'TestNombre', 'TestAyudante', 'MEDICO';

    PRINT 'C4 Seleccion inexistente. Esperado: "Seleccion inexistente."';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta -1, 'TestNombre', 'TestOtro', 'AYUDANTE';

    PRINT 'C5 Segundo DT. Esperado: "La seleccion ya tiene director tecnico."';
    IF NOT EXISTS (SELECT * FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @sel AND rol = 'DT')
        EXEC Mundial.usp_Cuerpo_tecnico_Alta @sel, 'TestDT', 'TestDTUno', 'DT';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @sel, 'TestDT', 'TestDTDos', 'DT';

    PRINT 'C6 Modificacion valida a MEDICO. Esperado: rol = MEDICO';
    EXEC Mundial.usp_Cuerpo_tecnico_Modificacion @id, 'TestNombre', 'TestAyudante', 'MEDICO';
    SELECT * FROM Mundial.Cuerpo_tecnico WHERE id_cuerpo_tecnico = @id;

    PRINT 'C7 Modificacion de inexistente. Esperado: "Integrante inexistente."';
    EXEC Mundial.usp_Cuerpo_tecnico_Modificacion -1, 'TestNombre', 'TestX', 'MEDICO';

    PRINT 'C8 Baja valida. Esperado: 0 filas con TestAyudante';
    EXEC Mundial.usp_Cuerpo_tecnico_Baja @id;
    SELECT COUNT(*) AS filas FROM Mundial.Cuerpo_tecnico WHERE apellido = 'TestAyudante';

    PRINT 'C9 Baja de inexistente. Esperado: "Integrante inexistente."';
    EXEC Mundial.usp_Cuerpo_tecnico_Baja @id;

    -- Limpieza del DT de prueba (si se creo)
    SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE apellido LIKE 'Test%' AND id_cuerpo_tecnico > 0);
    WHILE @x IS NOT NULL
    BEGIN
        EXEC Mundial.usp_Cuerpo_tecnico_Baja @x;
        SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE apellido LIKE 'Test%' AND id_cuerpo_tecnico > @x);
    END
END

/*ESPACIO PUBLICITARIO*/
PRINT '=== ESPACIO PUBLICITARIO ===';

DECLARE @sede INT = (SELECT TOP 1 id FROM Mundial.Sede ORDER BY id);
DECLARE @pais INT = (SELECT TOP 1 id_pais FROM Mundial.Pais ORDER BY id_pais);

IF @sede IS NULL
    PRINT 'FALTAN DATOS: no hay sedes.';
ELSE
BEGIN
    -- Se vacian los espacios de la sede para probar desde cero (con bucle WHILE).
    SET @x = (SELECT MIN(id_espacio) FROM Mundial.Espacio_publicitario WHERE id_sede = @sede AND id_espacio > 0);
    WHILE @x IS NOT NULL
    BEGIN
        EXEC Mundial.usp_Espacio_publicitario_Baja @x;
        SET @x = (SELECT MIN(id_espacio) FROM Mundial.Espacio_publicitario WHERE id_sede = @sede AND id_espacio > @x);
    END

    PRINT 'S1 Alta valida nro 1. Esperado: 1 fila';
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 1, 'Panel de prueba', NULL;
    SELECT * FROM Mundial.Espacio_publicitario WHERE id_sede = @sede;
    SELECT @id = id_espacio FROM Mundial.Espacio_publicitario WHERE id_sede = @sede AND numero_espacio = 1;

    PRINT 'S2 Numero repetido. Esperado: "La sede ya tiene ese numero de espacio."';
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 1, 'Duplicado', NULL;

    PRINT 'S3 Numero fuera de rango (5). Esperado: "El numero de espacio debe ser de 1 a 4."';
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 5, 'Fuera de rango', NULL;

    PRINT 'S4 Sede inexistente. Esperado: "Sede inexistente."';
    EXEC Mundial.usp_Espacio_publicitario_Alta -1, 2, 'Sin sede', NULL;

    PRINT 'S5 Pais de interes inexistente. Esperado: "Pais de interes inexistente."';
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 2, 'Pais invalido', -1;

    PRINT 'S6 Altas 2, 3 y 4 con pais valido. Esperado: 4 filas en total';
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 2, 'Panel 2', @pais;
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 3, 'Panel 3', @pais;
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 4, 'Panel 4', @pais;
    SELECT * FROM Mundial.Espacio_publicitario WHERE id_sede = @sede ORDER BY numero_espacio;

    PRINT 'S7 Quinto espacio con la sede completa. Esperado: "La sede ya tiene ese numero de espacio. La sede ya tiene los 4 espacios."';
    EXEC Mundial.usp_Espacio_publicitario_Alta @sede, 1, 'Extra', NULL;

    PRINT 'S8 Modificacion valida. Esperado: descripcion = Panel modificado';
    EXEC Mundial.usp_Espacio_publicitario_Modificacion @id, 'Panel modificado', NULL;
    SELECT * FROM Mundial.Espacio_publicitario WHERE id_espacio = @id;

    PRINT 'S9 Modificacion de inexistente. Esperado: "Espacio inexistente."';
    EXEC Mundial.usp_Espacio_publicitario_Modificacion -1, 'X', NULL;

    PRINT 'S10 Baja valida y baja de inexistente. Esperado: se borra el espacio 1 y luego "Espacio inexistente."';
    EXEC Mundial.usp_Espacio_publicitario_Baja @id;
    EXEC Mundial.usp_Espacio_publicitario_Baja @id;
    SELECT COUNT(*) AS filas FROM Mundial.Espacio_publicitario WHERE id_sede = @sede;   -- Esperado: 3
END

/*Baja valida final de Posicion y Esquema de prueba*/
PRINT 'P8 Baja valida de Posicion Test. Esperado: 0 filas con TST';
SELECT @id = id_posicion FROM Mundial.Posicion WHERE abreviatura = 'TST';
EXEC Mundial.usp_Posicion_Baja @id;
SELECT COUNT(*) AS filas FROM Mundial.Posicion WHERE abreviatura = 'TST';

PRINT 'E9 Baja valida del esquema de prueba. Esperado: 0 filas con 3-3-4';
SELECT @id = id_esquema FROM Mundial.Esquema WHERE lineas = '3-3-4';
EXEC Mundial.usp_Esquema_Baja @id;
SELECT COUNT(*) AS filas FROM Mundial.Esquema WHERE lineas = '3-3-4';
GO
