#!/bin/sh
: 'Driver to create group-level functional connectivity maps for a specified list of ROI centers'

head -9 ../CHANGELOG.md

gen_error_msg="\

    Usage: ./driver_group.sh [-s] [-m] [-c] | [-o <string>] [-h]
    Required arguments (at least 1 of):
    -s      run setup
    -m      create group-averaged z-score maps (uncorrected)
    -c      create group-level connectivity map (corrected)

    Option arguments:
    -o      specify output subdirectory name
    -h      help

    Notes:
    - -smc options must be run sequentially; that is, -m is dependent on -s output and -c is dependent on -m output
    - if -o option is not specified, the results will be stored in output directory
    - if -o option is specified, the results will be stored in output/<-o string>

    "
    while getopts ":hsmco:" opt; do
        case ${opt} in
                h|\?) #help option
                    echo "$gen_error_msg"
                    exit 1
                    ;;
                s) #setup
                    sflag=1
                    ;;
                m) #mean z-score maps
                    mflag=1
                    ;;
                c) #group-level connmap
                    cflag=1
                    ;;
                o) #specify output directory name
                    oflag=${OPTARG}
                    echo "oflag is ${OPTARG}"
                    ;;
                :) #expected argument omitted:
                    echo "Error: -${OPTARG} requires an argument"
                    echo "$gen_error_msg"
                    exit 1
                    ;;
        esac
    done
    if [ $OPTIND -eq 1 ]; then 
        echo "++ driver_group.sh requires at least 1 argument"
        echo "$gen_error_msg"
        exit 1
        fi
    shift $((OPTIND -1))

#==========configuration==========
echo " "
echo "DRIVER.SH STARTED"

# set datetime
: 'used for datetime stamp log files'
dt=$(date "+%Y.%m.%d.%H.%M.%S")

# set directories
: 'call directories.sh'
source config_directories.sh
out_dir=$out_dir/$oflag

# create log file
: 'log file will capture terminal output each time driver is run
can be used to check for and troubleshoot errors'
log_file=${log_dir}/log_fmriconnmap_group.${dt}
touch $log_file
echo "start time: $dt" 2>&1 | tee $log_file
echo "++ creating group-level connectivity maps" 2>&1 | tee -a $log_file
echo "++ output directory is $out_dir" 2>&1 | tee -a $log_file

# enable extended globbing
: 'enables pattern matching'
#shopt -s extglob

# check dependencies
: 'uncomment if you need to check dependencies
code should run fine on current LRN systems'
source dependencies.sh 2>&1 | tee -a $log_file

# set the python virtual environment
: 'depends on system | may not be needed'
source ~/env/bin/activate

# define subjects
SUB=`cat ${data_dir}/id_subj`
echo "number of subjects in analysis" 2>&1 | tee -a $log_file
awk 'END { print NR }' ${data_dir}/id_subj 2>&1 | tee -a $log_file

# define roi coordinate files
ilist=${roi_dir}/00_list_of_all_roi_centers_test.txt
ilist2=${roi_dir}/00_input_keys_values_test.txt

# define anat template
anat_template=MNI152_T1_2009c+tlrc

# check if outdir exists or create
if [ -d $out_dir ]; then 
    echo "++ output directory already exists" 2>&1 | tee -a $log_file
    echo "++ consider moving to backup directory or remove" 2>&1 | tee -a $log_file
    echo "pausing code for 10 seconds while you ponder this decision" 2>&1 | tee -a $log_file
    sleep 10

else
    echo "++ creating output directory" 2>&1 | tee -a $log_file
    mkdir -p $out_dir
fi

# copy required coordinate file to outdir
if [ ! -f ${out_dir}/roi_centers.txt ]; then
    cp $ilist ${out_dir}/roi_centers.txt
else
    rm -rf ${out_dir}/roi_centers.txt
    cp $ilist ${out_dir}/roi_centers.txt
fi

# copy roi labels too to help with QC
if [ ! -f ${out_dir}/roi_labs.txt ]; then
    cp $ilist2 ${out_dir}/roi_labs.txt
else
    rm -rf ${out_dir}/roi_labs.txt
    cp $ilist2 ${out_dir}/roi_labs.txt
fi

# navigate to outdir
cd $out_dir

#==========handle options==========
#==========setup==========
# run setup if selected
if [ "$sflag" ]; then
    echo " " 2>&1 | tee -a $log_file
    echo "++ setup option selected" 2>&1 | tee -a $log_file
    tcsh -c ${src_dir}/00_group_setup.tcsh 2>&1 | tee -a $log_file
fi

# create roi directories
if [ ! -f _tmp_roi_list.txt ]; then
    echo "++ no setup file found" 2>&1 | tee -a $log_file
    echo "++ must run [-s] option first " 2>&1 | tee -a $log_file
    exit 1
else
    ROI=`cat _tmp_roi_list.txt`
    for roi in ${ROI[@]}
    do 
        mkdir -p $roi
        if [ ! -f $roi/${anat_template}.HEAD ]; then
            echo "coping anatomical template files" 2>&1 | tee -a $log_file
            3dcopy ${nii_dir}/${anat_template} $roi/
        fi
    done
fi
#==========group mean z-score maps==========
if [ "$mflag" ]; then
    echo "++ group mean option selected" 2>&1 | tee -a $log_file
    for roi in ${ROI[@]}
    do
        echo "++ creating group-averaged z-score map ROI${roi}" 2>&1 | tee -a $log_file
        echo $roi > ${roi}/_tmp_roiname.txt
        
        # copy infiles
        for sub in ${SUB[@]}
        do
            cp ${data_dir}/${sub}/NETCORR_000_INDIV/WB_Z_ROI_${roi}.nii.gz ${out_dir}/${roi}/_tmp_${sub}_wb_z_roi_${roi}.nii.gz
        done
        
        # enter roi directory
        cd $roi
        if [ -f grp_wb_z_2_${roi}_mean_pos.nii.gz ]; then
        : 'if outfile exists do not run'
            echo "++ outfile already created for ROI${roi}"
        else
            : 'run if outfile does not exist'
            tcsh -c ${src_dir}/01_group_WB_mean_maps.tcsh 2>&1 | tee -a $log_file
        fi

        cd ../
    done
fi

#==========group-level connectivity maps==========
if [ "$cflag" ]; then
    for roi in ${ROI[@]}
    do
        echo "++ creating group-averaged connmap for ROI${roi}" 2>&1 | tee -a $log_file
        cd $roi

        #create uncorrected group-level connectivity map
        if [ ! -f grp_wb_z_1_${roi}_pos_mask.nii.gz ]; then
            echo "++ no mask to create connmap" 2>&1 | tee -a $log_file
            echo "++ must run [-m] option first" 2>&1 | tee -a $log_file
        else
            if [ ! -f grp_wb_z_${roi}_fwer.nii.gz ]; then
                tcsh -c ${src_dir}/02_group_connmap.tcsh 2>&1 | tee -a $log_file
            else 
                echo "++ group-averaged connmap already exists" 2>&1 | tee -a $log_file
            fi
        fi

        # clean up
        rm -rf _tmp*
        rm -rf MNI*
        rm -rf 3dFWHMx*

        cd ../

    done
fi
# clean up
rm -rf _tmp*
exit 0





    