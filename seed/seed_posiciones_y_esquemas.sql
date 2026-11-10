USE MundialDeFutbol;
GO

/*POSICION*/
EXEC Mundial.usp_Posicion_Alta 'Arquero', 'ARQ';
EXEC Mundial.usp_Posicion_Alta 'Defensor', 'DEF';
EXEC Mundial.usp_Posicion_Alta 'Mediocampista', 'MED';
EXEC Mundial.usp_Posicion_Alta 'Delantero', 'DEL';
GO

/*ESQUEMA*/
EXEC Mundial.usp_Esquema_Alta '4-4-2';
EXEC Mundial.usp_Esquema_Alta '4-3-3';
EXEC Mundial.usp_Esquema_Alta '3-5-2';
EXEC Mundial.usp_Esquema_Alta '4-2-3-1';
EXEC Mundial.usp_Esquema_Alta '5-3-2';
EXEC Mundial.usp_Esquema_Alta '4-5-1';
GO

SELECT * FROM Mundial.Posicion; -- Esperado: 4 filas (ARQ, DEF, MED, DEL)
SELECT * FROM Mundial.Esquema;  -- Esperado: 6 filas
GO