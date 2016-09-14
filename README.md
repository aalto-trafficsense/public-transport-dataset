# public-transport-dataset

The dataset is composed of position and activity recognition samples
of 8 researchers between 9 am and 4 pm EET+DST on August 26th 2016,
manual bookkeeping of their trips and related transport infrastructure
data. Data collection for the limited period was pre-agreed with every
campaign participant. The target was to create a dataset for testing
and benchmarking of algorithms for automatic recognition of public
transportation trips from mobile phone sample data. Seven participants
executed as many public transportation trips as possible during the
designated time, especially emphasizing travel by subway, as it has
been the most challenging transportation mode for automatic
recognition. Some private car trips were also logged to provide trips,
which should not match with any public transportation. Due to the
exceptional amount of travel during one day, this dataset cannot be
used as a source for studying regular travel habits of public
transportation users.

The challenge is to correctly recognise as many trips
from the manual log as possible by using the other forms of data available.

The dataset consists of the following components:
* [Device data](#device-data) (samples from mobile phones)
* [Filtered device data](#device-data-filtered) (activity and movement
  filtered)
* [Device models](#device-models) (phones used by the participants)
* [Manual log](#manual-log) (manual trip bookkeeping entries of participants)
* [Live position samples](#transit-live) of the public transport fleet
* [Static timetables](#static timetables) valid at the time of the experiment
* [Train history](#train history information) from the experiment date

CSV-versions of the data are available in the [csv folder](https://github.com/aalto-trafficsense/public-transport-dataset/tree/master/csv). The [psql
folder](https://github.com/aalto-trafficsense/public-transport-dataset/tree/master/psql) contains instructions and scripts to import the data into a
PostgreSQL database.

## device-data

Mobile client samples were collected using the [TrafficSense android client](https://play.google.com/store/apps/details?id=fi.aalto.trafficsense.trafficsense). The client program uses the fused location provider and activity recognition from Google play services. The following fields were collected into the dataset:
  1. time (timestamp without timezone)
  1. device_id (integer, stable identifier for the device)
  1. lat (double, latitude)
  1. lng (double, longitude)
  1. accuracy (double, radius)
  1. activity_1 (enum value of highest confidence activity)
  1. activity_1_conf (integer percentage of recognition certainty, 100 is best)
  1. activity_2 (enum value of second-highest confidence activity)
  1. activity_2_conf (integer percentage of recognition certainty)
  1. activity_3 (enum value of second-highest confidence activity)
  1. activity_3_conf (integer percentage of recognition certainty)

The table contains 6030 entries. The CSV-version is sorted by time and device_id.

The enum values for the activities are: IN_VEHICLE, ON_BICYCLE, ON_FOOT, RUNNING, STILL, TILTING, UNKNOWN, WALKING

### Missing points due to ACTIVE-SLEEP states and other filtering

The client transfers between ACTIVE and SLEEP states with the following criteria:

ACTIVE ----40 seconds STILL only----> SLEEP

ACTIVE <-------not STILL------------- SLEEP

If received position changes (more than the accuracy of the fix) during the STILL period, the timer is restarted from 40 seconds.

In ACTIVE state position is requested with high accuracy and 10 second interval. In SLEEP state position request drops to "no power" priority, which means that position fixes are given to our client, if someone else requests them.

The received position fixes are filtered as follows:
* Accuracy needs to be better than 1000m
* If activity != last queued activity and activity is good (not
  unknown or tilting), point is accepted
* If activity == last queued activity and distance to last queued activity > accuracy, point is accepted

Activity is always requested with 10 second interval, but as a form of power saving, during STILL situations activity recognition interval has been observed to raise up to 180 seconds. Each queued position is complemented with the latest activity information. The timestamp of the entry is the timestamp of the position, not of the activity. The same reported activity may repeat over multiple points.

As a result, sometimes the client may need up to ~200 seconds to wake
up from SLEEP state. It has also been observed in rail traffic that
sometimes the ride is so smooth that the client goes to SLEEP state
during travel.

### Sampling parameters

In addition to SLEEP-state explained above, these parameters were used
by the client:
* Location update request interval and max rate 10s (in ACTIVE)
* Activity recognition reporting interval 10s (request, in practice
varies up to 180 seconds for power saving reasons)

An average of 30% of the maximum number of points (one
point every 10 seconds from each terminal) has been uploaded.

### Positioning inaccuracies

The mobile client uses the [Android fused location provider](https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderApi), which
combines data from satellite, WLAN and cellular positioning. Despite that, sometimes there can be problematic positioning
fixes, which should be taken care of by filtering. One example is
shown [here](https://github.com/aalto-trafficsense/public-transport-dataset/blob/master/doc/example-positioning-problem.png).

## device-data-filtered

`device_data` after applying two filters:
* Remove periods, when the terminal was not substantially moving
* Find the best activity

`device_data_filtered` is included in the set, because some recognition
algorithms use it. A candidate solution is welcome to use the more
complete device-data instead, especially if a better activity
filtering solution is developed.

The following fields are included:
  1. time (timestamp without timezone)
  1. device_id (integer, same as in `device_data`)
  1. lat (double, latitude)
  1. lng (double, longitude)
  1. activity (enum value of the decided activity)

The table contains 5975 points. The CSV-version is sorted by time and device_id.

## device-models

Lists the type string for the mobile phone used in the test. Included, as there are some differences in e.g. activity recognition performance between different devices. Contains the following columns:
  1. device_id (integer, same as in `device_data`)
  1. model (string name of the model)

The table length is 8 rows.

## manual-log

The manual bookkeeping of the test persons on the trips made. Contains the following columns per trip leg:
  1. device_id (integer, same as in [device_data](#device-data))
  1. st_entrance (string description of entrance to station building, if applicable)
  1. st_entry_time (timestamp (no tz) of entering station, if applicable)
  1. line_type (string SUBWAY / BUS / TRAM / TRAIN / CAR)
  1. line_name (string identifier, e.g. 7A, 102T, U, V)
  1. vehicle_dep_time (timestamp (no tz) of vehicle departure in trip start)
  1. vehicle_dep_stop (string description of the platform or other station where vehicle was boarded)
  1. vehicle_arr_time (timestamp (no tz) of vehicle stop at trip end)
  1. vehicle_arr_stop (string description of the platform or other station where the vehicle was exited)
  1. st_exit_location (string description of exit to station building, if applicable)
  1. st_exit_time (timestamp (no tz) of exiting station, if applicable)
  1. comments (string freeform comments about the trip leg)

The table length is 103 rows.

## transit-live

A series of positions of the
[Helsinki Regional Transport](https://www.hsl.fi/en) fleet obtained by
sampling http://dev.hsl.fi/siriaccess/vm/json every 30 seconds,
restricting the timeperiod to the time of the trial and geoboxing the area
[around the coordinates](https://github.com/aalto-trafficsense/public-transport-dataset/blob/master/doc/transit-data-bounding-box.png) sampled from the test participants. 

The following columns are included:
  1. time (timestamp without timezone)
  1. lat (double, latitude)
  1. lng (double, longitude)
  1. line_type (string SUBWAY / BUS / TRAM / TRAIN / CAR)
  1. line_name (string identifier, e.g. 7A, 102T, U, V)
  1. vehicle_ref (string to distinguish between different line_name
     vehicles in traffic at the same time)

The table length is 229451 entries.

_Note: No trains and not all buses are included in the live data!! One
of the challenges of the exercise._

Travelled line_names found in transit-live are:
* Trams: 2, 3, 7A, 8, 9
* Buses: 16, 67, 72, 550, 560
* Subways (line_name in manual-log varies and cannot be used)

Travelled line_names not found in transit-live are:
* Trains: E, I, K, P, U
* Buses: Espoo18, 95, 102T, 103T, 105, 110, 132T, 154, 156

In terms of trips, the following (10) bus trips are therefore
definitely not in transit-live:

    id| dep-time | line_name
    1 | 09:07:00 | 154
    5 | 09:08:00 | 110
	5 | 09:16:00 | 18 (Espoo)
    3 | 09:59:32 | 132T
    2 | 10:38:51 | 103T
    6 | 13:26:00 | 95
    2 | 13:34:35 | 103T
    3 | 14:21:08 | 105
    3 | 15:26:39 | 102T
    1 | 15:59:00 | 156

The following 28 trips are in transit live, as they have been found there
with our matching algorithm (logged trips matching multiple segments
have multiple rows):

    dev_id | log_start | log_end  | logged_type |       logged_name       | id  | segment_start | segment_end |  activity  | recd_type | recd_name 
    -------+-----------+----------+-------------+-------------------------+-----+---------------+-------------+------------+-----------+-----------
         1 | 09:41:00  | 09:44:00 | TRAM        | 3                       |   6 | 09:40:58      | 09:44:59    | IN_VEHICLE | TRAM      | 3
         1 | 10:06:00  | 10:19:00 | TRAM        | 7A                      |  12 | 10:07:24      | 10:13:23    | IN_VEHICLE | TRAM      | 7A
         1 | 10:06:00  | 10:19:00 | TRAM        | 7A                      |  13 | 10:13:34      | 10:14:56    | ON_BICYCLE |           | 
         1 | 10:06:00  | 10:19:00 | TRAM        | 7A                      |  14 | 10:15:37      | 10:20:11    | IN_VEHICLE | TRAM      | 7A
         1 | 10:46:00  | 10:52:00 | SUBWAY      | V                       |  19 | 10:43:41      | 10:52:45    | IN_VEHICLE | SUBWAY    | V
         1 | 11:01:00  | 11:06:00 | SUBWAY      |                         |  21 | 11:01:12      | 11:09:28    | IN_VEHICLE | SUBWAY    | V
         1 | 11:15:00  | 11:19:00 | SUBWAY      | M                       |  22 | 11:16:07      | 11:20:23    | IN_VEHICLE | SUBWAY    | M
         1 | 13:14:00  | 13:30:00 | SUBWAY      |                         |  29 | 13:13:31      | 13:30:27    | IN_VEHICLE | SUBWAY    | V
         1 | 14:18:00  | 14:30:00 | SUBWAY      |                         |  34 | 14:17:32      | 14:22:30    | IN_VEHICLE | SUBWAY    | V
         1 | 14:18:00  | 14:30:00 | SUBWAY      |                         |  35 | 14:22:41      | 14:26:37    | ON_BICYCLE |           | 
         1 | 14:18:00  | 14:30:00 | SUBWAY      |                         |  36 | 14:27:18      | 14:31:15    | IN_VEHICLE | SUBWAY    | V
         1 | 14:38:00  | 14:51:00 | SUBWAY      |                         |  37 | 14:31:25      | 14:39:23    | WALKING    |           | 
         1 | 14:38:00  | 14:51:00 | SUBWAY      |                         |  38 | 14:39:54      | 14:51:15    | IN_VEHICLE | SUBWAY    | V
         1 | 14:57:00  | 15:05:00 | SUBWAY      |                         |  40 | 14:56:47      | 15:06:45    | IN_VEHICLE | SUBWAY    | V
         1 | 15:36:00  | 15:55:00 | SUBWAY      |                         |  44 | 15:36:27      | 15:42:17    | IN_VEHICLE | SUBWAY    | M
         1 | 15:36:00  | 15:55:00 | SUBWAY      |                         |  45 | 15:42:27      | 15:48:05    | ON_BICYCLE |           | 
         1 | 15:36:00  | 15:55:00 | SUBWAY      |                         |  46 | 15:50:21      | 16:18:46    | IN_VEHICLE |           | 
         2 | 13:14:34  | 13:30:03 | SUBWAY      | To west                 |  54 | 13:14:01      | 13:31:34    | IN_VEHICLE | SUBWAY    | V
         3 | 10:59:27  | 11:10:08 | SUBWAY      | To east                 |  74 | 10:59:43      | 11:09:46    | IN_VEHICLE | SUBWAY    | V
         3 | 11:27:06  | 11:34:11 | SUBWAY      | To west                 |  76 | 11:28:05      | 11:34:36    | IN_VEHICLE | SUBWAY    | V
         3 | 13:14:14  | 13:24:28 | SUBWAY      | To west                 |  81 | 13:15:14      | 13:23:37    | IN_VEHICLE | SUBWAY    | V
         4 | 10:17:00  | 10:28:00 | TRAM        | 7A                      | 105 | 10:14:27      | 10:38:15    | IN_VEHICLE | TRAM      | 7A
         4 | 10:47:00  | 10:53:00 | SUBWAY      | to east (to Vuosaari)   | 107 | 10:45:59      | 10:53:39    | IN_VEHICLE | SUBWAY    | V
         4 | 13:21:50  | 13:31:00 | SUBWAY      | to west                 | 116 | 13:21:20      | 13:31:57    | IN_VEHICLE | SUBWAY    | V
         4 | 13:44:00  | 13:47:00 | SUBWAY      | to west                 | 118 | 13:45:12      | 13:47:30    | IN_VEHICLE | SUBWAY    | V
         4 | 14:28:00  | 14:31:00 | TRAM        | 9                       | 122 | 14:26:04      | 14:31:10    | IN_VEHICLE | TRAM      | 9
         5 | 10:52:00  | 11:02:00 | BUS         | 16                      | 136 | 10:52:30      | 11:03:28    | IN_VEHICLE | BUS       | 16
         5 | 14:40:00  | 14:50:00 | SUBWAY      | R                       | 149 | 14:40:46      | 14:50:51    | IN_VEHICLE | SUBWAY    | V
         5 | 15:10:00  | 15:20:00 | TRAM        | 9                       | 151 | 15:08:38      | 15:24:01    | IN_VEHICLE | TRAM      | 9
         6 | 14:01:00  | 14:17:00 | BUS         | 560                     | 162 | 13:59:21      | 14:25:50    | IN_VEHICLE | BUS       | 560
         8 | 10:18:00  | 10:23:00 | TRAM        | 9                       | 174 | 10:17:00      | 10:23:55    | IN_VEHICLE | TRAM      | 9
         8 | 10:44:00  | 10:53:00 | TRAM        | 9                       | 178 | 10:44:22      | 10:54:44    | IN_VEHICLE | TRAM      | 9
         8 | 11:08:00  | 11:13:00 | BUS         | 72                      | 180 | 11:07:46      | 11:14:48    | IN_VEHICLE | BUS       | 72
         8 | 11:25:00  | 11:41:00 | SUBWAY      |                         | 181 | 11:26:23      | 11:42:24    | IN_VEHICLE | SUBWAY    | M
         8 | 13:49:00  | 14:04:00 | BUS         | 550                     | 187 | 13:48:41      | 14:04:30    | IN_VEHICLE | BUS       | 550

These 38 trips have an overlapping IN_VEHICLE segment (and therefore
should be recognisable if the vehicle exists in live) (logged trips
matching multiple segments are listed multiple times):

    dev_id | log_start | log_end  | logged_type |       logged_name       | id  | segment_start | segment_end |  activity  | recd_type | recd_name 
    -------+-----------+----------+-------------+-------------------------+-----+---------------+-------------+------------+-----------+-----------
         1 | 09:31:00  | 09:35:00 | SUBWAY      | V                       |   4 | 09:31:44      | 09:36:37    | IN_VEHICLE |           | 
         1 | 09:48:00  | 09:51:00 | SUBWAY      |                         |   8 | 09:49:19      | 09:54:48    | IN_VEHICLE |           | 
         1 | 10:28:00  | 10:35:00 | SUBWAY      |                         |  17 | 10:28:00      | 10:37:33    | IN_VEHICLE |           | 
         1 | 11:42:00  | 11:43:00 | SUBWAY      | M                       |  24 | 11:40:36      | 11:46:04    | IN_VEHICLE |           | 
         1 | 11:56:00  | 12:01:00 | SUBWAY      |                         |  26 | 11:55:14      | 12:02:53    | IN_VEHICLE |           | 
         1 | 13:43:00  | 13:52:00 | TRAM        | 9                       |  31 | 13:41:40      | 13:46:33    | ON_BICYCLE |           | 
         1 | 13:43:00  | 13:52:00 | TRAM        | 9                       |  32 | 13:46:54      | 14:05:12    | IN_VEHICLE |           | 
         1 | 13:58:00  | 14:04:00 | SUBWAY      |                         |  32 | 13:46:54      | 14:05:12    | IN_VEHICLE |           | 
         1 | 15:24:00  | 15:26:00 | SUBWAY      |                         |  42 | 15:24:38      | 15:28:24    | IN_VEHICLE |           | 
         2 | 11:04:00  | 11:06:33 | SUBWAY      | To east                 |  50 | 11:04:13      | 11:12:20    | IN_VEHICLE |           | 
         2 | 11:26:18  | 11:50:00 | SUBWAY      | To east                 |  51 | 11:22:41      | 11:58:31    | IN_VEHICLE |           | 
         2 | 11:50:44  | 11:58:40 | SUBWAY      | To west                 |  51 | 11:22:41      | 11:58:31    | IN_VEHICLE |           | 
         3 | 10:21:21  | 10:23:01 | SUBWAY      | To east                 |  70 | 10:17:28      | 10:25:54    | IN_VEHICLE |           | 
         3 | 10:37:47  | 10:47:59 | SUBWAY      | To east                 |  72 | 10:36:03      | 10:48:14    | IN_VEHICLE |           | 
         3 | 11:56:11  | 11:58:43 | SUBWAY      | To west                 |  78 | 11:57:56      | 12:01:18    | IN_VEHICLE |           | 
         3 | 13:35:13  | 13:41:37 | TRAM        | 7A                      |  83 | 13:28:48      | 13:41:28    | IN_VEHICLE |           | 
         3 | 13:45:37  | 13:47:12 | SUBWAY      | To west                 |  85 | 13:45:42      | 13:48:24    | IN_VEHICLE |           | 
         3 | 14:07:59  | 14:09:23 | SUBWAY      | To west                 |  87 | 13:59:48      | 14:14:14    | IN_VEHICLE |           | 
         3 | 14:11:30  | 14:13:34 | SUBWAY      | To west                 |  87 | 13:59:48      | 14:14:14    | IN_VEHICLE |           | 
         3 | 14:42:40  | 14:52:31 | SUBWAY      | To east                 |  90 | 14:39:47      | 14:52:22    | IN_VEHICLE |           | 
         3 | 15:02:03  | 15:13:57 | SUBWAY      | To west                 |  92 | 15:01:12      | 15:16:46    | IN_VEHICLE |           | 
         4 | 09:39:00  | 09:45:00 | TRAM        | 9                       |  97 | 09:38:15      | 09:41:02    | IN_VEHICLE | TRAM      | 3
         4 | 09:39:00  | 09:45:00 | TRAM        | 9                       |  98 | 09:41:12      | 09:42:25    | ON_BICYCLE |           | 
         4 | 09:39:00  | 09:45:00 | TRAM        | 9                       |  99 | 09:43:08      | 09:45:15    | IN_VEHICLE | TRAM      | 1
         4 | 10:35:00  | 10:37:00 | SUBWAY      | to east (to Mellunmäki) | 105 | 10:14:27      | 10:38:15    | IN_VEHICLE | TRAM      | 7A
         4 | 11:04:00  | 11:13:00 | SUBWAY      | to east (to Mellunmäki) | 109 | 11:04:55      | 11:14:10    | IN_VEHICLE |           | 
         4 | 11:26:00  | 11:28:00 | SUBWAY      | to west                 | 111 | 11:23:59      | 11:31:36    | IN_VEHICLE |           | 
         4 | 11:36:00  | 11:38:00 | SUBWAY      | to east                 | 113 | 11:36:32      | 11:46:49    | IN_VEHICLE |           | 
         4 | 11:45:00  | 11:47:00 | SUBWAY      | to east                 | 113 | 11:36:32      | 11:46:49    | IN_VEHICLE |           | 
         4 | 13:57:00  | 14:01:00 | SUBWAY      | to west                 | 120 | 13:57:00      | 14:02:39    | IN_VEHICLE |           | 
         4 | 15:15:00  | 15:20:00 | SUBWAY      | to east                 | 125 | 15:15:29      | 15:20:13    | IN_VEHICLE |           | 
         5 | 09:58:00  | 10:08:00 | TRAM        | 7A                      | 133 | 09:58:03      | 10:14:13    | IN_VEHICLE |           | 
         5 | 10:12:00  | 10:13:00 | SUBWAY      | M                       | 133 | 09:58:03      | 10:14:13    | IN_VEHICLE |           | 
         5 | 11:11:00  | 11:14:00 | SUBWAY      | R                       | 138 | 11:09:19      | 11:14:28    | IN_VEHICLE |           | 
         5 | 11:18:00  | 11:20:00 | BUS         | 67                      | 140 | 11:18:23      | 11:20:53    | IN_VEHICLE |           | 
         5 | 11:38:00  | 11:52:00 | SUBWAY      | M                       | 142 | 11:38:53      | 11:50:59    | IN_VEHICLE |           | 
         5 | 15:36:00  | 15:39:00 | TRAM        | 9                       | 153 | 15:37:43      | 15:40:10    | IN_VEHICLE |           | 
         6 | 11:38:00  | 11:52:00 | SUBWAY      |                         | 156 | 11:45:26      | 11:50:26    | IN_VEHICLE |           | 
         6 | 14:19:00  | 14:25:00 | SUBWAY      |                         | 162 | 13:59:21      | 14:25:50    | IN_VEHICLE | BUS       | 560
         6 | 15:50:00  | 15:59:00 | TRAM        | 9                       | 165 | 15:50:58      | 15:59:24    | IN_VEHICLE |           | 
         8 | 11:52:00  | 11:58:00 | SUBWAY      |                         | 183 | 11:52:35      | 12:00:18    | IN_VEHICLE |           | 

Finally, these 13 trips have no overlapping IN_VEHICLE segment:

    dev_id | log_start | log_end  | logged_type |       logged_name       | id  | segment_start | segment_end |  activity  | recd_type | recd_name 
    -------+-----------+----------+-------------+-------------------------+-----+---------------+-------------+------------+-----------+-----------
         4 | 15:53:00  | 15:55:00 | SUBWAY      | to west                 | 127 | 15:41:39      | 15:58:40    | WALKING    |           | 
         5 | 11:30:00  | 11:31:00 | SUBWAY      | R                       | 141 | 11:21:26      | 11:36:31    | WALKING    |           | 
         5 | 13:22:00  | 13:28:00 | SUBWAY      | M                       | 144 | 13:17:08      | 13:23:38    | WALKING    |           | 
         5 | 13:34:00  | 13:43:00 | SUBWAY      | R                       | 145 | 13:28:54      | 13:37:27    | WALKING    |           | 
         5 | 13:54:00  | 14:02:00 | SUBWAY      | V                       |     |               |             |            |           | 
         5 | 14:20:00  | 14:30:00 | SUBWAY      | R                       | 148 | 14:02:42      | 14:39:19    | WALKING    |           | 
         5 | 15:36:00  | 15:39:00 | TRAM        | 9                       | 152 | 15:34:32      | 15:37:11    | WALKING    |           | 
         5 | 15:51:00  | 15:52:00 | TRAM        | 8                       |     |               |             |            |           | 
         5 | 15:56:00  | 15:57:00 | SUBWAY      | M                       |     |               |             |            |           | 
         6 | 13:47:00  | 13:49:00 | SUBWAY      |                         | 161 | 13:44:23      | 13:57:30    | WALKING    |           | 
         6 | 14:29:00  | 14:30:00 | SUBWAY      |                         | 163 | 14:26:10      | 15:03:54    | WALKING    |           | 
         6 | 15:02:00  | 15:20:00 | SUBWAY      |                         | 163 | 14:26:10      | 15:03:54    | WALKING    |           | 
         6 | 15:41:00  | 15:43:00 | TRAM        | 2                       | 164 | 15:27:41      | 15:50:48    | WALKING    |           | 

Note also that:
* 3/13 trips (2 subway + 1 tram) have no corresponding data at all
* 10/13 trips matched by walking (in 6/10 cases shadowing the whole trip)

## static timetables

The static timetables from HRT are not included in the repository, but they are available through this link:
[http://dev.hsl.fi/gtfs/hsl_20160825T125101Z.zip](http://dev.hsl.fi/gtfs/hsl_20160825T125101Z.zip).

The
[format is specified by Google](https://developers.google.com/transit/gtfs/). It
can be used e.g. with [OpenTripPlanner](http://www.opentripplanner.org/). 

## train history information

JSON-format information in the [trains-json folder](https://github.com/aalto-trafficsense/public-transport-dataset/tree/master/trains-json) fetched from:
http://rata.digitraffic.fi/api/v1/history?departure_date=2016-08-26

The returned JSON-file is a "junat" object, as described (in Finnish) at:
http://rata.digitraffic.fi/api/v1/doc/index.html#Junavastaus

The train data references stations, which are obtained as:
http://rata.digitraffic.fi/api/v1/metadata/stations

The description of the stations "Liikennepaikat" format is available (in Finnish) at:
http://rata.digitraffic.fi/api/v1/doc/index.html#Liikennepaikkavastaus

The train data is licensed under the [Creative Commons BY 4.0 licence](http://creativecommons.org/licenses/by/4.0/) from [Digitraffic](http://www.liikennevirasto.fi/web/en/open-data/services/digitraffic#.V9BlOxB96Ho) offered by the [Finnish Traffic Agency](http://www.liikennevirasto.fi/web/en).

