# ETL Clima por Sede

ETL standalone para consultar clima actual por sede usando **Open-Meteo** y cargarlo en `Mundial.Clima_Sede`.

## Estructura

```text
scripts/etl-clima/
├── etl-clima.js
├── package.json
├── .env.example
├── README.md
└── sql/
    └── 01_create_table.sql
```

## Preparación

1. Crear la tabla destino (una vez):

```bash
# desde la raíz del repo, si usás db/run.sh:
./db/run.sh -d MundialDeFutbol Grupo8-Comision2900/scripts/etl-clima/sql/01_create_table.sql
```

2. Instalar dependencias:

```bash
cd Grupo8-Comision2900/scripts/etl-clima
npm install
```

3. Configurar env vars (opcional, tiene defaults):

```bash
cp .env.example .env
# ajustar si hace falta
```

## Ejecutar

```bash
npm start
# o
node etl-clima.js
```

## API usada

Open-Meteo (sin API key):

```text
https://api.open-meteo.com/v1/forecast?latitude=<lat>&longitude=<lon>&current=temperature_2m,weather_code,wind_speed_10m
```
