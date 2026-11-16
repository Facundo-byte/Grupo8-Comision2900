/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Grupo: 8
    Fecha: 10/11/2026
    Integrantes: Facundo David Iascas, Ramiro Javier De Rogatis, Gonzalo Daniel Cardozo, Thiago Dal Secco
    Descripcion: Creacion de la base de datos MundialDeFutbol y de los esquemas Mundial y MfSPabm
*/

USE master;
GO

IF DB_ID('MundialDeFutbol') IS NULL
    CREATE DATABASE MundialDeFutbol;
GO

USE MundialDeFutbol;
GO

IF SCHEMA_ID('Mundial') IS NULL EXEC('CREATE SCHEMA Mundial');
GO
IF SCHEMA_ID('MfSPabm') IS NULL EXEC('CREATE SCHEMA MfSPabm');
GO
