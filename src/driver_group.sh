#!/bin/sh
: 'Driver to run all fmriconnmap modules
Create individual network-level connectivity maps for specified ROI coordinate centers'

cat ../CHANGELOG.md

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

#define roi coordinate files
ilist=${roi_dir}/00_list_of_all_roi_centers_test.txt

#copy required files to outdir
cp $ilist ${out_dir}/00_list_of_all_roi_centers_test.txt
cp ${anat_template}* $out_dir/



tcsh -c ${src_dir}/03_connmap.tcsh 2>&1 | tee -a $log_file





    