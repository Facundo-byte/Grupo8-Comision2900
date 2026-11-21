/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Importación de sedes con BULK INSERT.
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
              ROWTERMINATOR = ''0x0A'', CODEPAGE = ''65001''';

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

