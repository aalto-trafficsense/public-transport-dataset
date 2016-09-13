-- Initialize a new database
-- Import the CSV-files of the TrafficSense
-- public transportation experiment dataset
-- to tables of a PostgreSQL database

-- mikko.rinne@aalto.fi 8.9.2016

CREATE ROLE regularroutes WITH LOGIN PASSWORD 'qwerty';
CREATE EXTENSION postgis;

--
-- enums
--

CREATE TYPE activity_type_enum AS ENUM ('IN_VEHICLE', 'ON_BICYCLE', 'ON_FOOT', 'RUNNING', 'STILL', 'TILTING', 'UNKNOWN', 'WALKING');
CREATE TYPE transit_type_enum AS ENUM ('FERRY', 'SUBWAY', 'TRAIN', 'TRAM', 'BUS', 'CAR');

\i import-db-from-csv.sql

