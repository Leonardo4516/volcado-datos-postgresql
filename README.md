# 🌍 Volcado, Normalización y Calidad de Datos en PostgreSQL (`world_db`)

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![DevContainer](https://img.shields.io/badge/Dev_Containers-Ready-blueviolet?logo=visualstudiocode&logoColor=white)
![Data Quality](https://img.shields.io/badge/Data_Quality-100%25_Clean_UTF--8-success)
![Status](https://img.shields.io/badge/Status-Completado-success)

Este repositorio contiene la solución completa, reproducible y profesional para el ejercicio de **Volcado y Organización de Datos Masivos** en PostgreSQL a partir del dataset geográfico mundial (`world`). 

Incluye orquestación con **Docker Compose**, resolución de dependencias circulares en claves foráneas, normalización de entidades geográficas y una restauración automatizada de caracteres especiales (Mojibake / `U+FFFD`).

---

## 🚀 Inicio Rápido (Quickstart con Docker)

El entorno está 100% contenerizado. Puedes levantar PostgreSQL 16 y pgAdmin 4 con la base de datos totalmente poblada y normalizada con un solo comando:

```bash
# 1. Clonar el repositorio
git clone https://github.com/Leonardo4516/volcado-datos-postgresql.git
cd volcado-datos-postgresql

# 2. Configurar variables de entorno (opcional)
cp .env.example .env

# 3. Iniciar los contenedores
docker compose up -d
```

La base de datos `world_db` se inicializa de forma automática ejecutando el dump completo y limpio ubicado en `init/01_world_db_setup.sql`.

### 🔑 Parámetros de Conexión

| Servicio | Host | Puerto Local | Usuario | Contraseña | Base de Datos |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `localhost` | `5435` | `postgres` | `postgres123` | `world_db` |
| **pgAdmin 4** | `localhost` | `8083` | `admin@example.com` | `Admin12345!` | Web UI |

---

## 📂 Estructura del Repositorio

```text
volcado-datos-postgresql/
├── .devcontainer/               # Configuración para VS Code Dev Containers
│   └── devcontainer.json
├── .env.example                 # Plantilla de variables de entorno
├── .gitignore                   # Exclusiones de Git
├── docker-compose.yml           # Orquestación de PostgreSQL 16 y pgAdmin 4
├── init/                        # Script de inicialización automática en Docker
│   └── 01_world_db_setup.sql    # Base de datos completa, normalizada y 100% limpia
├── sql/                         # Scripts modulares paso a paso
│   ├── 01_schema_base.sql       # DDL base sin llaves foráneas circulares
│   ├── 02_normalizacion_continent.sql # Extracción y normalización de continentes + FKs
│   └── 03_restauracion_caracteres.sql # Script de actualización y limpieza de UTF-8
└── README.md                    # Documentación técnica completa
```

---

## 🧠 Desafíos Técnicos y Soluciones Aplicadas

### 1. Dependencia Circular de Llaves Foráneas (El huevo y la gallina)
* **Problema:** `city` requiere que exista `country` (`countrycode` $\rightarrow$ `country.code`), pero `country` requiere que exista la ciudad capital (`capital` $\rightarrow$ `city.id`). Si se creaban las llaves foráneas antes del volcado, la inserción fallaba en cascada.
* **Solución:** Se crearon las tablas únicamente con sus llaves primarias y restricciones `CHECK`. Los datos se volcaron en el orden `country` $\rightarrow$ `city` $\rightarrow$ `countrylanguage`, y las restricciones `FOREIGN KEY` se aplicaron al final tras validar que existían 0 registros huérfanos.

### 2. Normalización de la Entidad Geográfica (`continent`)
* **Problema:** En el diseño original, el continente era un texto plano repetido dentro de cada fila de la tabla `country` (redundancia de datos).
* **Solución:** Se creó una nueva tabla normalizada e independiente:
  ```sql
  CREATE TABLE continent (
      code serial4 NOT NULL,
      name text NOT NULL UNIQUE,
      CONSTRAINT continent_pk PRIMARY KEY (code)
  );

  INSERT INTO continent (name)
  SELECT DISTINCT continent
  FROM country
  ORDER BY continent ASC;
  ```
  Obteniendo los 8 continentes de forma única y estructurada.

### 3. Calidad de Datos: Restauración de Caracteres Corruptos (`U+FFFD` / ``)
* **Problema:** El volcado original contenía cientos de caracteres de reemplazo (`U+FFFD`), producto de una mala exportación previa en el archivo origen (`Lom`, `NDjamna`, `Santaf de Bogot`, `Shqipria`).
* **Solución:** Se cruzaron los registros con la fuente oficial UTF-8 por sus identificadores primarios (`id` y `code`):
  * **652 ciudades** restauradas (`Lomé`, `N´Djaména`, `Santafé de Bogotá`, `São Paulo`, `Zürich`, `Montréal`, etc.).
  * **79 países** restaurados en nombres y gobernantes (`José Eduardo dos Santos`, `Bénin`, etc.).
  * **17 idiomas** corregidos (`Aimará`, `Guaraní`, `Ketšua`, `Náhuatl`, etc.).
  * **Resultado:** **0 caracteres corruptos restantes en toda la base de datos**.

---

## 📊 Validación de Registros en PostgreSQL

```sql
SELECT 'country' AS tabla, COUNT(*) FROM country
UNION ALL
SELECT 'city', COUNT(*) FROM city
UNION ALL
SELECT 'countrylanguage', COUNT(*) FROM countrylanguage
UNION ALL
SELECT 'continent', COUNT(*) FROM continent;
```

| Tabla | Registros Totales | Estado |
| :--- | :--- | :--- |
| **`country`** | **239** | Limpio y Relacionado |
| **`city`** | **4.079** | Limpio (incluyendo Kabul ID=1) |
| **`countrylanguage`** | **983** | Limpio |
| **`continent`** | **8** | Normalizado |

---

## 🔍 Consulta de Prueba Relacional (`JOIN`)

```sql
SELECT 
    c.code,
    c.name AS pais,
    co.name AS continente,
    ci.name AS capital,
    c.population AS poblacion
FROM country c
JOIN continent co ON c.continent = co.name
JOIN city ci ON c.capital = ci.id
LIMIT 10;
```

**Salida en consola:**
```text
 code |     pais     | continente |  capital  | poblacion 
------+--------------+------------+-----------+-----------
 ZWE  | Zimbabwe     | Africa     | Harare    |  11669000
 ZMB  | Zambia       | Africa     | Lusaka    |   9169000
 ZAF  | South Africa | Africa     | Pretoria  |  40377000
 UGA  | Uganda       | Africa     | Kampala   |  21778000
 TZA  | Tanzania     | Africa     | Dodoma    |  33517000
 TUN  | Tunisia      | Africa     | Tunis     |   9586000
 TGO  | Togo         | Africa     | Lomé      |   4629000
 TCD  | Chad         | Africa     | N´Djaména |   7651000
 SYC  | Seychelles   | Africa     | Victoria  |     77000
 SWZ  | Swaziland    | Africa     | Mbabane   |   1008000
(10 filas)
```
