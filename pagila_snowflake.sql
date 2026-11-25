CREATE DATABASE IF NOT EXISTS pagila_dw;
USE pagila_dw;
-- =====================================================
-- Podtabulky (sdim)
-- =====================================================

-- mesto a krajina pre zakaznika aj predajnu (obe su pripojene k dim, nie k sebe)
CREATE TABLE sdim_city (
    city_id INT NOT NULL,
    city    VARCHAR(50) NOT NULL,
    CONSTRAINT pk_sdim_city PRIMARY KEY (city_id)
);

CREATE TABLE sdim_country (
    country_id INT NOT NULL,
    country    VARCHAR(50) NOT NULL,
    CONSTRAINT pk_sdim_country PRIMARY KEY (country_id)
);

-- jazyk filmu
CREATE TABLE sdim_language (
    language_id INT NOT NULL,
    name        VARCHAR(20) NOT NULL,
    CONSTRAINT pk_sdim_language PRIMARY KEY (language_id)
);

-- hierarchia datumu
CREATE TABLE sdim_month (
    month_id   INT NOT NULL,
    month      INT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    CONSTRAINT pk_sdim_month PRIMARY KEY (month_id)
);

CREATE TABLE sdim_quarter (
    quarter_id    INT NOT NULL,
    quarter       INT NOT NULL,
    quarter_label VARCHAR(10) NOT NULL,
    CONSTRAINT pk_sdim_quarter PRIMARY KEY (quarter_id)
);

CREATE TABLE sdim_day_of_week (
    day_of_week_id INT NOT NULL,
    day_of_week    VARCHAR(15) NOT NULL,
    CONSTRAINT pk_sdim_day_of_week PRIMARY KEY (day_of_week_id)
);

-- cast dna
CREATE TABLE sdim_part_of_day (
    part_of_day_id INT NOT NULL,
    part_of_day    VARCHAR(20) NOT NULL,
    CONSTRAINT pk_sdim_part_of_day PRIMARY KEY (part_of_day_id)
);

-- =====================================================
-- Dimenzie (dim)
-- =====================================================

CREATE TABLE dim_customer (
    customer_id   INT NOT NULL,
    first_name    VARCHAR(45) NOT NULL,
    last_name     VARCHAR(45) NOT NULL,
    email         VARCHAR(50),
    active        TINYINT NOT NULL,
    created_at    DATE,
    address       VARCHAR(50),
    district      VARCHAR(50),
    postal_code   VARCHAR(10),
    phone         VARCHAR(20),
    city_id       INT NOT NULL,
    country_id    INT NOT NULL,
    CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id),
    CONSTRAINT fk_dim_customer_city FOREIGN KEY (city_id) REFERENCES sdim_city (city_id),
    CONSTRAINT fk_dim_customer_country FOREIGN KEY (country_id) REFERENCES sdim_country (country_id)
);

CREATE TABLE dim_film (
    film_id          INT NOT NULL,
    title            VARCHAR(255) NOT NULL,
    description      TEXT,
    release_year     YEAR,
    rental_duration  SMALLINT NOT NULL,
    rental_rate      DECIMAL(4,2) NOT NULL,
    length           SMALLINT,
    replacement_cost DECIMAL(5,2) NOT NULL,
    rating           DOUBLE,
    special_features TEXT,
    language_id      INT NOT NULL,
    CONSTRAINT pk_dim_film PRIMARY KEY (film_id),
    CONSTRAINT fk_dim_film_language FOREIGN KEY (language_id) REFERENCES sdim_language (language_id)
);

CREATE TABLE dim_category (
    category_id INT NOT NULL,
    name        VARCHAR(25) NOT NULL,
    CONSTRAINT pk_dim_category PRIMARY KEY (category_id)
);

CREATE TABLE dim_actor (
    actor_id   INT NOT NULL,
    first_name VARCHAR(45) NOT NULL,
    last_name  VARCHAR(45) NOT NULL,
    CONSTRAINT pk_dim_actor PRIMARY KEY (actor_id)
);

CREATE TABLE dim_staff (
    staff_id   INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    email      VARCHAR(50),
    active     TINYINT NOT NULL,
    CONSTRAINT pk_dim_staff PRIMARY KEY (staff_id)
);

CREATE TABLE dim_store (
    store_id     INT NOT NULL,
    manager_name VARCHAR(101),
    address      VARCHAR(50),
    district     VARCHAR(50),
    postal_code  VARCHAR(10),
    phone        VARCHAR(20),
    city_id      INT NOT NULL,
    country_id   INT NOT NULL,
    CONSTRAINT pk_dim_store PRIMARY KEY (store_id),
    CONSTRAINT fk_dim_store_city FOREIGN KEY (city_id) REFERENCES sdim_city (city_id),
    CONSTRAINT fk_dim_store_country FOREIGN KEY (country_id) REFERENCES sdim_country (country_id)
);

CREATE TABLE dim_date (
    date_id        INT NOT NULL,          -- napr. 20240131
    full_date      DATE NOT NULL,
    day            INT NOT NULL,
    week           INT NOT NULL,
    year           INT NOT NULL,
    month_id       INT NOT NULL,
    quarter_id     INT NOT NULL,
    day_of_week_id INT NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_id),
    CONSTRAINT fk_dim_date_month FOREIGN KEY (month_id) REFERENCES sdim_month (month_id),
    CONSTRAINT fk_dim_date_quarter FOREIGN KEY (quarter_id) REFERENCES sdim_quarter (quarter_id),
    CONSTRAINT fk_dim_date_dow FOREIGN KEY (day_of_week_id) REFERENCES sdim_day_of_week (day_of_week_id)
);

CREATE TABLE dim_time (
    time_id        INT NOT NULL,          -- napr. 143005
    hour           INT NOT NULL,
    minute         INT NOT NULL,
    second         INT NOT NULL,
    am_pm          VARCHAR(2) NOT NULL,
    part_of_day_id INT NOT NULL,
    CONSTRAINT pk_dim_time PRIMARY KEY (time_id),
    CONSTRAINT fk_dim_time_part FOREIGN KEY (part_of_day_id) REFERENCES sdim_part_of_day (part_of_day_id)
);

-- =====================================================
-- Bridge tabulky (vztahy M:N)
-- =====================================================

CREATE TABLE bridge_film_category (
    film_id     INT NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT pk_bridge_film_category PRIMARY KEY (film_id, category_id),
    CONSTRAINT fk_bfc_film FOREIGN KEY (film_id) REFERENCES dim_film (film_id),
    CONSTRAINT fk_bfc_category FOREIGN KEY (category_id) REFERENCES dim_category (category_id)
);

CREATE TABLE bridge_film_actor (
    film_id  INT NOT NULL,
    actor_id INT NOT NULL,
    CONSTRAINT pk_bridge_film_actor PRIMARY KEY (film_id, actor_id),
    CONSTRAINT fk_bfa_film FOREIGN KEY (film_id) REFERENCES dim_film (film_id),
    CONSTRAINT fk_bfa_actor FOREIGN KEY (actor_id) REFERENCES dim_actor (actor_id)
);

-- =====================================================
-- Faktova tabulka
-- =====================================================

CREATE TABLE fact_rental (
    rental_id             INT NOT NULL,
    customer_id           INT NOT NULL,
    film_id               INT NOT NULL,
    staff_id              INT NOT NULL,
    store_id              INT NOT NULL,
    rental_date_id        INT NOT NULL,
    rental_time_id        INT NOT NULL,
    return_date_id        INT NULL,       -- NULL ak film este nebol vrateny
    rental_rate           DECIMAL(4,2) NOT NULL,   -- cena za poziciane
    replacement_cost      DECIMAL(5,2),
    planned_duration_days INT,
    rental_days           INT NULL,                -- skutocny pocet dni (NULL ak nevrateny)
    CONSTRAINT pk_fact_rental PRIMARY KEY (rental_id),
    CONSTRAINT fk_fr_customer FOREIGN KEY (customer_id) REFERENCES dim_customer (customer_id),
    CONSTRAINT fk_fr_film FOREIGN KEY (film_id) REFERENCES dim_film (film_id),
    CONSTRAINT fk_fr_staff FOREIGN KEY (staff_id) REFERENCES dim_staff (staff_id),
    CONSTRAINT fk_fr_store FOREIGN KEY (store_id) REFERENCES dim_store (store_id),
    CONSTRAINT fk_fr_rental_date FOREIGN KEY (rental_date_id) REFERENCES dim_date (date_id),
    CONSTRAINT fk_fr_rental_time FOREIGN KEY (rental_time_id) REFERENCES dim_time (time_id),
    CONSTRAINT fk_fr_return_date FOREIGN KEY (return_date_id) REFERENCES dim_date (date_id)
);
