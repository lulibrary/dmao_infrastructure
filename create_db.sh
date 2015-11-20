#!/usr/bin/env bash

environment=${1}

if [[ ${environment} == "jhk_dev" ]]
then
    home_dir=${HOME}/projects/dmao_infrastructure
    dbname=DMAOnline
    load_demo_data=1
    user_name="krug"
    psql_path="/usr/local/bin"
elif [[ ${environment} == "dev" ]]
then
    home_dir=${HOME}/deploy
    dbname=dmaonline_dev
    load_demo_data=1
    user_name="dmaonline_dev"
    psql_path="/bin"
elif [[ ${environment} == "test" ]]
then
    home_dir=${HOME}/deploy
    dbname=dmaonline_test
    load_demo_data=0
    user_name="dmaonline_test"
    psql_path="/bin"
elif [[ ${environment} == "live" ]]
then
    home_dir=${HOME}/deploy
    dbname=dmaonline_live
    load_demo_data=0
    user_name="dmaonline_live"
    psql_path="/bin"
else
    echo "Incorrect environment specified"
    exit 1
fi

if [[ ${environment} == "live" ]]
then
    read -p "Are you sure, this will wipe the database (YES to continue): " yn
    if [[ "${yn}" != "YES" ]]
    then
        exit 0
    fi
fi

echo "Creating ${dbname}"
sudo su - ${user_name} -c "${psql_path}/psql ${dbname} -f ${home_dir}/database.sql > /dev/null"
if [ ${load_demo_data} -eq 1 ]
then
    echo "Loading sample data into ${dbname}"
    sudo su - ${user_name} -c "${psql_path}/psql ${dbname} -f ${home_dir}/demo_data_loader.sql > /dev/null"
fi
