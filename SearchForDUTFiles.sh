#!/bin/bash

function print_files {
    #find ./ -type f | find . -type f -name \*.v
    SV_files=$(find ./ -type f | find . -type f -name \*.sv)
    SV_files+=$(find ./ -type f | find . -type f -name \*.v)

    for element in $SV_files
    do
        echo ${1}${element:2} >> ../FilesList.txt
    done
}

RED='\033[0;31m'
NOCOLOR='\033[0m'

if [ -z "$1" ]
then
    echo -e "${RED}Searching in this directory${NOCOLOR}"
    print_files
else
    echo -e "${RED}Searching in directory $1${NOCOLOR}"
    cd $1
    print_files $1
fi
