#!/bin/bash
: 'Driver to create group-level ROI-to-ROI correlation matrix using output files from fmriconnmap'

head -9 ../CHANGELOG.md

gen_error_msg="\

    Usage: ./driver_indiv.sh [-r] [-o <string>] | [-h]
    Required arguments:
    -r  run roi2roi_conn_mat
    -o  specify output directory

    Optional arguments:
    -h  help

    NOTES: 
    - [-o <string>] is required when [-r] is specified

    "
    while getopts ":hro:" opt; do
        case ${opt} in
                h|\?) #help option
                    echo "$gen_error_msg"
                    exit 1
                    ;;
                r) #create group corrmat
                    rflag=1
                    ;;
                o) #specify output directory name
                    oflag=${OPTARG}
                    ;;

                *) #no option given
                    echo "$gen_error_msg"
                    exit 1
                    ;;
        esac
    done
    if [ $OPTIND -eq 1 ]; then 
        echo "++ ERROR: driver.sh requires at 2 arguments"
        echo "$gen_error_msg"
        exit 1
    fi

    if [ $rflag ]; then
        : 'rflag specified - therefore check that output was specified'
        if [ ! "$oflag" ]; then
            echo "ERROR: [-o <string>] must be provided when [-g] is provided"
            echo "$gen_error_msg" >&2
            exit 1
        fi
    fi
    shift $((OPTIND -1))

#==========configuration==========
echo "DRIVER.SH STARTED"

#set datetime
: 'used for datetime stamp log files'
dt=$(date "+%Y.%m.%d.%H.%M.%S")

#set directories
: 'call config_directories.sh'
source config_directories.sh

#check dependencies
: 'uncomment if you need to check dependencies
code should run fine on current LRN systems'
source dependencies.sh

#set the python virtual environment
: 'depends on system | may not be needed'
source ~/env/bin/activate

#create log file
: 'log file will capture terminal output each time driver is run
can be used to check for and troubleshoot errors'
log_file=${log_dir}/log_fmriconnmap_connmat.${dt}
touch $log_file
echo "Start time: $dt" 2>&1 | tee $log_file
echo "++ Creating group-level connectivity matrix" 2>&1 | tee -a $log_file

#define subjects
SUB=`cat ${data_dir}/id_subj`
echo "number of subjects in analysis" 2>&1 | tee -a $log_file
awk 'END { print NR }' ${data_dir}/id_subj 2>&1 | tee -a $log_file

#define roi coordinate files
ilist=${roi_dir}/00_list_of_all_roi_centers.txt
ilabtxt=${roi_dir}/00_input_keys_values.txt

# check if outdir exists or create
out_path_gen () {
    mkdir $mat_out_dir
    echo $mat_out_dir > $mat_out_dir/_tmp_outpath.txt
    cp $mat_out_dir/_tmp_outpath.txt ${pkg_dir}/connmat/_tmp_outpath.txt
    source ${src_dir}/07_connmat_proc.sh
}

if [ "$rflag" ]; then
    mat_out_dir=$mat_out_dir/$oflag
    echo "******* outdir is $mat_out_dir ******* "
    if [ ! -d $mat_out_dir ]; then 
        echo "++ creating output directory" 2>&1 | tee -a $log_file
        out_path_gen
    else
        echo "++ output directory already exists" 2>&1 | tee -a $log_file
        echo "++ run driver with new output name" 2>&1 | tee -a $log_file
        echo "++ terminating" 2>&1 | tee -a $log_file
        exit 1
    fi
fi
