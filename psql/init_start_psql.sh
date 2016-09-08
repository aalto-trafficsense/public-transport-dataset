#!/bin/bash

# Initialize a new database and start a server on it

if [ "$#" -ne 1 ]; then
    Echo "One parameter required: Name of (or path to) the directory where the new database will be created."
    Echo "(the directory will be created by this shell script)"
    exit 1
fi

# Create the directory
mkdir $1

# Initialize a database
initdb -D $1 -U postgres

# Start postgres on it
postgres -D $1
