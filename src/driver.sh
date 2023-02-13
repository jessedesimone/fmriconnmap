#!/bin/sh

cat ../CHANGELOG.md

gen_error_msg="\

    Usage: ./driver.sh [-h] [-s] [-r] [-n] [-o]
    Arguments:
    -h  help
    -s  setup
    -r  roi map
    -n  netcor
    -o  overwrite 

    NOTE: Overwrite option should only be passed when running -srn
    This option will remove all output files (i.e., all neccesary
    dependencies for later stages of the code). It is best to not
    include this option without a complete understanding of the code

    "
    while getopts ":hsrn" opt; do
        case ${opt} in
                h|\?) #help option
                    echo "$gen_error_msg"
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
                o) overwrite
                    oflag=1
                    ;;
        esac
    done
    if [ $OPTIND -eq 1 ]; then 
        echo "++ driver.sh requires argument"
        echo "$gen_error_msg"
        exit 1
        fi
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
#source dependencies.sh

#set the python virtual environment
source ~/env/bin/activate

#create log file
: 'log file will capture terminal output each time driver is run
can be used to check for and troubleshoot errors'
log_file=${log_dir}/log_fmriconnmap.${dt}
touch $log_file

#define subjects
SUB=`cat ${data_dir}/id_subj`
echo "number of subjects in analysis"
awk 'END { print NR }' ${data_dir}/id_subj

#define roi coordinate list
ilist=${roi_dir}/00_list_of_all_roi_centers_test.txt


for sub in ${SUB[@]}
do
    #==========handle options==========
    if [ "$sflag" ]; then
        : 'run 00_setup'
        echo "run 00_setup"
        cp ${roi_dir}/00_list_of_all_roi_centers_test.txt $data_dir/$sub/
        echo $sub > $data_dir/$sub/subname.txt
        cd $data_dir/$sub
        tcsh -c ${src_dir}/00_setup.tcsh 2>&1 | tee $log_fil
    fi
done