# Scripts to setup a PostgreSQL database

This directory contains the scripts to create a new local PostgreSQL
database and import the data in the repository CSV-files into it.

The database schema follows the conventions of the TrafficSense project to
maintain compatibility. Especially the lat-lng coordinates in the CSV
files are converted to single `coordinate` entries used by the
`postgis` extension, using `ST_SetSRID(ST_Point(lng, lat),4326)`.

## Required installations

If not already installed, install
[postgresql](http://www.postgresql.org/) and
[postgis](http://postgis.net/) packages. They are available for Debian Linuxes (Ubuntu) via `apt-get`, and [homebrew](http://brew.sh/) for Mac OS X.

## Init a new empty database, import tables

1. Run `$ ./init_start_psql.sh <path-to-new-database-dir>` (should
   work on most flavors of *nix, not on Windows). The script
   creates the directory, initiates the database and starts the
   postgresql server. Leave the server running, it can be closed later with
   CTRL-C. When you need to run it again, use `postgres -D <path-to-new-database-dir>`.
1. Switch to another terminal window.
1. Run the init script on psql: `psql -U postgres -f
   create-db-from-csv.sql`. (If you need to re-import the data to an
   initialised database, use `import-db-from-csv.sql` instead.)
1. A list of `CREATE ROLE`, `CREATE TYPE` etc. should follow.

Done! To verify that the db was created correctly, start psql command
line:

1. `psql -U postgres`
1. `postgres=# \dt` should printout the following:

                           List of relations
         Schema |         Name         | Type  |     Owner     
        --------+----------------------+-------+---------------
         public | device_data          | table | regularroutes
         public | device_data_filtered | table | regularroutes
         public | device_models        | table | regularroutes
         public | manual_log           | table | regularroutes
         public | spatial_ref_sys      | table | postgres
		 public | transit_live         | table | regularroutes
         (6 rows)

## Test with recognised trips

File `csv/recognised-summary.csv` contains sample recognitions using
three different methods ("old live", "new live" and "static"). To
perform tests with one of those, use the following procedure:

1. File `import-recognised.sql` imports data from the csv-file to a
   table in the database. The end of the file contains import commands
   for all three recognition methods and a combination of "new live" +
   "static" ("new live" higher priority). Edit the file to uncomment
   the method you want to use, keep others commented out.
1. Run the file in postgres: `postgres=# \i import-recognised.sql`.
1. Recognition statistics can be obtained with `postgres=# \i
report-recognised.sql`.
1. A side-by-side comparison table showing manual log entries next to
   the recognised trips is produced by `postgres=# \i
   compare-recognised.sql`. This comparison is over-inclusive in
   showing all the log-entry recognised-segment pairs, which overlap
   by more than 60 seconds, but that has been found useful for diagnostics.

## Recognised_trips table format

The reporting and comparison scripts described above can be used over
the results of any newly implemented recognition method, as long as
the output format is the same. The assumed table name is
`recognised_trips` with the following format:

       Column   |            Type             |                           Modifiers                           
    ------------+-----------------------------+---------------------------------------------------------------
     id         | integer                     | not null default nextval('recognised_trips_id_seq'::regclass)
     device_id  | integer                     | not null
     time_start | timestamp without time zone | not null
     time_end   | timestamp without time zone | not null
     activity   | activity_type_enum          | 
     line_type  | transit_type_enum           | 
     line_name  | character varying           | 
    Indexes:
        "recognised_trips_pkey" PRIMARY KEY, btree (id)
        "idx_recognised_trips_device_id_time" btree (device_id, time_start)
        "idx_recognised_trips_time" btree (time_start)

The setup commands to initialise an empty table can be found in the `import-recognised.sql` script.

