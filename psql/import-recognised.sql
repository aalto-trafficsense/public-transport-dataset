--
-- import recognised trips into a common format
--

DROP TABLE IF EXISTS recognised_trips_import ;

CREATE TEMPORARY TABLE recognised_trips_import (
    device_id integer NOT NULL,
    time_start timestamp without time zone NOT NULL,
    time_end timestamp without time zone NOT NULL,
    activity activity_type_enum,
    km integer NOT NULL,
    direction character varying,
    minutes integer NOT NULL,
    speed_kmh integer NOT NULL,
    points integer NOT NULL,
    ol_line_type transit_type_enum, -- old live recognition
    ol_line_name character varying,
    nl_line_type transit_type_enum, -- new live recognition
    nl_line_name character varying,
    st_line_type transit_type_enum, -- static recognition (timetable-based)
    st_line_name character varying
) ;

\COPY recognised_trips_import FROM '../csv/recognised-summary.csv' WITH CSV HEADER

DROP TABLE IF EXISTS recognised_trips ;

CREATE TABLE recognised_trips (
    id integer NOT NULL,
    device_id integer NOT NULL,
    time_start timestamp without time zone NOT NULL,
    time_end timestamp without time zone NOT NULL,
    activity activity_type_enum,
    line_type transit_type_enum,
    line_name character varying
);

ALTER TABLE recognised_trips OWNER TO regularroutes;

CREATE SEQUENCE recognised_trips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE recognised_trips_id_seq OWNER TO regularroutes;

-- Create indices
ALTER SEQUENCE recognised_trips_id_seq OWNED BY recognised_trips.id;
ALTER TABLE ONLY recognised_trips ALTER COLUMN id SET DEFAULT nextval('recognised_trips_id_seq'::regclass);
ALTER TABLE ONLY recognised_trips
    ADD CONSTRAINT recognised_trips_pkey PRIMARY KEY (id);
CREATE INDEX idx_recognised_trips_device_id_time ON recognised_trips USING btree (device_id, time_start);
CREATE INDEX idx_recognised_trips_time ON recognised_trips USING btree (time_start);

-- Combined

INSERT INTO recognised_trips (device_id, time_start, time_end, activity, line_type, line_name)
SELECT devmap.target AS device_id, time_start, time_end, activity, coalesce(nl_line_type,st_line_type), coalesce(nl_line_name,st_line_name)
FROM recognised_trips_import,
  (VALUES(126,1), (128,2), (132,3), (170,4), (174,5), (178,6), (179,7), (180,8)) AS devmap (dev_id, target)
WHERE
  device_id = devmap.dev_id ;

-- From new live recognition

/*
INSERT INTO recognised_trips (device_id, time_start, time_end, activity, line_type, line_name)
SELECT devmap.target AS device_id, time_start, time_end, activity, nl_line_type, nl_line_name
FROM recognised_trips_import,
  (VALUES(126,1), (128,2), (132,3), (170,4), (174,5), (178,6), (179,7), (180,8)) AS devmap (dev_id, target)
WHERE
  device_id = devmap.dev_id;
*/

-- From static recognition

/*
INSERT INTO recognised_trips (device_id, time_start, time_end, activity, line_type, line_name)
SELECT devmap.target AS device_id, time_start, time_end, activity, st_line_type, st_line_name
FROM recognised_trips_import,
  (VALUES(126,1), (128,2), (132,3), (170,4), (174,5), (178,6), (179,7), (180,8)) AS devmap (dev_id, target)
WHERE
  device_id = devmap.dev_id ;
*/

-- From old live recognition

/*
INSERT INTO recognised_trips (device_id, time_start, time_end, activity, line_type, line_name)
SELECT devmap.target AS device_id, time_start, time_end, activity, ol_line_type, ol_line_name
FROM recognised_trips_import,
  (VALUES(126,1), (128,2), (132,3), (170,4), (174,5), (178,6), (179,7), (180,8)) AS devmap (dev_id, target)
WHERE
  device_id = devmap.dev_id;
*/
