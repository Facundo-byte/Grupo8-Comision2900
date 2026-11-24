/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Importación de sedes y partidos desde archivos XML.
*/

-- Instalo los SP y la tabla de registro en la base del TP.
USE MundialDeFutbol;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Acá quedan los resultados por registro y el historial de los cambios.
-- Creo la tabla solo si todavía no existe.
IF OBJECT_ID('Mundial.ImportacionXML', 'U') IS NULL
BEGIN
    CREATE TABLE Mundial.ImportacionXML (
        id_log INT IDENTITY PRIMARY KEY,
        ejecucion UNIQUEIDENTIFIER NOT NULL,
        archivo NVARCHAR(1024) NOT NULL,
        tipo VARCHAR(8) NOT NULL,
        referencia NVARCHAR(250) NULL,
        fecha DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        estado VARCHAR(15) NOT NULL,
        id_registro INT NULL,
        detalle NVARCHAR(2048) NULL,
        datos_anteriores NVARCHAR(MAX) NULL,
        datos_nuevos NVARCHAR(MAX) NULL
    );
END;
GO

CREATE OR ALTER PROCEDURE Mundial.sp_ImportarSedesXML
    @RutaArchivo NVARCHAR(1024)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET ANSI_PADDING ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    IF @@TRANCOUNT <> 0
        THROW 51100, N'Ejecutá la importación sin una transacción abierta.', 1;
    IF NULLIF(TRIM(@RutaArchivo), N'') IS NULL
        THROW 51101, N'Indicá la ruta del XML de sedes.', 1;

    DECLARE @ejecucion UNIQUEIDENTIFIER = NEWID(), @documento XML;
    -- SINGLE_BLOB conserva la codificación declarada por el archivo.
    DECLARE @sql NVARCHAR(MAX) = N'SELECT @xml = CONVERT(XML, BulkColumn)
        FROM OPENROWSET(BULK N''' + REPLACE(@RutaArchivo, N'''', N'''''') + N''', SINGLE_BLOB) AS origen;';

    CREATE TABLE #SedesXML (
        fila INT IDENTITY(1,1) PRIMARY KEY,
        estadio NVARCHAR(MAX),
        ciudad NVARCHAR(MAX),
        pais NVARCHAR(MAX),
        capacidad NVARCHAR(MAX),
        huso NVARCHAR(MAX),
        latitud NVARCHAR(MAX),
        longitud NVARCHAR(MAX)
    );

    BEGIN TRY
        EXEC sys.sp_executesql @sql, N'@xml XML OUTPUT', @xml = @documento OUTPUT;
        -- La raíz identifica el dataset. Cada registro es un elemento con atributos.
        IF @documento IS NULL OR @documento.exist('/sedes') = 0
            OR @documento.exist('/*[2]') = 1
            OR @documento.value('count(/sedes/*)', 'int') <> @documento.value('count(/sedes/sede)', 'int')
            OR @documento.exist('/sedes/sede/*') = 1
            OR @documento.exist('//text()') = 1
            THROW 51106, N'Se esperaba una raíz <sedes> con registros <sede> y campos como atributos.', 1;

        INSERT INTO #SedesXML (estadio, ciudad, pais, capacidad, huso, latitud, longitud)
        SELECT
            TRIM(registro.value('(@nombre_estadio)[1]', 'nvarchar(max)')),
            TRIM(registro.value('(@ciudad)[1]', 'nvarchar(max)')),
            TRIM(registro.value('(@pais)[1]', 'nvarchar(max)')),
            TRIM(registro.value('(@capacidad)[1]', 'nvarchar(max)')),
            TRIM(registro.value('(@huso_horario)[1]', 'nvarchar(max)')),
            NULLIF(TRIM(registro.value('(@latitud)[1]', 'nvarchar(max)')), N''),
            NULLIF(TRIM(registro.value('(@longitud)[1]', 'nvarchar(max)')), N'')
        FROM @documento.nodes('/sedes/sede') AS filas(registro);
    END TRY
    BEGIN CATCH
        INSERT INTO Mundial.ImportacionXML (ejecucion, archivo, tipo, estado, detalle)
        VALUES (@ejecucion, @RutaArchivo, 'Sedes', 'ERROR ARCHIVO', LEFT(ERROR_MESSAGE(), 2048));
        THROW;
    END CATCH;

    DECLARE @fila INT = 1;
    DECLARE @ultimaFila INT = (SELECT COUNT(*) FROM #SedesXML);

    -- Reutilizo las variables en cada vuelta. Separo el texto del XML de los números y los IDs.
    DECLARE @estadio NVARCHAR(MAX), @ciudad NVARCHAR(MAX), @pais NVARCHAR(MAX), @huso NVARCHAR(MAX);
    DECLARE @capacidadTexto NVARCHAR(MAX), @latitudTexto NVARCHAR(MAX), @longitudTexto NVARCHAR(MAX);
    DECLARE @capacidad INT, @latitud DECIMAL(9,6), @longitud DECIMAL(9,6), @idPais INT, @idSede INT;
    DECLARE @antes NVARCHAR(MAX), @despues NVARCHAR(MAX), @estado VARCHAR(15);

    -- Uso el WHILE porque los ABM reciben una sola sede por llamada.
    WHILE @fila <= @ultimaFila
    BEGIN
        SELECT @estadio = estadio, @ciudad = ciudad, @pais = pais, @huso = huso,
            @capacidadTexto = capacidad, @latitudTexto = latitud, @longitudTexto = longitud
        FROM #SedesXML WHERE fila = @fila;

        BEGIN TRY
            -- Convierto la capacidad y las coordenadas. Si hay texto donde va un número, paso al CATCH.
            SET @capacidad = CONVERT(INT, NULLIF(@capacidadTexto, N''));
            SET @latitud = CONVERT(DECIMAL(9,6), @latitudTexto);
            SET @longitud = CONVERT(DECIMAL(9,6), @longitudTexto);
            -- Limpio el valor anterior para que no quede el de otra sede.
            SET @antes = NULL;

            -- La sede, un posible país nuevo y su registro de auditoría se confirman juntos.
            BEGIN TRANSACTION;

            -- El seed tiene México y Canadá, y el XML los trae sin tilde.
            SET @idPais = (SELECT id_pais FROM Mundial.Pais WITH (UPDLOCK, HOLDLOCK)
                WHERE nombre COLLATE Latin1_General_100_CI_AI = @pais);
            IF @idPais IS NULL
            BEGIN
                -- altaPais recibe VARCHAR(30). Evito que se corte un nombre largo.
                IF DATALENGTH(CONVERT(VARCHAR(MAX), @pais)) > 30
                    THROW 51102, N'El nombre del país supera el largo que admite altaPais.', 1;
                EXEC MfSPabm.altaPais @nombrePais = @pais;
                SELECT @idPais = id_pais FROM Mundial.Pais WHERE nombre = @pais;
            END;

            -- Busco la sede por estadio, ciudad y país. Mantengo los bloqueos para evitar altas duplicadas.
            SET @idSede = (SELECT id_sede FROM Mundial.Sede WITH (UPDLOCK, HOLDLOCK)
                WHERE nombre_estadio = @estadio AND ciudad = @ciudad AND id_pais = @idPais);

            -- Si es nueva, el ABM de alta devuelve el ID. Si existe, guardo sus datos antes de modificarla.
            IF @idSede IS NULL
                EXEC Mundial.Sede_Alta @nombre_estadio = @estadio, @ciudad = @ciudad, @id_pais = @idPais,
                    @capacidad = @capacidad, @huso_horario = @huso, @latitud = @latitud,
                    @longitud = @longitud, @id_sede = @idSede OUTPUT;
            ELSE
            BEGIN
                SET @antes = (SELECT * FROM Mundial.Sede WHERE id_sede = @idSede
                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER);
                EXEC Mundial.Sede_Modificar @id_sede = @idSede, @nombre_estadio = @estadio,
                    @ciudad = @ciudad, @id_pais = @idPais, @capacidad = @capacidad,
                    @huso_horario = @huso, @latitud = @latitud, @longitud = @longitud;
            END;

            -- Comparo lo que quedó guardado con la versión anterior. FOR JSON arma texto para el historial.
            SET @despues = (SELECT * FROM Mundial.Sede WHERE id_sede = @idSede
                FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER);
            SET @estado = CASE
                WHEN @antes IS NULL THEN 'INSERTADO'
                WHEN @antes COLLATE Latin1_General_100_BIN2 = @despues COLLATE Latin1_General_100_BIN2 THEN 'SIN CAMBIOS'
                ELSE 'ACTUALIZADO' END;

            -- Registro el resultado de la fila. Guardo ambas versiones cuando hubo un cambio.
            INSERT INTO Mundial.ImportacionXML
                (ejecucion, archivo, tipo, referencia, estado, id_registro, datos_anteriores, datos_nuevos)
            VALUES (@ejecucion, @RutaArchivo, 'Sedes', LEFT(@estadio, 250), @estado, @idSede,
                CASE WHEN @estado = 'ACTUALIZADO' THEN @antes END,
                CASE WHEN @estado = 'ACTUALIZADO' THEN @despues END);

            -- Confirmo los cambios de esta fila una vez que también quedó registrada.
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            -- Si había una transacción abierta, deshago esta fila. Después registro el motivo del rechazo.
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            INSERT INTO Mundial.ImportacionXML (ejecucion, archivo, tipo, referencia, estado, detalle)
            VALUES (@ejecucion, @RutaArchivo, 'Sedes', LEFT(@estadio, 250), 'RECHAZADO', LEFT(ERROR_MESSAGE(), 2048));
        END CATCH;

        -- Avanzo tanto si la sede se guardó como si fue rechazada.
        SET @fila += 1;
    END;

    -- Devuelvo las cantidades por estado y los motivos de rechazo de esta ejecución.
    SELECT @ejecucion AS ejecucion, estado, COUNT(*) AS cantidad
    FROM Mundial.ImportacionXML WHERE ejecucion = @ejecucion GROUP BY estado;
    SELECT referencia, detalle FROM Mundial.ImportacionXML
    WHERE ejecucion = @ejecucion AND estado = 'RECHAZADO' ORDER BY id_log;
END;
GO

CREATE OR ALTER PROCEDURE Mundial.sp_ImportarPartidosXML
    @RutaArchivo NVARCHAR(1024)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET ANSI_PADDING ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    IF @@TRANCOUNT <> 0
        THROW 51100, N'Ejecutá la importación sin una transacción abierta.', 1;
    IF NULLIF(TRIM(@RutaArchivo), N'') IS NULL
        THROW 51101, N'Indicá la ruta del XML de partidos.', 1;

    DECLARE @ejecucion UNIQUEIDENTIFIER = NEWID(), @documento XML;
    -- SINGLE_BLOB conserva la codificación declarada por el archivo.
    DECLARE @sql NVARCHAR(MAX) = N'SELECT @xml = CONVERT(XML, BulkColumn)
        FROM OPENROWSET(BULK N''' + REPLACE(@RutaArchivo, N'''', N'''''') + N''', SINGLE_BLOB) AS origen;';

    CREATE TABLE #PartidosXML (
        fila INT IDENTITY(1,1) PRIMARY KEY,
        estadio NVARCHAR(MAX),
        pais_local NVARCHAR(MAX),
        pais_visitante NVARCHAR(MAX),
        fecha_utc NVARCHAR(MAX),
        offset_min NVARCHAR(MAX),
        goles_local NVARCHAR(MAX),
        goles_visitante NVARCHAR(MAX),
        asistencia NVARCHAR(MAX),
        fase NVARCHAR(MAX)
    );

    BEGIN TRY
        EXEC sys.sp_executesql @sql, N'@xml XML OUTPUT', @xml = @documento OUTPUT;
        -- La raíz identifica el dataset. Cada registro es un elemento con atributos.
        IF @documento IS NULL OR @documento.exist('/partidos') = 0
            OR @documento.exist('/*[2]') = 1
            OR @documento.value('count(/partidos/*)', 'int') <> @documento.value('count(/partidos/partido)', 'int')
            OR @documento.exist('/partidos/partido/*') = 1
            OR @documento.exist('//text()') = 1
            THROW 51106, N'Se esperaba una raíz <partidos> con registros <partido> y campos como atributos.', 1;

        INSERT INTO #PartidosXML (estadio, pais_local, pais_visitante, fecha_utc, offset_min, goles_local, goles_visitante, asistencia, fase)
        SELECT
            TRIM(registro.value('(@estadio)[1]', 'nvarchar(max)')),
            TRIM(registro.value('(@pais_local)[1]', 'nvarchar(max)')),
            TRIM(registro.value('(@pais_visitante)[1]', 'nvarchar(max)')),
            NULLIF(TRIM(registro.value('(@fecha_utc)[1]', 'nvarchar(max)')), N''),
            NULLIF(TRIM(registro.value('(@offset_min)[1]', 'nvarchar(max)')), N''),
            NULLIF(TRIM(registro.value('(@goles_local)[1]', 'nvarchar(max)')), N''),
            NULLIF(TRIM(registro.value('(@goles_visitante)[1]', 'nvarchar(max)')), N''),
            NULLIF(TRIM(registro.value('(@asistencia)[1]', 'nvarchar(max)')), N''),
            LOWER(TRIM(registro.value('(@fase)[1]', 'nvarchar(max)')))
        FROM @documento.nodes('/partidos/partido') AS filas(registro);
    END TRY
    BEGIN CATCH
        INSERT INTO Mundial.ImportacionXML (ejecucion, archivo, tipo, estado, detalle)
        VALUES (@ejecucion, @RutaArchivo, 'Partidos', 'ERROR ARCHIVO', LEFT(ERROR_MESSAGE(), 2048));
        THROW;
    END CATCH;

    DECLARE @fila INT = 1, @ultimaFila INT;
    SELECT @ultimaFila = ISNULL(MAX(fila), 0) FROM #PartidosXML;

    -- Preparo variables para el texto del XML, los datos convertidos y los IDs de la base.
    DECLARE @estadio NVARCHAR(MAX), @local NVARCHAR(MAX), @visitante NVARCHAR(MAX), @fase NVARCHAR(MAX);
    DECLARE @fechaTexto NVARCHAR(MAX), @offsetTexto NVARCHAR(MAX), @golesLocalTexto NVARCHAR(MAX);
    DECLARE @golesVisitanteTexto NVARCHAR(MAX), @asistenciaTexto NVARCHAR(MAX), @referencia NVARCHAR(250);
    DECLARE @fechaUTC DATETIME, @fechaLocal DATETIME, @offset INT, @golesLocal INT, @golesVisitante INT, @asistencia INT;
    DECLARE @idSede INT, @idLocal INT, @idVisitante INT, @idPartido INT;
    DECLARE @antes NVARCHAR(MAX), @despues NVARCHAR(MAX), @estado VARCHAR(15);

    -- Uso una vuelta por partido para llamar al ABM de alta o modificación.
    WHILE @fila <= @ultimaFila
    BEGIN
        SELECT @estadio = estadio, @local = pais_local, @visitante = pais_visitante, @fase = fase,
            @fechaTexto = fecha_utc, @offsetTexto = offset_min, @golesLocalTexto = goles_local,
            @golesVisitanteTexto = goles_visitante, @asistenciaTexto = asistencia
        FROM #PartidosXML WHERE fila = @fila;

        -- Uso los equipos y la fecha para poder identificar la fila en el registro de importación.
        SET @referencia = LEFT(CONCAT(@local, N' vs ', @visitante, N' | ', @fechaTexto), 250);
        BEGIN TRY
            -- Convierto la fecha UTC y le sumo el desfase en minutos para obtener la hora local.
            SET @fechaUTC = CONVERT(DATETIME, @fechaTexto, 120);
            SET @offset = CONVERT(INT, @offsetTexto);
            IF @offset IS NULL OR @offset NOT BETWEEN -840 AND 840
                THROW 51104, N'El offset debe estar entre -840 y 840 minutos.', 1;
            SET @fechaLocal = DATEADD(MINUTE, @offset, @fechaUTC);
            -- Convierto goles y asistencia. Si venían vacíos, quedan en NULL.
            SET @golesLocal = CONVERT(INT, @golesLocalTexto);
            SET @golesVisitante = CONVERT(INT, @golesVisitanteTexto);
            SET @asistencia = CONVERT(INT, @asistenciaTexto);
            SET @antes = NULL;

            -- El partido y el resultado de su importación se confirman en la misma transacción.
            BEGIN TRANSACTION;

            -- El XML trae el nombre del estadio y el ABM necesita su ID.
            SET @idSede = (SELECT id_sede FROM Mundial.Sede WHERE nombre_estadio = @estadio);
            IF @idSede IS NULL THROW 51105, N'El estadio no está cargado.', 1;

            -- Busco el ID de cada selección a partir del nombre del país, sin distinguir tildes.
            SET @idLocal = (SELECT s.id_seleccion FROM Mundial.Seleccion s
                JOIN Mundial.Pais p ON p.id_pais = s.id_pais WHERE p.nombre COLLATE Latin1_General_100_CI_AI = @local);
            SET @idVisitante = (SELECT s.id_seleccion FROM Mundial.Seleccion s
                JOIN Mundial.Pais p ON p.id_pais = s.id_pais WHERE p.nombre COLLATE Latin1_General_100_CI_AI = @visitante);

            -- Uso las dos selecciones y la fecha y hora UTC para reconocer el partido.
            -- Mantengo los bloqueos durante el alta o la modificación para evitar duplicados entre cargas.
            SET @idPartido = (SELECT id_partido FROM Mundial.Partido WITH (UPDLOCK, HOLDLOCK)
                WHERE id_seleccion_local = @idLocal AND id_seleccion_visitante = @idVisitante
                    AND fecha_hora_utc = @fechaUTC);

            -- Llamo al alta si es nuevo. Si ya existe, guardo su estado anterior y llamo a modificar.
            IF @idPartido IS NULL
                EXEC Mundial.Partido_Alta @id_sede = @idSede, @id_seleccion_local = @idLocal,
                    @id_seleccion_visitante = @idVisitante, @fecha_hora_local = @fechaLocal,
                    @fecha_hora_utc = @fechaUTC, @goles_local = @golesLocal, @goles_visitante = @golesVisitante,
                    @asistencia = @asistencia, @fase = @fase, @id_partido = @idPartido OUTPUT;
            ELSE
            BEGIN
                SET @antes = (SELECT * FROM Mundial.Partido WHERE id_partido = @idPartido
                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER);
                EXEC Mundial.Partido_Modificar @id_partido = @idPartido, @id_sede = @idSede,
                    @id_seleccion_local = @idLocal, @id_seleccion_visitante = @idVisitante,
                    @fecha_hora_local = @fechaLocal, @fecha_hora_utc = @fechaUTC, @goles_local = @golesLocal,
                    @goles_visitante = @golesVisitante, @asistencia = @asistencia, @fase = @fase;
            END;

            -- Leo cómo quedó el partido y lo comparo con lo que había antes del ABM.
            SET @despues = (SELECT * FROM Mundial.Partido WHERE id_partido = @idPartido
                FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER);
            SET @estado = CASE
                WHEN @antes IS NULL THEN 'INSERTADO'
                WHEN @antes COLLATE Latin1_General_100_BIN2 = @despues COLLATE Latin1_General_100_BIN2 THEN 'SIN CAMBIOS'
                ELSE 'ACTUALIZADO' END;

            -- Anoto el resultado y guardo los dos estados del partido si hubo cambios.
            INSERT INTO Mundial.ImportacionXML
                (ejecucion, archivo, tipo, referencia, estado, id_registro, datos_anteriores, datos_nuevos)
            VALUES (@ejecucion, @RutaArchivo, 'Partidos', @referencia, @estado, @idPartido,
                CASE WHEN @estado = 'ACTUALIZADO' THEN @antes END,
                CASE WHEN @estado = 'ACTUALIZADO' THEN @despues END);

            -- Confirmo esta fila cuando el ABM y el registro de importación salieron bien.
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            -- Deshago lo pendiente de esta fila, guardo el error y dejo que el bucle siga.
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            INSERT INTO Mundial.ImportacionXML (ejecucion, archivo, tipo, referencia, estado, detalle)
            VALUES (@ejecucion, @RutaArchivo, 'Partidos', @referencia, 'RECHAZADO', LEFT(ERROR_MESSAGE(), 2048));
        END CATCH;

        -- Paso al siguiente partido aunque el anterior haya sido rechazado.
        SET @fila += 1;
    END;

    -- Muestro las cantidades agrupadas por resultado.
    SELECT @ejecucion AS ejecucion, estado, COUNT(*) AS cantidad
    FROM Mundial.ImportacionXML WHERE ejecucion = @ejecucion GROUP BY estado;
    -- El segundo resultado muestra qué partido se rechazó y por qué.
    SELECT referencia, detalle FROM Mundial.ImportacionXML
    WHERE ejecucion = @ejecucion AND estado = 'RECHAZADO' ORDER BY id_log;
END;
GO

/* Ejemplo en SSMS. Cargar primero las selecciones del script 28.
   La cuenta del servicio de SQL Server necesita acceso de lectura a datasets.

EXEC Mundial.sp_ImportarSedesXML
    @RutaArchivo = N'E:\Desktop\Cosas\Tareas_UNLAM\Bases de Datos aplicadas\TP 2026\Grupo8-Comision2900\datasets\sedes_mundial_2026.xml';

EXEC Mundial.sp_ImportarPartidosXML
    @RutaArchivo = N'E:\Desktop\Cosas\Tareas_UNLAM\Bases de Datos aplicadas\TP 2026\Grupo8-Comision2900\datasets\partidos_mundial_2026.xml';

SELECT * FROM Mundial.ImportacionXML ORDER BY id_log DESC;
*/
