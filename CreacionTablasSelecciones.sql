/*
-/-/2026
Universidad Nacional de La Matanza
Bases de Datos Aplicada

Grupo x
Thiago Dal Secco
Ramiro De Rogatis
Federico Iascas
Gonzalo Cardozo

En este script se realiza la creacion de las tablas: Pais, Seleccion, Jugador, ListaConvocados, AltasBajasConvocados
*/

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MundialDeFutbol')
BEGIN
	USE MundialDeFutbol
	PRINT '--Usando BD: MundialDeFutbol--' 
END;
GO

--Tabla Pais
--Se asume que no hay 2 países con el mismo nombre, por lo que el campo nombrePais es unico.
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Selecciones' AND TABLE_NAME = 'Pais')
BEGIN
	CREATE TABLE Selecciones.Pais
	(
		IDPais INT IDENTITY(1,1) PRIMARY KEY,
		nombrePais varchar(30) UNIQUE
	)
	PRINT '--Creada Tabla: Pais--'
END;
GO

--Tabla Seleccion
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Selecciones' AND TABLE_NAME = 'Seleccion')
BEGIN
	CREATE TABLE Selecciones.Seleccion
	(
		IDSeleccion INT IDENTITY(1,1) PRIMARY KEY,
		IDPais INT REFERENCES Selecciones.Pais(IDPais),
		Confederacion VARCHAR(30),
		Grupo CHAR
	)
	PRINT '--Creada Tabla: Seleccion--'
END;
GO

--Tabla ListaConvocados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Selecciones' AND TABLE_NAME = 'ListaConvocados')
BEGIN
	CREATE TABLE Selecciones.ListaConvocados
	(
		IDLista INT IDENTITY(1,1) PRIMARY KEY,
		IDSeleccion INT UNIQUE REFERENCES Selecciones.Seleccion(IDSeleccion)
	)
	PRINT '--Creada Tabla: ListaConvocados--'
END;
GO

--Tabla Jugador
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Selecciones' AND TABLE_NAME = 'Jugador')
BEGIN
	CREATE TABLE Selecciones.Jugador
	(
		IDJugador INT IDENTITY(1,1) PRIMARY KEY,
		IDListaConvocados INT REFERENCES Selecciones.ListaConvocados(IDLista),
		Nombre VARCHAR(20),
		Apellido VARCHAR(50),
		Dorsal INT,
		Club VARCHAR(50)
	)
	PRINT '--Creada Tabla: Jugador--'
END;
GO

--Tabla AltasBajasConvocados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Selecciones' AND TABLE_NAME = 'AltasBajasConvocados')
BEGIN
	CREATE TABLE Selecciones.AltasBajasConvocados
	(
		IDAltaBaja INT IDENTITY(1,1) PRIMARY KEY,
		IDListaConvocados INT,
		IDSeleccion INT,
		IDJugador INT REFERENCES Selecciones.Jugador(IDJugador),
		Tipo CHAR(4),
		CONSTRAINT CK_Tipo CHECK(
		Tipo LIKE 'BAJA' OR
		Tipo LIKE 'ALTA'
		),
		Motivo VARCHAR(100),
		FechaModificacion DATE,
		CONSTRAINT FK_AltaBaja_ListaConvocados FOREIGN KEY (IDListaConvocados)
		REFERENCES Selecciones.ListaConvocados(IDLista)
	)
	PRINT '--Creada Tabla: AltasBajasConvocados--'
END;
GO























