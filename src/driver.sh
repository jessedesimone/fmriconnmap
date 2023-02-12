#!/bin/sh

: '(C) Jesse DeSimone, Ph.D. 2022
master script to call all modules'

gen_error_msg="\
    Driver to run afni_proc.py

    Usage: ./driver.sh [-h] [-s] [-r] [-n]
    Arguments
    -h  help
    "
    while getopts ":hsrn" opt; do
        case ${opt} in
                h|\?) #help option
                    echo -e "$gen_error_msg"
                    exit 1
                    ;;
                s) #run setup
                    sflag=1
                    ;;
                r) #run roi map
                    rflag=1
                    ;;
                n) run netcor
                    nflag=1
                    ;;
                *)  #no option passed
                    echo "no option passed"
                    echo -e "$gen_error_msg"
                    ;;
        esac
    done
    shift $((OPTIND -1))

#==========configuration==========
echo "DRIVER.SH STARTED"

#set datetime
: 'used for datetime stamp log files'
dt=$(date "+%Y.%m.%d.%H.%M.%S")
echo "Start time: $dt"

#set directories
: 'call directories.sh'
source src/config_directories.sh

#check dependencies
: 'uncomment if you need to check dependencies
code should run fine on current LRN systems'
source dependencies.sh