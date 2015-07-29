#!/usr/bin/env bash

debug=1

home_dir=/home/krug/PycharmProjects/dmao_infrastructure

psql -h lib-ldiv.lancs.ac.uk DMAonline -f $home_dir/database.sql

if [[ $debug == 1 ]]
then
    psql -h lib-ldiv.lancs.ac.uk DMAonline -f $home_dir/demo_data_loader.sql
fi