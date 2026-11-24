USE MundialDeFutbol
go

USE MundialDeFutbol;
GO

IF SCHEMA_ID('MfSeguridad') IS NULL EXEC('CREATE SCHEMA MfSeguridad');
GO

-- Jugador: nombre, apellido, club
ALTER TABLE Mundial.Jugador
    ADD nombre_cifrado     VARBINARY(MAX) NULL,
        apellido_cifrado   VARBINARY(MAX) NULL;
GO

-- Tecnico: nombre, apellido
ALTER TABLE Mundial.Tecnico
    ADD nombre_cifrado   VARBINARY(MAX) NULL,
        apellido_cifrado VARBINARY(MAX) NULL;
GO

-- Arbitro: nombre, apellido
ALTER TABLE Mundial.Arbitro
    ADD nombre_cifrado   VARBINARY(MAX) NULL,
        apellido_cifrado VARBINARY(MAX) NULL;
GO

/* 
============================================================
   MIGRACIÓN: cifrar nombre/apellido/club de las 3 tablas
   con EncryptByPassPhrase + autenticador = id del registro
============================================================ 
*/

CREATE OR ALTER PROCEDURE MfSeguridad.CifrarDatosPersonales
    @FraseClave NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validación de la frase
    IF @FraseClave IS NULL OR LTRIM(RTRIM(@FraseClave)) = N''
    BEGIN
        ;THROW 51401, N'La frase clave es obligatoria. ', 1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

            -- ---------- JUGADOR ----------
            UPDATE Mundial.Jugador
            SET nombre_cifrado   = EncryptByPassPhrase(@FraseClave, nombre,   1, CONVERT(VARBINARY, id_jugador)),
                apellido_cifrado = EncryptByPassPhrase(@FraseClave, apellido, 1, CONVERT(VARBINARY, id_jugador))
            WHERE nombre IS NOT NULL;

            -- ---------- TECNICO ----------
            UPDATE Mundial.Tecnico
            SET nombre_cifrado   = EncryptByPassPhrase(@FraseClave, nombre,   1, CONVERT(VARBINARY, id_tecnico)),
                apellido_cifrado = EncryptByPassPhrase(@FraseClave, apellido, 1, CONVERT(VARBINARY, id_tecnico))
            WHERE nombre IS NOT NULL;

            -- ---------- ARBITRO ----------
            UPDATE Mundial.Arbitro
            SET nombre_cifrado   = EncryptByPassPhrase(@FraseClave, nombre,   1, CONVERT(VARBINARY, id_arbitro)),
                apellido_cifrado = EncryptByPassPhrase(@FraseClave, apellido, 1, CONVERT(VARBINARY, id_arbitro))
            WHERE nombre IS NOT NULL;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

select * from Mundial.Jugador
go







