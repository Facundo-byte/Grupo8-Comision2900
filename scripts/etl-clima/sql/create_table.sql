/*
  Tabla destino para la ETL de clima por sede.
  Ejecutar una vez antes de correr la ETL.
*/
USE MundialDeFutbol;
GO

IF OBJECT_ID(N'Mundial.Clima_Sede', N'U') IS NULL
BEGIN
    CREATE TABLE Mundial.Clima_Sede (
        id_clima            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clima_Sede PRIMARY KEY,
        id_sede             INT NOT NULL,
        fecha_consulta_utc  DATETIME2(0) NOT NULL CONSTRAINT DF_Clima_Sede_fecha DEFAULT (SYSUTCDATETIME()),
        temperatura_c       DECIMAL(5,2) NULL,
        viento_kmh          DECIMAL(6,2) NULL,
        weather_code        INT NULL,
        condicion           VARCHAR(60) NULL,
        fuente              VARCHAR(30) NOT NULL CONSTRAINT DF_Clima_Sede_fuente DEFAULT ('Open-Meteo'),
        json_respuesta      NVARCHAR(MAX) NULL,
        CONSTRAINT FK_Clima_Sede_Sede FOREIGN KEY (id_sede) REFERENCES Mundial.Sede(id_sede)
    );

    CREATE INDEX IX_Clima_Sede_sede_fecha
        ON Mundial.Clima_Sede(id_sede, fecha_consulta_utc DESC);
END
GO

SELECT * FROM Mundial.Clima_Sede
GO