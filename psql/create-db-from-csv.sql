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

--
-- device_data
--

CREATE TEMPORARY TABLE device_data_import (
    "time" timestamp without time zone NOT NULL,
    device_id integer NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    accuracy double precision NOT NULL,
    activity_1 activity_type_enum,
    activity_1_conf integer,
    activity_2 activity_type_enum,
    activity_2_conf integer,
    activity_3 activity_type_enum,
    activity_3_conf integer
) ;

\COPY device_data_import FROM '../csv/device_data.csv' WITH CSV HEADER

CREATE TABLE device_data (
    id integer NOT NULL,
    device_id integer NOT NULL,
    coordinate geography(Point,4326) NOT NULL,
    accuracy double precision NOT NULL,
    "time" timestamp without time zone NOT NULL,
    activity_1 activity_type_enum,
    activity_1_conf integer,
    activity_2 activity_type_enum,
    activity_2_conf integer,
    activity_3 activity_type_enum,
    activity_3_conf integer
);

ALTER TABLE device_data OWNER TO regularroutes;

CREATE SEQUENCE device_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE device_data_id_seq OWNER TO regularroutes;

-- Create indices
ALTER SEQUENCE device_data_id_seq OWNED BY device_data.id;
ALTER TABLE ONLY device_data ALTER COLUMN id SET DEFAULT nextval('device_data_id_seq'::regclass);
ALTER TABLE ONLY device_data
    ADD CONSTRAINT device_data_pkey PRIMARY KEY (id);
CREATE INDEX idx_device_data_device_id_time ON device_data USING btree (device_id, "time");
CREATE INDEX idx_device_data_time ON device_data USING btree ("time");

INSERT INTO device_data (device_id, coordinate, accuracy, "time", activity_1, activity_1_conf, activity_2, activity_2_conf, activity_3, activity_3_conf)
SELECT device_id, ST_SetSRID(ST_Point(lng, lat),4326) AS coordinate, accuracy, "time",  activity_1, activity_1_conf, activity_2, activity_2_conf, activity_3, activity_3_conf
FROM device_data_import ;

--
-- device_data_filtered
--

CREATE TEMPORARY TABLE device_data_filtered_import (
    "time" timestamp without time zone NOT NULL,
    device_id integer NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    activity activity_type_enum
) ;

\COPY device_data_filtered_import FROM '../csv/device_data_filtered.csv' WITH CSV HEADER

CREATE TABLE device_data_filtered (
    id integer NOT NULL,
    device_id integer NOT NULL,
    coordinate geography(Point,4326) NOT NULL,
    "time" timestamp without time zone NOT NULL,
    activity activity_type_enum
);

ALTER TABLE device_data_filtered OWNER TO regularroutes;

CREATE SEQUENCE device_data_filtered_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE device_data_filtered_id_seq OWNER TO regularroutes;

-- Create indices
ALTER SEQUENCE device_data_filtered_id_seq OWNED BY device_data_filtered.id;
ALTER TABLE ONLY device_data_filtered ALTER COLUMN id SET DEFAULT nextval('device_data_filtered_id_seq'::regclass);
ALTER TABLE ONLY device_data_filtered
    ADD CONSTRAINT device_data_filtered_pkey PRIMARY KEY (id);
CREATE INDEX idx_device_data_filtered_device_id_time ON device_data_filtered USING btree (device_id, "time");
CREATE INDEX idx_device_data_filtered_time ON device_data_filtered USING btree ("time");

INSERT INTO device_data_filtered (device_id, coordinate, "time", activity)
SELECT device_id, ST_SetSRID(ST_Point(lng, lat),4326) AS coordinate, "time",  activity
FROM device_data_filtered_import ;

--
-- device_models
--

CREATE TABLE device_models (
    device_id integer NOT NULL,
    model character varying
);

ALTER TABLE device_models OWNER TO regularroutes;

\COPY device_models FROM '../csv/device_models.csv' WITH CSV HEADER

--
-- manual_log table import
-- 

CREATE TABLE manual_log (
    device_id integer NOT NULL,
    st_entrance character varying,
    st_entry_time timestamp without time zone,
    line_type transit_type_enum,
    line_name character varying,
    vehicle_dep_time timestamp without time zone NOT NULL,
    vehicle_boarding_stop character varying,
    vehicle_stop_time timestamp without time zone NOT NULL,
    vehicle_exit_stop character varying,
    st_exit_location character varying,
    st_exit_time timestamp without time zone,
    comments character varying
);

ALTER TABLE manual_log OWNER TO regularroutes;

\COPY manual_log FROM '../csv/manual_log.csv' WITH CSV HEADER
