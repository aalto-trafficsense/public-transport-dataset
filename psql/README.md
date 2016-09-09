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
   CTRL-C. When you need to run it again, use `postgres -D pttestdb`, where `pttestdb` is the path to the directory with your database.
1. Switch to another terminal window.
1. Run the init script on psql: `psql -U postgres -f create-db-from-csv.sql`
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




