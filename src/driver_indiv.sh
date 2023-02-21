#!/bin/bash
: 'Driver to create subject-level functional connectivity maps for specified ROI coordinate centers'

head -9 ../CHANGELOG.md

gen_error_msg="\

    Usage: ./driver_indiv.sh [-s] [-r] [-n] | [-o] [-h]
    Required arguments:
    -s  run setup
    -r  run roi map
    -n  run netcorr

    Optional arguments:
    -h  help
    -o  overwrite 

    NOTES: 

    - -srn options must be run sequentially; that is, -r is dependent on -s output and -n is dependent on -r output
    - if -o option is given, will remove all files except for original input files in data directoryy
    - use -o with *extreme caution*
    - this sould only be used if you want to run package using with a clean slate

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
        echo "++ ERROR: driver.sh requires at least 1 argument"
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
log_file=${log_dir}/log_fmriconnmap_indiv.${dt}
touch $log_file
echo "Start time: $dt" 2>&1 | tee $log_file
echo "++ Creating subject-level connectivity maps" 2>&1 | tee -a $log_file

#define subjects
SUB=`cat ${data_dir}/id_subj`
echo "number of subjects in analysis" 2>&1 | tee -a $log_file
awk 'END { print NR }' ${data_dir}/id_subj 2>&1 | tee -a $log_file

#define roi coordinate files
ilist=${roi_dir}/00_list_of_all_roi_centers.txt
ilabtxt=${roi_dir}/00_input_keys_values.txt

#define anatomical file
anat_template=${nii_dir}/MNI152_T1_2009c+tlrc

#create anat mask file
if [ ! -f ${nii_dir}/anat_mask.nii ]; then
    : 'create mask if it does not already exist'
    echo "++ creating mask of anatomical template" 2>&1 | tee -a $log_file
    : 'mask the anatomical template'
    3dcalc -a ${anat_template} -expr 'step(a)' -prefix ${nii_dir}/anat_mask0.nii
    : 'find the errts input file for the first subject and resample to epi dimensions'
    firstsub=$(head -n 1 ${data_dir}/id_subj)
    3dresample -master ${data_dir}/$firstsub/errts.${firstsub}.anaticor+tlrc -rmode NN -prefix ${nii_dir}/anat_mask.nii -inset ${nii_dir}/anat_mask0.nii
    rm -rf ${nii_dir}/anat_mask0.nii
fi
anat_mask=${nii_dir}/anat_mask.nii
echo "++ output mask dataset $anat_mask"

if [ "$oflag" ]; then
    echo "++ overwrite option selected" 2>&1 | tee -a $log_file
    echo "++ cancel now while you still can ... | type > ^c"
    echo "++ pausing code for 10 seconds while you ponder this decision"
    sleep 10
    echo "++ no regerts"
    for sub in ${SUB[@]}
    do
        echo "++ !! CLEANING DATA DIRECTORY for $sub !!" 2>&1 | tee -a $log_file
        cd $data_dir/$sub
        echo `pwd`
        : 'set GLOBIGNORE for pattern matching'
        GLOBIGNORE=errts.*:anat_final.*
        rm -v -r -f *
        if [ -d $data_dir/$sub/NETCORR_000_INDIV ]; then
            rm -rf $data_dir/$sub/NETCORR_000_INDIV
        fi
        unset GLOBIGNORE
    done
    exit 0
fi

for sub in ${SUB[@]}
do
    echo " " 2>&1 | tee -a $log_file
    echo "*** SUBJECT: $sub ***" 2>&1 | tee -a $log_file

    #define infiles
    epi=errts.${sub}.anaticor+tlrc
    anat=anat_final.${sub}+tlrc

    # copy some files
    cp $ilist ${data_dir}/${sub}/00_list_of_all_roi_centers.txt
    cp $ilabtxt ${data_dir}/${sub}/00_input_keys_values.txt
    cp $anat_mask ${data_dir}/${sub}/anat_mask.nii

    echo $sub > ${data_dir}/${sub}/subname.txt

    cd $data_dir/$sub

    #==========handle options==========

    if [[ -f ${epi}.HEAD ]] && [[ -f ${anat}.HEAD ]]; then
        : 'check that infiles for subject exist, then proceed'
        #==========setup==========
        if [ "$sflag" ]; then
            : 'run 00_indiv_setup.tcsh'
            echo " " 2>&1 | tee -a $log_file
            echo "++ setup option selected" 2>&1 | tee -a $log_file
            : 'check to see if number of outfiles match number of roi centers specified
            only run script if they do not match | overwrite protection'
            roi_in=$(grep -c ".*" ${roi_dir}/00_list_of_all_roi_centers.txt)
            roi_in=$((roi_in))
            if (( $roi_in < 10)); then
                roi_out=$(ls -l roi_mask_00* | grep ^- | wc -l)
                roi_out=$((roi_out))
            elif (( $roi_in > 10)) && (( $roi_in < 100)); then
                roi_out=$(ls -l roi_mask_0* | grep ^- | wc -l)
                roi_out=$((roi_out))
            elif (( $roi_in > 100)); then
                roi_out=$(ls -l roi_mask_* | grep ^- | wc -l)
                roi_out=$((roi_out))
            fi

            if [ "$roi_in" -eq "$roi_out" ]; then
                echo "outfiles already exist | skipping subject"
            else
                tcsh -c ${src_dir}/00_indiv_setup.tcsh 2>&1 | tee -a $log_file
            fi
        fi
        #==========create ROI map==========
        if [ "$rflag" ]; then
            : 'run 01_indiv_roi_map.tcsh'
            echo " " 2>&1 | tee -a $log_file
            echo "++ single ROI map option selected" 2>&1 | tee -a $log_file
            : 'run script if outfile does not exist '
            outfile=final_roi_map.nii.gz
            if [ ! -f $outfile ]; then
                tcsh -c ${src_dir}/01_indiv_roi_map.tcsh 2>&1 | tee -a $log_file
            else
                : 'if outfile does exist, check to make sure that it
                contains the correct number of ROIs | only run if the
                number of ROIs does not match the specified ROI centers |
                overwrite protection'
                roi_in=$(grep -c ".*" ${roi_dir}/00_list_of_all_roi_centers.txt)
                echo "++ number of ROIs = $roi_in" 2>&1 | tee -a $log_file
                roi_in=$((roi_in))

                if (( $roi_in < 10)); then
                    roi_out1=$(grep -n "ni_dimen" final_roi_map.niml.lt)
                    roi_out2="${roi_out1:12}"
                    roi_out="${roi_out2: :1}"
                elif (( $roi_in > 10)) && (( $roi_in < 100)); then
                    roi_out1=$(grep -n "ni_dimen" final_roi_map.niml.lt)
                    roi_out2="${roi_out1:12}"
                    roi_out="${roi_out2: :2}"
                elif (( $roi_in > 100)); then
                    roi_out1=$(grep -n "ni_dimen" final_roi_map.niml.lt)
                    roi_out2="${roi_out1:12}"
                    roi_out="${roi_out2: :3}"
                fi

                if [ "$roi_in" -eq "$roi_out" ]; then
                    echo "outfiles already exists | skipping subject"
                else
                    echo "++ !!! OVERWRITING EXISTING DATASET | final_roi_map.nii.gz !!!"
                    rm -rf $outfile
                    tcsh -c ${src_dir}/01_indiv_roi_map.tcsh 2>&1 | tee -a $log_file
                fi
            fi
        fi
        
        #==========create correlation map==========
        if [ "$nflag" ]; then
            : 'run 02_indiv_netcorr.tcsh'
            echo " " 2>&1 | tee -a $log_file
            echo "++ NetCorr option selected" 2>&1 | tee -a $log_file
            : 'run script if outdir does not exist '
            if [ ! -d NETCORR_000_INDIV ]; then
                tcsh -c ${src_dir}/02_indiv_netcorr.tcsh 2>&1 | tee -a $log_file
            elif [ -d NETCORR_000_INDIV ]; then
                : 'if outdir does exist, check to see if number of outfiles matches
                the specified number of ROI centers | only run if they do not match |
                overwrite protection'
                roi_in=$(grep -c ".*" ${roi_dir}/00_list_of_all_roi_centers.txt)
                roi_out=$(ls -l NETCORR_000_INDIV/WB_Z_ROI_00*.nii.gz | grep ^- | wc -l)
                if [ "$roi_in" -eq "$roi_out" ]; then
                    echo "outfiles already exist | skipping subject"
                else
                    tcsh -c ${src_dir}/02_indiv_netcorr.tcsh 2>&1 | tee -a $log_file
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