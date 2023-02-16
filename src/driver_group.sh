#!/bin/sh
: 'Driver to create group-level functional connectivity maps for a specified list of ROI centers'

cat ../CHANGELOG.md

gen_error_msg="\

    Usage: ./driver_group.sh [-o] [-h]
    Optional arguments:
    -h  help
    -o  overwrite existing output directory

    "
    while getopts ":hsrnmo" opt; do
        case ${opt} in
                h|\?) #help option
                    echo "$gen_error_msg"
                    exit 1
                    ;;
                o) #overwrite
                    oflag=1
                    ;;
        esac
    done
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
source dependencies.sh

#set the python virtual environment
source ~/env/bin/activate

#create log file
: 'log file will capture terminal output each time driver is run
can be used to check for and troubleshoot errors'
log_file=${log_dir}/log_fmriconnmap_group.${dt}
touch $log_file
echo "Start time: $dt" 2>&1 | tee $log_file
echo "++ Creating group-level connectivity maps" 2>&1 | tee -a $log_file

#define subjects
SUB=`cat ${data_dir}/id_subj`
echo "number of subjects in analysis" 2>&1 | tee -a $log_file
awk 'END { print NR }' ${data_dir}/id_subj 2>&1 | tee -a $log_file

#define roi coordinate files
ilist=${roi_dir}/00_list_of_all_roi_centers_test.txt

#define anat template
anat_template=${nii_dir}/MNI152_T1_2009c+tlrc


#==========handle options==========
if [ "$oflag" ]; then
    echo "++ Overwrite option selected" 2>&1 | tee -a $log_file
    if [ -d $out_dir ]; then
        echo "Output directory exists | !!! OVERWRITING !!!"
        rm -rf $out_dir
        mkdir $out_dir
    else
        echo "Creating output directory with path: $out_dir"
        mkdir -p $out_dir
    fi
else
    if [ -d $out_dir ]; then
        echo "Output directory exists | run overwrite option [-o]"
        exit 0
    else
        echo "Creating output directory with path: $out_dir"
        mkdir -p $out_dir
    fi
fi
cd $out_dir

#==========setup==========
#run setup script
#copy required files to outdir
cp $ilist ${out_dir}/00_list_of_all_roi_centers_test.txt
if [! -f ${out_dir}/${anat_template}.HEAD ]; then
    3dcopy ${anat_template} ${out_dir}/
fi

: 'creates a temp list of ROIs'
if [ -f _tmp_roi_list.txt ]; then
    rm -rf _tmp_roi_list.txt
fi
tcsh -c ${src_dir}/03_group_setup.tcsh 2>&1 | tee -a $log_file

ROI=`cat _tmp_roi_list.txt`
for roi in ${ROI[@]}; 
    do mkdir -p $roi

    : 'copy individual z maps for creation of group level maps'
    echo "++ copying individual subject z maps" 2>&1 | tee -a $log_file
    for sub in ${SUB[@]}
    do
        cp ${data_dir}/$sub/NETCORR_000_INDIV/WB_Z_ROI_${roi}.nii.gz ${out_dir}/${roi}/_tmp_${sub}_WB_Z_ROI_${roi}.nii.gz
    done

    cd $roi
        #==========create group-level connectivity map==========
        #here - run tcsh script for group level connectivity map


        #rm -rf _tmp*
    cd ../

done







    