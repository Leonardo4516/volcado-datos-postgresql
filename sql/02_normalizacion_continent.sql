-- ==========================================================
-- 02. Normalización de Continentes y Activación de Llaves Foráneas
-- ==========================================================

SET client_encoding = 'UTF8';

-- 1. Crear tabla normalizada de continentes
CREATE TABLE IF NOT EXISTS public.continent (
    code serial4 NOT NULL,
    name text NOT NULL UNIQUE,
    CONSTRAINT continent_pk PRIMARY KEY (code)
);

-- 2. Poblar tabla extrayendo valores únicos de country ordenados alfabéticamente
INSERT INTO continent (name)
SELECT DISTINCT continent
FROM country
ORDER BY continent ASC
ON CONFLICT (name) DO NOTHING;

-- 3. Activación de Llaves Foráneas (Integridad Referencial)
ALTER TABLE city 
    ADD CONSTRAINT fk_city_country 
    FOREIGN KEY (countrycode) REFERENCES country(code);

ALTER TABLE countrylanguage 
    ADD CONSTRAINT fk_language_country 
    FOREIGN KEY (countrycode) REFERENCES country(code);

ALTER TABLE country 
    ADD CONSTRAINT fk_country_capital 
    FOREIGN KEY (capital) REFERENCES city(id);
