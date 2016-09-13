-- Query to list the manual-log entries with their matching recognised lines.

-- Multiple IN_VEHICLE segments overlapping one manual-log entry
-- and multiple manual-log entries overlapping one in-vehicle segment intentionally
-- produce multiple rows to enable comparison.
-- Overlap is required to be more than 60 seconds to remove bookkeeping rounding issues.

SELECT DISTINCT
  ml.device_id AS device_id,
  "time"(ml.vehicle_dep_time) AS log_start,
  "time"(ml.vehicle_arr_time) AS log_end,
  ml.line_type AS logged_type,
  ml.line_name AS logged_name,
  rt.id AS id,
  "time"(rt.time_start) AS segment_start,
  "time"(rt.time_end) AS segment_end,
  rt.activity AS activity,
  rt.line_type AS recd_type,
  rt.line_name AS recd_name
FROM manual_log ml
LEFT OUTER JOIN recognised_trips rt ON
  rt.device_id=ml.device_id AND
  (rt.time_start,rt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time) AND
  (rt.time_end-ml.vehicle_dep_time) > '60 second' AND
  (ml.vehicle_arr_time-rt.time_start) > '60 second'
ORDER BY
  ml.device_id, "time"(ml.vehicle_dep_time) ;

-- Old version - shows each logged entry once.

/*
SELECT DISTINCT ON (device_id,log_start)
  ml.device_id AS device_id,
  "time"(ml.vehicle_dep_time) AS log_start,
  "time"(ml.vehicle_arr_time) AS log_end,
  ml.line_type AS logged_type,
  ml.line_name AS logged_name,
  coalesce(act.id,pt.id) AS id,
  "time"(coalesce(act.time_start,pt.time_start)) AS segment_start,
  "time"(coalesce(act.time_end,pt.time_end)) AS segment_end,
  coalesce(act.activity,pt.activity) AS activity,
  act.line_type AS recd_type,
  act.line_name AS recd_name
FROM manual_log ml
LEFT OUTER JOIN recognised_trips act ON
  act.device_id=ml.device_id AND
  (act.time_start,act.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time) AND
  ml.vehicle_dep_time < act.time_start
LEFT OUTER JOIN recognised_trips pt ON
  pt.device_id=ml.device_id AND
  pt.line_type IS NOT NULL AND
  (pt.time_start,pt.time_end) OVERLAPS (ml.vehicle_dep_time,ml.vehicle_arr_time)
ORDER BY
  ml.device_id, "time"(ml.vehicle_dep_time) ;
*/
