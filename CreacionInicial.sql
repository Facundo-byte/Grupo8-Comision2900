IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MundialDeFutbol')
BEGIN
	CREATE DATABASE MundialDeFutbol;
	PRINT '--Creada BD: MundialDeFutbol--'
END;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MundialDeFutbol')
BEGIN
	USE MundialDeFutbol
	PRINT '--Usando BD: MundialDeFutbol--' 
END;
GO

----Creacion de Schema para Tablas
IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'Selecciones')
BEGIN
	EXECUTE('CREATE SCHEMA Selecciones')
	PRINT '--Creado Schema: Selecciones--'
END;
GO

IF NOT EXISTS (SELECT name FROM sys.schemas WHERE name = 'Mundial')
BEGIN
	EXECUTE('CREATE SCHEMA Mundial')
	PRINT '--Creado Schema: Mundial--'
END;
GO


































