#!/bin/bash

# Module to prepare data for grp_corr.py

# =================================================================
echo "++ Running 03_grp_proc.tcsh"

cd $mat_out_dir

# copy required coordinate file to outdir
if [ ! -f $mat_out_dir/roi_centers.txt ]; then
    cp $ilist $mat_out_dir/roi_centers.txt
else
    rm -rf $mat_out_dir/roi_centers.txt
    cp $ilist $mat_out_dir/roi_centers.txt
fi

# create 1D file for each sub x roi condition
SUB=`cat $data_dir/id_subj`
ROI=`cat $roi_dir/roi_list.txt`
for sub in ${SUB[@]}
do
    echo "++ computing roi stats for subj $sub"
    for roi in ${ROI[@]}
    do
        echo "++ computing roi stats for ROI $roi" 2>&1 | tee -a $log_file    
        3dROIstats -quiet -mask_f2short -mask $data_dir/$sub/roi_mask_${roi}.nii.gz ${data_dir}/$sub/errts.${sub}.anaticor+tlrc > $mat_out_dir/${sub}_${roi}_roistats.1D
    done
done


# concatenate and average 1D files
for roi in ${ROI[@]}
do
    : 'concatenate the time series across subjects for each ROI
    creates single 1D file for each ROI'
    echo "++ concatenating roistats for roi $roi" 2>&1 | tee -a $log_file    
    1dcat $mat_out_dir/*_${roi}_roistats.1D > $mat_out_dir/${roi}_tcat.1D
    : 'get average time series across subjects for each ROI
    creates single 1D file with single column containing group avg'
    echo "++ averaging roistats for roi $roi" 2>&1 | tee -a $log_file    
    3dTstat -mean -prefix - $mat_out_dir/${roi}_tcat.1D > $mat_out_dir/${roi}_mean.1D
done

# create single 1D file with means for each roi
: '1D file will have a single column for each ROI
each column represents the group average time series for that ROI'
echo "++ concatenating grp means for all ROIs into single file" 2>&1 | tee -a $log_file
1dcat $mat_out_dir/*_mean.1D > grp_roi_means.txt

# python entrance
: 'create list of ROI labels for python use'
awk '{$1=""}1' ${roi_dir}/00_input_keys_values.txt | awk '{$1=$1}1' > $mat_out_dir/py_roi_labels.txt
pip3 install -r requirements.txt
python grp_corr.py

# clean up
#rm -rf $mat_out_dir/_tmp*
#rm -rf *.1D
#cd ../
#rm -rf _tmp*
