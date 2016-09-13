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

In terms of trips, the following (10) bus trips are therefore not in transit-live:

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

The following trips are in transit live, as they have been found there
with our matching algorithm:



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

