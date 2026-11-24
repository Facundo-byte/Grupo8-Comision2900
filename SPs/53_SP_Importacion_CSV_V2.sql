/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Importación de sedes y partidos con BULK INSERT.
*/

-- Instalo los SP y la tabla de registro en la base del TP.
USE MundialDeFutbol;
GO

-- Acá quedan los resultados por registro y el historial de los cambios.
-- Creo la tabla solo si todavía no existe.
IF OBJECT_ID('Mundial.ImportacionCSV_V2', 'U') IS NULL
BEGIN
    CREATE TABLE Mundial.ImportacionCSV_V2 (
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

-- Importación de sedes. 
CREATE OR ALTER PROCEDURE Mundial.sp_ImportarSedesCSV_V2
    @RutaArchivo NVARCHAR(1024),
    @RutaErrores NVARCHAR(1024) = NULL
AS
BEGIN
    -- Cada fila tiene su propia transacción. Un ROLLBACK no debe alcanzar trabajo ajeno al SP.
    IF @@TRANCOUNT <> 0
        THROW 51100, N'Ejecutá la importación sin una transacción abierta.', 1;
    IF NULLIF(TRIM(@RutaArchivo), N'') IS NULL
        THROW 51101, N'Indicá la ruta del CSV de sedes.', 1;
    -- Ante un error de ejecución, XACT_ABORT evita que se pueda confirmar una operación a medias.
    SET XACT_ABORT ON;

    -- Cargo todo como texto. Si una conversión falla, puedo registrar esa fila y seguir.
    CREATE TABLE #SedesCSV (
        estadio NVARCHAR(MAX),
        ciudad NVARCHAR(MAX),
        pais NVARCHAR(MAX),
        capacidad NVARCHAR(MAX),
        huso NVARCHAR(MAX),
        latitud NVARCHAR(MAX),
        longitud NVARCHAR(MAX)
    );

    -- Uso el mismo identificador para agrupar todos los resultados de esta carga.
    DECLARE @ejecucion UNIQUEIDENTIFIER = NEWID();
    -- BULK INSERT requiere la ruta escrita en el comando, así que lo armo como texto.
    -- La ruta va entre comillas. Si tiene una comilla simple, la duplico.
    -- Leo un CSV en UTF-8, con comas entre campos y un salto de línea LF entre registros.
    DECLARE @sql NVARCHAR(MAX) = N'BULK INSERT #SedesCSV FROM '''
        + REPLACE(@RutaArchivo, '''', '''''') + N'''
        WITH (FORMAT = ''CSV'', FIELDTERMINATOR = '','',
              ROWTERMINATOR = ''0x0A''';

	-- Aca leo el archivo CSV
    BEGIN TRY
        -- Leo primero el encabezado para comprobar el orden de las columnas.
        DECLARE @sqlEncabezado NVARCHAR(MAX) = @sql + N', LASTROW = 1);';
        EXEC sys.sp_executesql @sqlEncabezado;
        IF NOT EXISTS (SELECT 1 FROM #SedesCSV
            WHERE estadio = N'nombre_estadio' AND ciudad = N'ciudad' AND pais = N'pais'
                AND capacidad = N'capacidad' AND huso = N'huso_horario' AND latitud = N'latitud'
                AND REPLACE(longitud, CHAR(13), '') = N'longitud')
            THROW 51106, N'El encabezado no coincide con el CSV de sedes.', 1;
        -- Saco el encabezado de la temporal antes de cargar los datos.
        TRUNCATE TABLE #SedesCSV;

        -- Cargo desde la segunda fila. Si me pasan una ruta, SQL Server puede volcar ahí errores de formato.
        SET @sql += N', FIRSTROW = 2';
        IF NULLIF(TRIM(@RutaErrores), N'') IS NOT NULL
            SET @sql += N', ERRORFILE = ''' + REPLACE(@RutaErrores, '''', '''''') + N'''';
        SET @sql += N');';
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        -- Si falla la lectura del archivo, guardo el motivo y devuelvo el error a quien llamó al SP.
        INSERT INTO Mundial.ImportacionCSV_V2 (ejecucion, archivo, tipo, estado, detalle)
        VALUES (@ejecucion, @RutaArchivo, 'Sedes', 'ERROR ARCHIVO', LEFT(ERROR_MESSAGE(), 2048));
        THROW;
    END CATCH;

    -- Le saco los espacios innecesarios y las coordenadas vacías quedan en NULL.
    UPDATE #SedesCSV
    SET estadio = TRIM(estadio), ciudad = TRIM(ciudad), pais = TRIM(pais),
        capacidad = TRIM(capacidad), huso = TRIM(huso), latitud = NULLIF(TRIM(latitud), N''),
        longitud = NULLIF(TRIM(REPLACE(longitud, CHAR(13), '')), N'');

    -- Numero las filas después del BULK INSERT. Este número es interno y no viene del CSV.
    ALTER TABLE #SedesCSV ADD fila INT IDENTITY(1,1) PRIMARY KEY;
    DECLARE @fila INT = 1;
    DECLARE @ultimaFila INT = (SELECT COUNT(*) FROM #SedesCSV);

    -- Reutilizo las variables en cada vuelta. Separo el texto del CSV de los números y los IDs.
    DECLARE @estadio NVARCHAR(MAX), @ciudad NVARCHAR(MAX), @pais NVARCHAR(MAX), @huso NVARCHAR(MAX);
    DECLARE @capacidadTexto NVARCHAR(MAX), @latitudTexto NVARCHAR(MAX), @longitudTexto NVARCHAR(MAX);
    DECLARE @capacidad INT, @latitud DECIMAL(9,6), @longitud DECIMAL(9,6), @idPais INT, @idSede INT;
    DECLARE @antes NVARCHAR(MAX), @despues NVARCHAR(MAX), @estado VARCHAR(15);

    -- Uso el WHILE porque los ABM reciben una sola sede por llamada.
    WHILE @fila <= @ultimaFila
    BEGIN
        SELECT @estadio = estadio, @ciudad = ciudad, @pais = pais, @huso = huso,
            @capacidadTexto = capacidad, @latitudTexto = latitud, @longitudTexto = longitud
        FROM #SedesCSV WHERE fila = @fila;

        BEGIN TRY
            -- Convierto la capacidad y las coordenadas. Si hay texto donde va un número, paso al CATCH.
            SET @capacidad = CONVERT(INT, NULLIF(@capacidadTexto, N''));
            SET @latitud = CONVERT(DECIMAL(9,6), @latitudTexto);
            SET @longitud = CONVERT(DECIMAL(9,6), @longitudTexto);
            -- Limpio el valor anterior para que no quede el de otra sede.
            SET @antes = NULL;

            -- La sede, un posible país nuevo y su registro de auditoría se confirman juntos.
            BEGIN TRANSACTION;

            -- El seed tiene México y Canadá, y el CSV los trae sin tilde.
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
            INSERT INTO Mundial.ImportacionCSV_V2
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
            INSERT INTO Mundial.ImportacionCSV_V2 (ejecucion, archivo, tipo, referencia, estado, detalle)
            VALUES (@ejecucion, @RutaArchivo, 'Sedes', LEFT(@estadio, 250), 'RECHAZADO', LEFT(ERROR_MESSAGE(), 2048));
        END CATCH;

        -- Avanzo tanto si la sede se guardó como si fue rechazada.
        SET @fila += 1;
    END;

    -- Devuelvo las cantidades por estado y los motivos de rechazo de esta ejecución.
    SELECT @ejecucion AS ejecucion, estado, COUNT(*) AS cantidad
    FROM Mundial.ImportacionCSV_V2 WHERE ejecucion = @ejecucion GROUP BY estado;
    SELECT referencia, detalle FROM Mundial.ImportacionCSV_V2
    WHERE ejecucion = @ejecucion AND estado = 'RECHAZADO' ORDER BY id_log;
END;
GO

-- Importación de partidos. Las sedes y las selecciones ya tienen que estar cargadas.
CREATE OR ALTER PROCEDURE Mundial.sp_ImportarPartidosCSV_V2
    @RutaArchivo NVARCHAR(1024),
    @RutaErrores NVARCHAR(1024) = NULL
AS
BEGIN
    -- Verifico la ruta y arranco sin una transacción externa para poder revertir de a una fila.
    IF @@TRANCOUNT <> 0
        THROW 51100, N'Ejecutá la importación sin una transacción abierta.', 1;
    IF NULLIF(TRIM(@RutaArchivo), N'') IS NULL
        THROW 51103, N'Indicá la ruta del CSV de partidos.', 1;
    SET XACT_ABORT ON;

    -- Recibo todas las columnas como texto. Convierto fechas y números más adelante, fila por fila.
    CREATE TABLE #PartidosCSV (
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

    -- Agrupo los resultados con un ID y armo el BULK INSERT con la ruta recibida.
    DECLARE @ejecucion UNIQUEIDENTIFIER = NEWID();
    DECLARE @sql NVARCHAR(MAX) = N'BULK INSERT #PartidosCSV FROM '''
        + REPLACE(@RutaArchivo, '''', '''''') + N'''
        WITH (FORMAT = ''CSV'', FIELDTERMINATOR = '','',
              ROWTERMINATOR = ''0x0A''';

    BEGIN TRY
        -- Leo solo la primera fila para comprobar el encabezado y el orden de los campos.
        DECLARE @sqlEncabezado NVARCHAR(MAX) = @sql + N', LASTROW = 1);';
        EXEC sys.sp_executesql @sqlEncabezado;
        IF NOT EXISTS (SELECT 1 FROM #PartidosCSV
            WHERE estadio = N'estadio' AND pais_local = N'pais_local' AND pais_visitante = N'pais_visitante'
                AND fecha_utc = N'fecha_utc' AND offset_min = N'offset_min' AND goles_local = N'goles_local'
                AND goles_visitante = N'goles_visitante' AND asistencia = N'asistencia'
                AND REPLACE(fase, CHAR(13), '') = N'fase')
            THROW 51107, N'El encabezado no coincide con el CSV de partidos.', 1;
        TRUNCATE TABLE #PartidosCSV;

        -- Leo los partidos desde la segunda fila y agrego ERRORFILE si me pasaron una ruta.
        SET @sql += N', FIRSTROW = 2';
        IF NULLIF(TRIM(@RutaErrores), N'') IS NOT NULL
            SET @sql += N', ERRORFILE = ''' + REPLACE(@RutaErrores, '''', '''''') + N'''';
        SET @sql += N');';
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        -- Un error de lectura o de encabezado se registra como error de archivo.
        INSERT INTO Mundial.ImportacionCSV_V2 (ejecucion, archivo, tipo, estado, detalle)
        VALUES (@ejecucion, @RutaArchivo, 'Partidos', 'ERROR ARCHIVO', LEFT(ERROR_MESSAGE(), 2048));
        THROW;
    END CATCH;

    -- Limpio la tabla de una vez y dejo en NULL los campos numéricos que vienen vacíos.
    -- La fase va en minúsculas y le quito el CR si quedó pegado al último campo.
    UPDATE #PartidosCSV
    SET estadio = TRIM(estadio), pais_local = TRIM(pais_local), pais_visitante = TRIM(pais_visitante),
        fecha_utc = NULLIF(TRIM(fecha_utc), N''), offset_min = NULLIF(TRIM(offset_min), N''),
        goles_local = NULLIF(TRIM(goles_local), N''), goles_visitante = NULLIF(TRIM(goles_visitante), N''),
        asistencia = NULLIF(TRIM(asistencia), N''), fase = LOWER(TRIM(REPLACE(fase, CHAR(13), '')));

    -- Numero las filas de la temporal para poder buscarlas de a una dentro del WHILE.
    ALTER TABLE #PartidosCSV ADD fila INT IDENTITY(1,1) PRIMARY KEY;
    DECLARE @fila INT = 1, @ultimaFila INT;
    SELECT @ultimaFila = ISNULL(MAX(fila), 0) FROM #PartidosCSV;

    -- Preparo variables para el texto del CSV, los datos convertidos y los IDs de la base.
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
        FROM #PartidosCSV WHERE fila = @fila;

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

            -- El CSV trae el nombre del estadio y el ABM necesita su ID.
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
                    @fecha_hora_utc = @fechaUTC, @fase = @fase, @id_partido = @idPartido OUTPUT;
            ELSE
            BEGIN
                SET @antes = (SELECT * FROM Mundial.Partido WHERE id_partido = @idPartido
                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER);
                EXEC Mundial.Partido_Modificar @id_partido = @idPartido, @id_sede = @idSede,
                    @id_seleccion_local = @idLocal, @id_seleccion_visitante = @idVisitante,
                    @fecha_hora_local = @fechaLocal, @fecha_hora_utc = @fechaUTC, @fase = @fase;
            END;

            -- Leo cómo quedó el partido y lo comparo con lo que había antes del ABM.
            SET @despues = (SELECT * FROM Mundial.Partido WHERE id_partido = @idPartido
                FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER);
            SET @estado = CASE
                WHEN @antes IS NULL THEN 'INSERTADO'
                WHEN @antes COLLATE Latin1_General_100_BIN2 = @despues COLLATE Latin1_General_100_BIN2 THEN 'SIN CAMBIOS'
                ELSE 'ACTUALIZADO' END;

            -- Anoto el resultado y guardo los dos estados del partido si hubo cambios.
            INSERT INTO Mundial.ImportacionCSV_V2
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
            INSERT INTO Mundial.ImportacionCSV_V2 (ejecucion, archivo, tipo, referencia, estado, detalle)
            VALUES (@ejecucion, @RutaArchivo, 'Partidos', @referencia, 'RECHAZADO', LEFT(ERROR_MESSAGE(), 2048));
        END CATCH;

        -- Paso al siguiente partido aunque el anterior haya sido rechazado.
        SET @fila += 1;
    END;

    -- Muestro las cantidades agrupadas por resultado.
    SELECT @ejecucion AS ejecucion, estado, COUNT(*) AS cantidad
    FROM Mundial.ImportacionCSV_V2 WHERE ejecucion = @ejecucion GROUP BY estado;
    -- El segundo resultado muestra qué partido se rechazó y por qué.
    SELECT referencia, detalle FROM Mundial.ImportacionCSV_V2
    WHERE ejecucion = @ejecucion AND estado = 'RECHAZADO' ORDER BY id_log;
END;
GO

-- Para probarlo:

/*
USE MundialDeFutbol;
GO

EXEC Mundial.sp_ImportarSedesCSV_V2
    @RutaArchivo = N'E:\Desktop\Cosas\Tareas_UNLAM\Bases de Datos aplicadas\TP 2026\Grupo8-Comision2900\datasets\sedes_mundial_2026.csv';

EXEC Mundial.sp_ImportarPartidosCSV_V2
    @RutaArchivo = N'E:\Desktop\Cosas\Tareas_UNLAM\Bases de Datos aplicadas\TP 2026\Grupo8-Comision2900\datasets\partidos_mundial_2026.csv';
*/