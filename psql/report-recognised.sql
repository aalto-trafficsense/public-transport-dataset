--
-- Report recognized trips
--

-- mikko.rinne@aalto.fi 11.9.2016

-- rec_trips points to the table where the recognised trips are found:
\set rec_trips 'recognised_trips'

\echo '\nTrip counts without checking correct matching:'
\echo '=============================================='

SELECT COUNT(*) AS recognised FROM :rec_trips WHERE line_type IS NOT NULL
\gset public_

SELECT COUNT(*) AS logged FROM manual_log WHERE line_type != 'CAR'
\gset public_

SELECT :public_recognised*100/:public_logged AS per
\gset

\echo All public transport trips recognised: :public_recognised / :public_logged logged (:per%)

SELECT COUNT(*) AS recognised FROM :rec_trips WHERE line_type = 'BUS'
\gset bus_

SELECT COUNT(*) AS logged FROM manual_log WHERE line_type = 'BUS'
\gset bus_

SELECT :bus_recognised*100/:bus_logged AS per
\gset

\echo Bus recognised: :bus_recognised / :bus_logged logged (:per%)

SELECT COUNT(*) AS recognised FROM :rec_trips WHERE line_type = 'TRAM'
\gset tram_

SELECT COUNT(*) AS logged FROM manual_log WHERE line_type = 'TRAM'
\gset tram_

SELECT :tram_recognised*100/:tram_logged AS per
\gset

\echo Tram recognised: :tram_recognised / :tram_logged logged (:per%)

SELECT COUNT(*) AS recognised FROM :rec_trips WHERE line_type = 'TRAIN'
\gset train_

SELECT COUNT(*) AS logged FROM manual_log WHERE line_type = 'TRAIN'
\gset train_

SELECT :train_recognised*100/:train_logged AS per
\gset

\echo Train recognised: :train_recognised / :train_logged logged (:per%)

SELECT COUNT(*) AS recognised FROM :rec_trips WHERE line_type = 'SUBWAY'
\gset subway_

SELECT COUNT(*) AS logged FROM manual_log WHERE line_type = 'SUBWAY'
\gset subway_

SELECT :subway_recognised*100/:subway_logged AS per
\gset

\echo Subway recognised: :subway_recognised / :subway_logged logged (:per%)

\echo '\nRecognised trips overlapping a logged trip:'
\echo '==========================================='

SELECT COUNT(*) AS recognised, logged
FROM :rec_trips,
     (SELECT COUNT(*) AS logged FROM manual_log) man_log
WHERE activity = 'IN_VEHICLE'
GROUP BY logged
\gset vehicle_

-- SELECT :rec_trips.time_start,:rec_trips.activity, ml.vehicle_dep_time, ml.line_type
SELECT COUNT(DISTINCT :rec_trips.time_start) as matching
FROM :rec_trips, manual_log ml
WHERE
  :rec_trips.device_id=ml.device_id AND
  :rec_trips.activity = 'IN_VEHICLE' AND
  (:rec_trips.time_start,:rec_trips.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
\gset vehicle_

\echo In-vehicle segments recognised / overlapping-logged / logged-total: :vehicle_recognised / :vehicle_matching / :vehicle_logged

-- SELECT rt.id, rt.time_start, rt.line_type, ml.vehicle_dep_time, ml.line_type
SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt
      LEFT OUTER JOIN manual_log ml ON
        rt.device_id=ml.device_id AND
        (ml.line_type != 'CAR') AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      WHERE
        rt.line_type IS NOT NULL
      ) AS subQuery
\gset pub_match_

SELECT :pub_match_recognised*100/:public_logged AS per
\gset

\echo Recognised public transportation trips matching a real trip :pub_match_recognised / :public_logged logged (:per%)

-- SELECT rt.id,rt.time_start
SELECT COUNT(DISTINCT rt.id) AS recognised
FROM
  :rec_trips rt
WHERE
  (rt.line_type IS NOT NULL) AND
  NOT EXISTS (SELECT irt.id FROM :rec_trips irt, manual_log ml
   WHERE irt.device_id=ml.device_id AND
         irt.line_type IS NOT NULL AND
         (ml.line_type != 'CAR') AND
         (irt.time_start,irt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time) AND
	 irt.id = rt.id)
\gset pub_nomatch_

\echo Recognised public transportation trips NOT matching a real trip :pub_nomatch_recognised

-- SELECT rt.id, rt.time_start, rt.line_type, ml.vehicle_dep_time, ml.line_type
SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        ml.line_type = rt.line_type AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset pub_match_line_

SELECT :pub_match_line_recognised*100/:public_logged AS per
\gset

\echo Public transportation trips with matching line type :pub_match_line_recognised / :public_logged logged (:per%)

SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        ml.line_type = rt.line_type AND
	ml.line_type = 'BUS' AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset bus_match_line_

\echo Bus trips with matching line type :bus_match_line_recognised / :bus_logged logged

SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        ml.line_type = rt.line_type AND
	ml.line_type = 'BUS' AND
	ml.line_name = rt.line_name AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset bus_match_name_

\echo Bus trips with matching line name :bus_match_name_recognised / :bus_logged logged

SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        rt.line_type IS NOT NULL AND
	ml.line_type = 'TRAM' AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset tram_match_line_

\echo Tram trips with matching line type :tram_match_line_recognised / :tram_logged logged

SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        ml.line_type = rt.line_type AND
	ml.line_type = 'TRAM' AND
	ml.line_name = rt.line_name AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset tram_match_name_

\echo Tram trips with matching line name :tram_match_name_recognised / :tram_logged logged

SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        ml.line_type = rt.line_type AND
	ml.line_type = 'TRAIN' AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset train_match_line_

\echo Train trips with matching line type :train_match_line_recognised / :train_logged logged

SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        ml.line_type = rt.line_type AND
	ml.line_type = 'TRAIN' AND
	ml.line_name = rt.line_name AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset train_match_name_

\echo Train trips with matching line name :train_match_name_recognised / :train_logged logged

SELECT COUNT(DISTINCT log_dep_time) AS recognised
FROM (SELECT DISTINCT ON (rt.id) rt.id AS id,ml.vehicle_dep_time AS log_dep_time
      FROM
        :rec_trips rt, manual_log ml
      WHERE
        rt.device_id=ml.device_id AND
        ml.line_type = rt.line_type AND
	ml.line_type = 'SUBWAY' AND
        (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
      ) AS subQuery	
\gset subway_match_line_

\echo Subway trips with matching line type :subway_match_line_recognised / :subway_logged logged

