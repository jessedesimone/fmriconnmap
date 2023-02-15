#!/bin/sh
: 'Driver to run all fmriconnmap modules
Create individual network-level connectivity maps for specified ROI coordinate centers'

cat ../CHANGELOG.md

gen_error_msg="\

    Usage: ./driver.sh [-h] [-s] [-r] [-n] | [-o]
    Arguments:
    -h  help
    -s  setup individual
    -r  roi map individual
    -n  netcorr individual
    -o  overwrite 

    NOTE: Overwrite [-o] will remove all output files and should be employed with *extreme caution*
    This option should really only be run if you want to start from a clean slate 

    "
    while getopts ":hsrnmo" opt; do
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
                n) #run netcorr individual
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
source dependencies.sh

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

#define anatomical file
anat_template=${nii_dir}/MNI152_T1_2009c+tlrc
anat_mask=${nii_dir}/MNI152_T1_2009c_mask_r.nii

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
    cp $anat_mask ${data_dir}/${sub}/anat_mask.nii

    echo $sub > ${data_dir}/${sub}/subname.txt

    cd $data_dir/$sub
    #==========handle options==========
    if [ "$oflag" ]; then
        echo "++ Overwrite option selected" 2>&1 | tee -a $log_file
        echo "++ !! OVERWRITING OUTPUT DIRECTORY !!" 2>&1 | tee -a $log_file
        rm -v !(*+tlrc.*)
        rm -rf NETCORR_000_INDIV
    fi
    if [[ -f ${epi}.HEAD ]] && [[ -f ${anat}.HEAD ]]; then
        : 'check that infiles for subject exist, then proceed'
        echo "++ epi and anat infiles exist" 2>&1 | tee -a $log_file
        #==========setup==========
        if [ "$sflag" ]; then
            : 'run 00_setup.tcsh'
            echo " " 2>&1 | tee -a $log_file
            echo "++ setup option selected" 2>&1 | tee -a $log_file
            : 'check to see if number of outfiles match number of roi centers specified
            only run script if they do not match | overwrite protection'
            roi_in=$(grep -c ".*" ${roi_dir}/00_list_of_all_roi_centers_test.txt)
            roi_out=$(ls -l roi_mask_00* | grep ^- | wc -l)
            if [ "$roi_in" -eq "$roi_out" ]; then
                echo "outfiles already exist | skipping subject"
            else
                tcsh -c ${src_dir}/00_setup.tcsh 2>&1 | tee -a $log_file
            fi
        fi
        #==========create ROI map==========
        if [ "$rflag" ]; then
            : 'run 01_make_single_roi_map.tcsh'
            echo " " 2>&1 | tee -a $log_file
            echo "++ make single ROI map option selected" 2>&1 | tee -a $log_file
            : 'run script if outfile does not exist '
            outfile=final_roi_map.nii.gz
            if [ ! -f $outfile ]; then
                tcsh -c ${src_dir}/01_make_single_roi_map.tcsh 2>&1 | tee -a $log_file
            elif [ -f $outfile ]; then
                : 'if outfile does exist, check to make sure that it
                contains the correct number of ROIs | only run if the
                number of ROIs does not match the specified ROI centers |
                overwrite protection'
                roi_in=$(grep -c ".*" ${roi_dir}/00_list_of_all_roi_centers_test.txt)
                roi_out1=$(grep -n "ni_dimen" final_roi_map.niml.lt)
                roi_out2="${roi_out1:12}"
                roi_out="${roi_out2: :1}"
                if [ "$roi_in" -eq "$roi_out" ]; then
                    echo "outfile already exists | skipping subject"
                else
                    echo "++ !!! OVERWRITING EXISTING DATASET | final_roi_map.nii.gz !!!"
                    rm -rf $outfile
                    tcsh -c ${src_dir}/01_make_single_roi_map.tcsh 2>&1 | tee -a $log_file
                fi
            fi
        fi
        #==========create correlation map==========
        if [ "$nflag" ]; then
            : 'run 02_netcorr.tcsh'
            echo " " 2>&1 | tee -a $log_file
            echo "++ NetCorr option selected" 2>&1 | tee -a $log_file
            : 'run script if outdir does not exist '
            if [ ! -d NETCORR_000_INDIV ]; then
                tcsh -c ${src_dir}/02_netcorr.tcsh 2>&1 | tee -a $log_file
            elif [ -d NETCORR_000_INDIV ]; then
                : 'if outdir does exist, check to see if number of outfiles matches
                the specified number of ROI centers | only run if they do not match |
                overwrite protection'
                roi_in=$(grep -c ".*" ${roi_dir}/00_list_of_all_roi_centers_test.txt)
                roi_out=$(ls -l NETCORR_000_INDIV/WB_Z_ROI_00*.nii.gz | grep ^- | wc -l)
                if [ "$roi_in" -eq "$roi_out" ]; then
                    echo "outfiles already exist | skipping subject"
                else
                    tcsh -c ${src_dir}/02_netcorr.tcsh 2>&1 | tee -a $log_file
                fi
            fi
        fi
        
    else
        : 'terminate script if missing input files'
        echo "anat and/or epi infiles not found for $sub"
        echo "terminating script"
        exit 1
    fi
done