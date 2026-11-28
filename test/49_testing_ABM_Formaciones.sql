/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Testing de los Stored Procedures ABM de Posicion, Esquema, Formacion, Jugador_Formacion, Cuerpo_tecnico y Espacio_publicitario
*/

USE MundialDeFutbol;
GO
SET NOCOUNT ON;

DECLARE @id INT, @idf INT, @x INT;

-- Limpieza de restos de ejecuciones anteriores
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

-- POSICION
PRINT '=== POSICION ===';

PRINT 'P1 Alta valida. Esperado: 1 fila (Posicion Test / TST)';
EXEC Mundial.usp_Posicion_Alta 'Posicion Test', 'TST';
SELECT * FROM Mundial.Posicion WHERE abreviatura = 'TST';
SELECT @id = id_posicion FROM Mundial.Posicion WHERE abreviatura = 'TST';

PRINT 'P2 Alta duplicada. Esperado: "La posicion ya existe. La abreviatura ya existe."';
EXEC Mundial.usp_Posicion_Alta 'Posicion Test', 'TST';
SELECT COUNT(*) AS filas_TST FROM Mundial.Posicion WHERE abreviatura = 'TST'; -- Esperado: 1

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

-- ESQUEMA
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

-- FORMACION / JUGADOR_FORMACION
PRINT '=== FORMACION y JUGADOR_FORMACION ===';

DECLARE @sel INT, @part INT, @jug INT, @noConv INT;
DECLARE @esq1 INT = (SELECT id_esquema FROM Mundial.Esquema WHERE lineas = '4-4-2');
DECLARE @esq2 INT = (SELECT id_esquema FROM Mundial.Esquema WHERE lineas = '4-3-3');
DECLARE @arq  INT = (SELECT id_posicion FROM Mundial.Posicion WHERE abreviatura = 'ARQ');

SELECT TOP 1 @sel = s.id_seleccion
FROM Mundial.Seleccion s
JOIN Mundial.ListaConvocados lc ON lc.id_seleccion = s.id_seleccion
JOIN Mundial.Jugador j ON j.id_lista_convocados = lc.id_lista
ORDER BY s.id_seleccion;

SELECT TOP 1 @part = p.id_partido
FROM Mundial.Partido p
WHERE (p.id_seleccion_local = @sel OR p.id_seleccion_visitante = @sel)
  AND NOT EXISTS (SELECT 1 FROM Mundial.Formacion f WHERE f.id_partido = p.id_partido AND f.id_seleccion = @sel)
ORDER BY p.id_partido;

SELECT TOP 1 @jug = j.id_jugador
FROM Mundial.Jugador j
JOIN Mundial.ListaConvocados lc ON j.id_lista_convocados = lc.id_lista
WHERE lc.id_seleccion = @sel
ORDER BY j.id_jugador;

SELECT TOP 1 @noConv = j.id_jugador
FROM Mundial.Jugador j
JOIN Mundial.ListaConvocados lc ON j.id_lista_convocados = lc.id_lista
WHERE lc.id_seleccion <> @sel
ORDER BY j.id_jugador;

IF @sel IS NULL OR @part IS NULL OR @jug IS NULL OR @esq1 IS NULL OR @esq2 IS NULL OR @arq IS NULL
    PRINT 'FALTAN DATOS: se necesita seleccion con convocados, partido donde juegue esa seleccion sin formacion y el seed (32_seed_posiciones_y_esquemas.sql).';
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

-- CUERPO TECNICO
PRINT '=== CUERPO TECNICO ===';

DECLARE @selCTTest INT = (SELECT TOP 1 id_seleccion FROM Mundial.Seleccion ORDER BY id_seleccion);

IF @selCTTest IS NULL
    PRINT 'FALTAN DATOS: no hay selecciones.';
ELSE
BEGIN
    PRINT 'C1 Alta valida AYUDANTE. Esperado: 1 fila';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @selCTTest, 'TestNombre', 'TestAyudante', 'AYUDANTE';
    SELECT * FROM Mundial.Cuerpo_tecnico WHERE apellido = 'TestAyudante';
    SELECT @id = id_cuerpo_tecnico FROM Mundial.Cuerpo_tecnico WHERE apellido = 'TestAyudante';

    PRINT 'C2 Alta invalida (nombre vacio, rol inexistente). Esperado: "Nombre obligatorio. Rol invalido (...)."';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @selCTTest, '', 'TestOtro', 'ENTRENADOR';

    PRINT 'C3 Persona repetida. Esperado: "La persona ya esta en el cuerpo tecnico."';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @selCTTest, 'TestNombre', 'TestAyudante', 'MEDICO';

    PRINT 'C4 Seleccion inexistente. Esperado: "Seleccion inexistente."';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta -1, 'TestNombre', 'TestOtro', 'AYUDANTE';

    PRINT 'C5 Segundo DT. Esperado: "La seleccion ya tiene director tecnico."';
    IF NOT EXISTS (SELECT 1 FROM Mundial.Cuerpo_tecnico WHERE id_seleccion = @selCTTest AND rol = 'DT')
        EXEC Mundial.usp_Cuerpo_tecnico_Alta @selCTTest, 'TestDT', 'TestDTUno', 'DT';
    EXEC Mundial.usp_Cuerpo_tecnico_Alta @selCTTest, 'TestDT', 'TestDTDos', 'DT';

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

    SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE apellido LIKE 'Test%' AND id_cuerpo_tecnico > 0);
    WHILE @x IS NOT NULL
    BEGIN
        EXEC Mundial.usp_Cuerpo_tecnico_Baja @x;
        SET @x = (SELECT MIN(id_cuerpo_tecnico) FROM Mundial.Cuerpo_tecnico WHERE apellido LIKE 'Test%' AND id_cuerpo_tecnico > @x);
    END
END

-- ESPACIO PUBLICITARIO
PRINT '=== ESPACIO PUBLICITARIO ===';

DECLARE @sede INT = (SELECT TOP 1 id_sede FROM Mundial.Sede ORDER BY id_sede);
IF @sede IS NULL
    PRINT 'FALTAN DATOS: no hay sedes.';
ELSE
BEGIN
    SELECT @id = id_espacio FROM Mundial.Espacio_publicitario
    WHERE id_sede = @sede AND numero_espacio = 1;

    PRINT 'S1 Alta duplicada y quinto espacio: se esperan rechazos.';
    EXEC MfSPabm.usp_Espacio_publicitario_Alta @sede, 1;
    EXEC MfSPabm.usp_Espacio_publicitario_Alta @sede, 5;

    PRINT 'S2 Cambio de descripcion y baja individual: se conservan los cuatro paneles.';
    BEGIN TRANSACTION;
    EXEC MfSPabm.usp_Espacio_publicitario_Modificacion @id, 'Panel modificado';
    EXEC MfSPabm.usp_Espacio_publicitario_Baja @id;
    SELECT numero_espacio, descripcion FROM Mundial.Espacio_publicitario
    WHERE id_sede = @sede ORDER BY numero_espacio;
    ROLLBACK TRANSACTION;
END

-- Baja valida final de Posicion y Esquema de prueba
PRINT 'P8 Baja valida de Posicion Test. Esperado: 0 filas con TST';
SELECT @id = id_posicion FROM Mundial.Posicion WHERE abreviatura = 'TST';
EXEC Mundial.usp_Posicion_Baja @id;
SELECT COUNT(*) AS filas FROM Mundial.Posicion WHERE abreviatura = 'TST';

PRINT 'E9 Baja valida del esquema de prueba. Esperado: 0 filas con 3-3-4';
SELECT @id = id_esquema FROM Mundial.Esquema WHERE lineas = '3-3-4';
EXEC Mundial.usp_Esquema_Baja @id;
SELECT COUNT(*) AS filas FROM Mundial.Esquema WHERE lineas = '3-3-4';
GO
