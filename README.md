# public-transport-dataset
This dataset is composed of position and activity recognition samples of 8 researchers between 9 am and 4 pm EET+DST on August 26th 2016. Collection of data was pre-agreed with every participant, therefore the dataset can be made publically available. The target was to create a dataset, which could be used for testing and benchmarking of algorithms for automatic recognition of public transportation trips from mobile phone sample data. Seven participants executed as many public transportation trips as possible during the designated time, especially emphasizing travel by subway, as it has been the most challenging transportation mode for automatic recognition. The eight participant logged some private car trips to provide comparison data, which should not match with any public transportation. Due to the exceptional amount of travel during one day, this dataset cannot be used as a source for the regular travel habits of public transportation users.

The dataset consists of the following components:
* Terminal samples
* Terminal models
* Manual log (supplemented by subway station maps)
* Public transport fleet positions
* Static timetables

## terminal-samples
Mobile client samples were collected using the TrafficSense android client. The client program uses the fused location provider and activity recognition from Google play services. The following data is collected into the dataset:
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


