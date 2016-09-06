# public-transport-dataset
This dataset is composed of position and activity recognition samples of 8 researchers between 9 am and 4 pm EET+DST on August 26th 2016 and related transport infrastructure data. Data collection for the limited period was pre-agreed with every campaign participant. The target was to create a dataset to be used for testing and benchmarking of algorithms for automatic recognition of public transportation trips from mobile phone sample data. Seven participants executed as many public transportation trips as possible during the designated time, especially emphasizing travel by subway, as it has been the most challenging transportation mode for automatic recognition. Some private car trips were also logged to provide comparison data, which should not match with any public transportation. Due to the exceptional amount of travel during one day, this dataset cannot be used as a source for studying regular travel habits of public transportation users.

The dataset consists of the following components:
* Terminal samples
* Terminal models
* Manual log (supplemented by subway station maps)
* Public transport fleet live position samples
* Reference to static timetables

## terminal-samples
Mobile client samples were collected using the TrafficSense android client. The client program uses the fused location provider and activity recognition from Google play services. The following fields are collected into the dataset:
  1. terminal (integer, stable identifier for the device, used also for manual bookkeeping)
  1. time (timestamp without timezone)
  1. lat (double, latitude)
  1. lng (double, longitude)
  1. accuracy (double, radius)
  1. activity_1 (enum value of highest confidence activity)
  1. activity_1_conf (integer percentage of recognition certainty, 100 is best)
  1. activity_2 (enum value of second-highest confidence activity)
  1. activity_2_conf (integer percentage of recognition certainty)
  1. activity_3 (enum value of second-highest confidence activity)
  1. activity_3_conf (integer percentage of recognition certainty)

The enum values for the activities are: IN_VEHICLE, ON_BICYCLE, ON_FOOT, RUNNING, STILL, TILTING, UNKNOWN, WALKING

### missing points due to ACTIVE-SLEEP states and other filtering

The client transfers between ACTIVE and SLEEP states with the following criteria:

ACTIVE ----40 seconds STILL only----> SLEEP

ACTIVE <-------not STILL------------- SLEEP

If coordinates show movement during the STILL period, the timer is restarted from 40 seconds.

In ACTIVE state position is requested with high accuracy and 10 second interval. In SLEEP state position request drops to "no power" priority, which means that position fixes are given to our client, if someone else requests them.

The received position fixes are filtered as follows:
* Accuracy needs to be better than 1000m
* If activity != last queued activity, point is accepted
* If activity == last queued activity and distance to last queued activity > accuracy, point is accepted

Activity is always requested with 10 second interval, but as a form of power saving, during STILL situations activity recognition interval has been observed to raise up to 180 seconds. Each queued position is complemented with the latest activity information. The timestamp of the entry is the timestamp of the position, not of the activity. The same reported activity may repeat over multiple points.

As a result, sometimes the client may need up to ~200 seconds to wake up from SLEEP state. It has also been observed in rail traffic that sometimes the ride is so smooth that the client goes to SLEEP state during travel.

## terminal-models

Lists the type string for the mobile phone used in the test. Included, as there are some differences in e.g. activity recognition performance between different devices. Contains the following columns:
  1. Terminal (integer number of the terminal)
  1. Model (string name of the model)

Table length: 8 rows.

## manual-log

The manual bookkeeping of the test persons on the trips made. Contains the following columns per trip leg:
  1. Terminal (integer number of the terminal)
  1. St. entrance (string description of entrance to station building, if applicable)
  1. St. entry time (time of entering station, if applicable)
  1. Vehicle type (enum Metro / Bus / Tram / Train / Car)
  1. Vehicle label (string identifier, e.g. 7A, 102T, U, V)
  1. Vehicle dep. time (time of vehicle departure in trip start)
  1. Vehicle boarding stop (string description of the platform or other station where vehicle was boarded)
  1. Vehicle stop time (time of vehicle stop at trip end)
  1. Vehicle exit stop (string description of the platform or other station where the vehicle was exited)
  1. St. exit location (string description of exit to station building, if applicable)
  1. St. exit time (time of exiting station, if applicable)
  1. Comments (string freeform comments about the trip leg)


## transit-live-samples

Not included yet, license under clarification.

## static timetables

The static timetables from HRT are not included in the repository, but they are available through this link:
[http://dev.hsl.fi/gtfs/hsl_20160825T125101Z.zip](http://dev.hsl.fi/gtfs/hsl_20160825T125101Z.zip).

