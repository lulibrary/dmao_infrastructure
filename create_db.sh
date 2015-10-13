#!/usr/bin/env bash

debug=1
load_demo_data=1

home_dir=/home/krug/PycharmProjects/dmao_infrastructure


if [[ ${debug} == 1 ]]
then
    psql DMAonline -f ${home_dir}/database.sql > /dev/null
    if [[ ${load_demo_data} == 1 ]]
    then
        psql DMAonline -f ${home_dir}/demo_data_loader.sql > /dev/null
    fi
else
    dbh=lib-ldiv.lancs.ac.uk
    psql -h ${dbh} DMAonline -f ${home_dir}/database.sql
    if [[ ${load_demo_data} == 1 ]]
    then
        psql -h ${dbh} DMAonline -f ${home_dir}/demo_data_loader.sql
    fi
fi