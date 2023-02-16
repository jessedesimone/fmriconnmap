#!/bin/tcsh

# Module for creating group-level functional network connectivity maps
# Creates group-averaged z-score connectivity maps for each ROI center
# Creates mask file containing only voxels positively correlated with ROI
# Preserves positively correlated voxels only (removes anticorrelated voxels)

# =================================================================

echo "++ Running 04_group_WB_mean_maps tcsh to create WB group-averaged z-score maps for each ROI center"

# set the ROI number
set vname    = `cat roiname.txt`

# set infile name
set ipref    = grp_wb_z
set iname    = ${ipref}_2_"${vname}"_mean_pos.nii.gz
set ianat    = MNI152_T1_2009c+tlrc

# set uncorrected and corrected p-values
opvalunc     = 0.01     #uncorrected p-value
oathr        = 0.01     #corrected (whole volume) alpha-values
opthr        = 0.001    #uncorrected (per voxel) p-values

# set outfile names
set opref    = grp_wb_z
set ouncf    = ${opref}_"${vname}"_unc_${opvalunc}
set ocorf    = ${opref}_"${vname}"_fwer_${oathr}


# ------------- Create uncorrected network maps ---------------
# creates uncorrected parameter statistic WB z map and cluster mask
# also provides text output of cluster report
3dClusterize                                                        \
    -inset ${iname}                                                 \
    -ithr 0                                                         \
    -idat 0                                                         \
    -NN 1                                                           \
    -1sided RIGHT_TAIL ${opvalunc}                                  \
    -pref_map ${opref}_"${vname}"_unc_${opvalunc}_mask.nii.gz       \
    -pref_dat ${opref}_"${vname}"_unc_${opvalunc}.nii.gz            \
    -abs_table_data > ${opref}_"${vname}"_unc_${opvalunc}.txt


# ------------- QC uncorrected network maps ---------------
@chauffeur_afni                                                 \
        -ulay  ${ianat}                                         \
        -box_focus_slices ${ianat}                              \
        -olay  ${opref}_"${vname}"_unc_${opvalunc}.nii.gz       \
        -cbar Reds_and_Blues_Inv                                \
        -func_range 1                                           \
        -opacity 6                                              \
        -blowup 1                                               \
        -save_ftype JPEG                                        \
        -prefix   ${opref}_"${vname}"_unc_${opvalunc}           \
        -montx 3 -monty 2                                       \
        -set_xhairs OFF                                         \
        -label_mode 1 -label_size 3                             \
        -do_clean
