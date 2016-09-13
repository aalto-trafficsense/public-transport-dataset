-- Import the CSV-files of the TrafficSense
-- public transportation experiment dataset
-- to tables of a PostgreSQL database

-- mikko.rinne@aalto.fi 12.9.2016

--
-- device_data
--

DROP TABLE IF EXISTS device_data_import ;

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

DROP TABLE IF EXISTS device_data ;

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

DROP TABLE IF EXISTS device_data_filtered_import ;

CREATE TEMPORARY TABLE device_data_filtered_import (
    "time" timestamp without time zone NOT NULL,
    device_id integer NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    activity activity_type_enum
) ;

\COPY device_data_filtered_import FROM '../csv/device_data_filtered.csv' WITH CSV HEADER

DROP TABLE IF EXISTS device_data_filtered ;

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

DROP TABLE IF EXISTS device_models ;

CREATE TABLE device_models (
    device_id integer NOT NULL,
    model character varying
);

ALTER TABLE device_models OWNER TO regularroutes;

\COPY device_models FROM '../csv/device_models.csv' WITH CSV HEADER

--
-- manual_log table import
-- 

DROP TABLE IF EXISTS manual_log ;

CREATE TABLE manual_log (
    device_id integer NOT NULL,
    st_entrance character varying,
    st_entry_time timestamp without time zone,
    line_type transit_type_enum,
    line_name character varying,
    vehicle_dep_time timestamp without time zone NOT NULL,
    vehicle_dep_stop character varying,
    vehicle_arr_time timestamp without time zone NOT NULL,
    vehicle_arr_stop character varying,
    st_exit_location character varying,
    st_exit_time timestamp without time zone,
    comments character varying
);

ALTER TABLE manual_log OWNER TO regularroutes;

\COPY manual_log FROM '../csv/manual_log.csv' WITH CSV HEADER

--
-- transit_live
--

DROP TABLE IF EXISTS transit_live_import ;

CREATE TEMPORARY TABLE transit_live_import (
    "time" timestamp without time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    line_type transit_type_enum,
    line_name character varying,
    vehicle_ref character varying
) ;

\COPY transit_live_import FROM '../csv/transit_live.csv' WITH CSV HEADER

DROP TABLE IF EXISTS transit_live ;

CREATE TABLE transit_live (
    id integer NOT NULL,
    coordinate geography(Point,4326) NOT NULL,
    "time" timestamp without time zone NOT NULL,
    line_type transit_type_enum,
    line_name character varying,
    vehicle_ref character varying
);

ALTER TABLE transit_live OWNER TO regularroutes;

CREATE SEQUENCE transit_live_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE transit_live_id_seq OWNER TO regularroutes;

-- Create indices
ALTER SEQUENCE transit_live_id_seq OWNED BY transit_live.id;
ALTER TABLE ONLY transit_live ALTER COLUMN id SET DEFAULT nextval('transit_live_id_seq'::regclass);
ALTER TABLE ONLY transit_live
    ADD CONSTRAINT transit_live_pkey PRIMARY KEY (id);
CREATE INDEX idx_transit_live_time_coordinate ON transit_live USING btree ("time", coordinate);
CREATE INDEX idx_transit_live_time ON transit_live USING btree ("time");

INSERT INTO transit_live (coordinate, "time", line_type, line_name, vehicle_ref)
SELECT ST_SetSRID(ST_Point(lng, lat),4326) AS coordinate, "time", line_type, line_name, vehicle_ref
FROM transit_live_import ;
