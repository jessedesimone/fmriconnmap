#!/bin/sh

cat ../CHANGELOG.md

gen_error_msg="\

    Usage: ./driver.sh [-h] [-s] [-r] [-n] | [-o]
    Arguments:
    -h  help
    -s  setup
    -r  roi map
    -n  netcor
    -o  overwrite 

    NOTE: Overwrite [-o] will remove all output files for subjects 
    specified in data/id_subj. Use this option with *extreme caution*. 

    "
    while getopts ":hsrno" opt; do
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
                n) #run netcor
                    nflag=1
                    ;;
                o) #overwrite
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

#set directories
: 'call directories.sh'
source config_directories.sh

#enable extended globbing
: 'enables pattern matching for removing files with overwrite option'
shopt -s extglob

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
echo "Start time: $dt" 2>&1 | tee $log_file

#define subjects
SUB=`cat ${data_dir}/id_subj`
echo "number of subjects in analysis" 2>&1 | tee -a $log_file
awk 'END { print NR }' ${data_dir}/id_subj 2>&1 | tee -a $log_file

#define roi coordinate files
ilist=${roi_dir}/00_list_of_all_roi_centers_test.txt
ilabtxt=${roi_dir}/00_input_keys_values_test.txt

for sub in ${SUB[@]}
do
    echo " " 2>&1 | tee -a $log_file
    echo "*** SUBJECT: $sub ***" 2>&1 | tee -a $log_file

    #define infiles
    epi=errts.${sub}.anaticor+tlrc
    anat=anat_final.${sub}+tlrc

    # copy some files
    cp $ilist ${data_dir}/${sub}/00_list_of_all_roi_centers_test.txt
    cp $ilabtxt ${data_dir}/${sub}/00_input_keys_values_test.txt
    echo $sub > ${data_dir}/${sub}/subname.txt

    cd $data_dir/$sub
    #==========handle options==========
    if [ "$oflag" ]; then
        echo "++ Overwrite option selected" 2>&1 | tee -a $log_file
        echo "++ !! OVERWRITING OUTPUT DIRECTORY !!" 2>&1 | tee -a $log_file
        rm -v !(*+tlrc.*)
    fi
    if [[ -f ${epi}.HEAD ]] && [[ -f ${anat}.HEAD ]]; then
        : 'check that infiles for subject exist, then proceed'
        echo "++ epi and anat infiles exist" 2>&1 | tee -a $log_file

        #here - input if statement to not run code if final output file exists
        #if [ ! -f <outfile> ]; then run sflag, rflag, nflag

        if [ "$sflag" ]; then
            : 'run 00_setup.tcsh'
            echo "++ setup option selected" 2>&1 | tee -a $log_file
            tcsh -c ${src_dir}/00_setup.tcsh 2>&1 | tee -a $log_file
        fi
        if [ "$rflag" ]; then
            : 'run 01_make_single_roi_map.tcsh'
            echo "++ make single ROI map option selected" 2>&1 | tee -a $log_file
            tcsh -c ${src_dir}/01_make_single_roi_map.tcsh 2>&1 | tee -a $log_file
        fi


        #else echo outfiles alread exist for subject

    else
        : 'terminate script if missing input files'
        echo "anat and/or epi infiles not found for $sub"
        echo "terminating script"
        exit 1
    fi
done