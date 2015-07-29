#!/usr/bin/env bash

debug=1

home_dir=/home/krug/PycharmProjects/dmao_infrastructure


if [[ ${debug} == 1 ]]
then
    psql DMAonline -f ${home_dir}/database.sql
    psql DMAonline -f ${home_dir}/demo_data_loader.sql
else
    dbh=lib-ldiv.lancs.ac.uk
    psql -h ${dbh} DMAonline -f ${home_dir}/database.sql
    psql -h ${dbh} DMAonline -f ${home_dir}/demo_data_loader.sql
fi