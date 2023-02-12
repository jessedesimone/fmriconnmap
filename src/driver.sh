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
source config_directories.sh

#check dependencies
: 'uncomment if you need to check dependencies
code should run fine on current LRN systems'
source dependencies.sh

#create log file
: 'log file will capture terminal output each time driver is run
can be used to check for and troubleshoot errors'
log_file=${log_dir}/log_fmriconnmap.${dt}

#define subjects
sub_list=`cat ${data_dir}/id_subj`
cat $sub_list
: 'count number of lines in sub_list'
n=awk 'END { print NR }' ${sub_list}
echo "running analysis for $n subjects"