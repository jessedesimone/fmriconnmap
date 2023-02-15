#!/bin/bash

source config_directories.sh


SUB=`cat ${data_dir}/id_subj`
for sub in ${SUB[@]}
do
    echo "sub is $sub"
    cp ${data_dir}/$sub/NETCORR_000_INDIV/WB_Z_ROI_001.nii.gz ${out_dir}/_tmp_${sub}_WB_Z_ROI_001.nii.gz
done

3dMean -prefix ${out_dir}_tmp_mean_WB_Z_ROI_001.nii.gz ${out_dir}/_tmp_*_WB_Z_ROI_001.nii.gz       #calculates mean WB zmap across subjects
#creates a mask of voxels with positive z value only
3dcalc                                                          \
    -a ${out_dir}/_tmp_mean_WB_Z_ROI_001.nii.gz                 \
    -prefix ${out_dir}/_tmp_mean_pos_mask_WB_Z_ROI_001.nii.gz   \ 
    -expr 'ispositive(a-0)'

#calculates postive-only mean WB z map
3dcalc 
    -a ${out_dir}/_tmp_mean_WB_Z_ROI_001.nii.gz 
    -b ${out_dir}/_tmp_mean_pos_mask_WB_Z_ROI_001.nii.gz 
    -prefix ${out_dir}/_tmp_mean_pos_WB_Z_ROI_001.nii.gz 
    -expr 'a*b'      

# creates uncorrected parameter statistic WB z map and cluster mask
# also provides text output of cluster report
3dClusterize > ${out_dir}/WB_Z_ROI_001_thr001_unc.txt           \
    -inset ${out_dir}/_tmp_mean_pos_WB_Z_ROI_001.nii.gz              \
    -ithr 0                                                     \
    -idat 0                                                     \
    -NN 1                                                       \
    -1sided RIGHT_TAIL p=0.001                                  \
    -pref_map ${out_dir}/WB_Z_ROI_001_thr001_unc_clust_mask.nii.gz    \
    -pref_dat ${out_dir}/WB_Z_ROI_001_thr001_unc.nii.gz

# creates a binary mask file of the uncorrected WB z map
3dcalc 
    -a ${out_dir}/WB_Z_ROI_001_thr001_unc_clust_mask.nii.gz     \
    -prefix ${out_dir}/WB_Z_ROI_001_thr001_unc_mask.nii.gz      \
    -expr 'step(a)'

# clean up temp files
rm -rf ${out_dir}/_tmp*



