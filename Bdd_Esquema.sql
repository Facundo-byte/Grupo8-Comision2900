USE master;
GO

IF DB_ID('MundialDeFutbol') IS NULL
    CREATE DATABASE MundialDeFutbol;
GO

USE MundialDeFutbol;
GO

-- CREATE SCHEMA debe ir solo en su lote: unico uso de SQL dinamico (necesario).
IF SCHEMA_ID('Mundial') IS NULL
    EXEC('CREATE SCHEMA Mundial');
GO