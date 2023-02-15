#!/bin/bash

: 'this code will create a group-level connectivity map/mask for a single ROI
now need to run for the number of specified ROI centers

tcsh code:
#!/bin/tcsh

# Module to create group-level network connectivity maps

# =================================================================

# configuration files
set ilist   = 00_list_of_all_roi_centers_test.txt

# define outputs/temp files
set opref   = roi_mask
set tlist   = _tmp_roi_list.txt


# get dimensions of ROI coordinate list
set dims = `1d_tool.py              \
                -show_rows_cols     \
                -verb 0             \
                -infile "${ilist}"`

echo "Dimensions of ROI coordinates list: "
echo "${dims}"

foreach ii ( `seq 1 1 ${dims[1]}` )
    set iii = `printf "%03d" ${ii}`

end
exit 0


'


source config_directories.sh
source ~/env/bin/activate


SUB=`cat ${data_dir}/id_subj`
for sub in ${SUB[@]}
do
    echo "sub is $sub"
    cp ${data_dir}/$sub/NETCORR_000_INDIV/WB_Z_ROI_001.nii.gz ${out_dir}/_tmp_${sub}_WB_Z_ROI_001.nii.gz
done

# ------------- Create uncorrected network maps ---------------

#calculate mean WB zmap across subjects
3dMean -prefix ${out_dir}/_tmp_mean_WB_Z_ROI_001.nii.gz ${out_dir}/_tmp_*_WB_Z_ROI_001.nii.gz       

#create a mask of voxels with positive z value only
3dcalc -a ${out_dir}/_tmp_mean_WB_Z_ROI_001.nii.gz -prefix ${out_dir}/_tmp_mean_pos_mask_WB_Z_ROI_001.nii.gz -expr 'ispositive(a-0)'

#calculates postive-only mean WB z map
3dcalc -a ${out_dir}/_tmp_mean_WB_Z_ROI_001.nii.gz -b ${out_dir}/_tmp_mean_pos_mask_WB_Z_ROI_001.nii.gz -prefix ${out_dir}/WB_Z_ROI_001_mean_pos.nii.gz -expr 'a*b'      

# creates uncorrected parameter statistic WB z map and cluster mask
# also provides text output of cluster report
3dClusterize                                                        \
    -inset ${out_dir}/WB_Z_ROI_001_mean_pos.nii.gz                  \
    -ithr 0                                                         \
    -idat 0                                                         \
    -NN 1                                                           \
    -1sided RIGHT_TAIL p=0.001                                      \
    -pref_map ${out_dir}/WB_Z_ROI_001_thr001_unc_clust_mask.nii.gz  \
    -pref_dat ${out_dir}/WB_Z_ROI_001_thr001_unc.nii.gz

# creates a binary mask file of the uncorrected WB z map
3dcalc -a ${out_dir}/WB_Z_ROI_001_thr001_unc_clust_mask.nii.gz -prefix ${out_dir}/WB_Z_ROI_001_thr001_unc_mask.nii.gz -expr 'step(a)'

# ------------- QC uncorrected network maps ---------------
@chauffeur_afni                                                 \
        -ulay  ${out_dir}/MNI152_T1_2009c+tlrc                  \
        -box_focus_slices ${out_dir}/MNI152_T1_2009c+tlrc       \
        -olay  ${out_dir}/WB_Z_ROI_001_thr001_unc.nii.gz        \
        -cbar Reds_and_Blues_Inv                                \
        -func_range 1                                           \
        -opacity 6                                              \
        -blowup 1                                               \
        -save_ftype JPEG                                        \
        -prefix   ${out_dir}/WB_Z_ROI_001_thr001_unc            \
        -pbar_saveim ${out_dir}/"WB_Z_ROI_001_thr001_unc.jpg"   \
        -montx 3 -monty 2                                       \
        -set_xhairs OFF                                         \
        -label_mode 1 -label_size 3                             \
        -do_clean

# ------------- Create connected network maps ---------------
# Get ACF parameters for 3dClustSim
3dFWHMx -mask ${out_dir}/WB_Z_ROI_001_thr001_unc_mask.nii.gz -input ${out_dir}/WB_Z_ROI_001_mean_pos.nii.gz > ${out_dir}/WB_Z_ROI_001_acf_params.txt
awk 'NR==2' ${out_dir}/WB_Z_ROI_001_acf_params.txt > ${out_dir}/WB_Z_ROI_001_acf_params2.txt

# extract acf parameters for input to 3dClustSim
delimiter=' '
acf1="$(cut -d "$delimiter" -f 1-2 ${out_dir}/WB_Z_ROI_001_acf_params2.txt)"
acf2="$(cut -d "$delimiter" -f 3-4 ${out_dir}/WB_Z_ROI_001_acf_params2.txt)"
acf3="$(cut -d "$delimiter" -f 5-6 ${out_dir}/WB_Z_ROI_001_acf_params2.txt)"
echo "ACF parameters for 3dClustSim: $acf1 $acf2 $acf3" 

# Run 3dClustSim to get the voxel-level cluster threshold
3dClustSim -mask ${out_dir}/WB_Z_ROI_001_thr001_unc_mask.nii.gz -acf $acf1 $acf2 $acf3 -athr 0.01 -pthr 0.001 -prefix ${out_dir}/WB_Z_ROI_001_clustim
awk 'NR==9' ${out_dir}/WB_Z_ROI_001_clustim.NN3_bisided.1D > ${out_dir}/WB_Z_ROI_001_clustsize.txt
clustsize="$(cut -d "$delimiter" -f 4-5 ${out_dir}/WB_Z_ROI_001_clustsize.txt)"
echo "$clustsize"

# Repeat 3dClusterize with cluster level thresholding
3dClusterize                                                        \
    -inset ${out_dir}/WB_Z_ROI_001_mean_pos.nii.gz                  \
    -ithr 0                                                         \
    -idat 0                                                         \
    -NN 3                                                           \
    -clust_nvox $clustsize                                          \
    -1sided RIGHT_TAIL p=0.001                                      \
    -pref_map ${out_dir}/WB_Z_ROI_001_thr001_fwer_clust_mask.nii.gz  \
    -pref_dat ${out_dir}/WB_Z_ROI_001_thr001_fwer.nii.gz

# ------------- QC connected network maps ---------------
@chauffeur_afni                                                 \
        -ulay  ${out_dir}/MNI152_T1_2009c+tlrc                  \
        -box_focus_slices ${out_dir}/MNI152_T1_2009c+tlrc       \
        -olay  ${out_dir}/WB_Z_ROI_001_thr001_fwer.nii.gz        \
        -cbar Reds_and_Blues_Inv                                \
        -func_range 1                                           \
        -opacity 6                                              \
        -blowup 1                                               \
        -save_ftype JPEG                                        \
        -prefix   ${out_dir}/WB_Z_ROI_001_thr001_fwer            \
        -pbar_saveim ${out_dir}/"WB_Z_ROI_001_thr001_fwer.jpg"   \
        -montx 3 -monty 2                                       \
        -set_xhairs OFF                                         \
        -label_mode 1 -label_size 3                             \
        -do_clean

# ------------- Clean up ---------------
rm -rf ${out_dir}/_tmp*
rm -rf ${out_dir}/3dFWHMx*
rm -rf ${out_dir}/WB_Z_ROI_001_acf_params.txt