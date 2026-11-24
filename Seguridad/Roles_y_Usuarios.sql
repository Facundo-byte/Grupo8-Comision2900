

USE MundialDeFutbol
go

CREATE LOGIN administrador
	WITH PASSWORD = 'HomeroElGrande',
	CHECK_POLICY = on;
go

CREATE LOGIN cargadorDeResultados
	WITH PASSWORD = 'ChiquiAura',
	CHECK_POLICY = on;
go

CREATE LOGIN cargadorDeDatos
	WITH PASSWORD = 'Datapaluza',
	CHECK_POLICY = on;
go

--Creo el usuario administrador
CREATE USER [administrador] FOR LOGIN administrador
GO

--Le doy el permiso de db_owner
ALTER ROLE db_owner ADD MEMBER [administrador];
GO

--Creo el usuario cargadorDeDatos
CREATE USER [cargadorDeDatos] FOR LOGIN cargadorDeDatos
GO

--Le doy permiso para que ejecute los EXEC de los SP's de carga
GRANT EXECUTE ON SCHEMA::[MfSPabm] TO cargadorDeDatos;
GO

--Creo la Tabla Resultados para darle permios a "cargador de resultados"
Create TABLE Mundial.Resultados(
id_resultado INT IDENTITY(1,1) PRIMARY KEY,
id_partido INT REFERENCES Mundial.Partido(id_partido),
id_seleccion_ganadora INT,
id_seleccion_perdedora INT,
empate BIT)

select * from Mundial.Resultados
go

--Creo el usuario cargadorDeResultados
CREATE USER [cargadorDeResultados] FOR LOGIN cargadorDeResultados
GO

--Le doy permiso para insertar y consultar Mundial.Resultados
GRANT INSERT, SELECT ON [Mundial].Resultados TO cargadorDeResultados
GO














