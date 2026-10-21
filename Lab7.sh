#!/bin/bash


#ird at fuggvennye ahol meglehet adni az urlt es max timeot, legyen a maxtime opcionalis. 

connect(){
    if [ $1 ]; then
        URL=$1
        echo "[CHECKING URL...]: $1"
    else
        echo "No url specified"
    fi

    if [ $2 ]; then
        TIME=$2
    else
        TIME=8
    fi
    echo "Max-time: $2"

    if curl -s --max-time $TIME -o "data.txt" $URL; then
        VAN_HALOZAT=1
        echo "halozat: van"
    else
        VAN_HALOZAT=0
        echo "halozat: nincs"
    fi

}

connect "https://api.frankfurter.dev/v1/latest" 4

