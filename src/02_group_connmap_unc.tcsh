#!/bin/tcsh

# Module for creating group-level functional network connectivity maps
# Creates group-averaged z-score connectivity maps for each ROI center
# Creates mask file containing only voxels positively correlated with ROI
# Preserves positively correlated voxels only (removes anticorrelated voxels)

# =================================================================

echo "++ Running 02_group_connmap_unc.tcsh"

# set the ROI number
set vname    = `cat _tmp_roiname.txt`

# set infile name
set ipref    = grp_wb_z
set iname    = ${ipref}_2_"${vname}"_mean_pos.nii.gz
set ianat    = MNI152_T1_2009c+tlrc

# set uncorrected and corrected p-values
set opvalunc = 0.05    #uncorrected p-value

# set outfile names
set opref    = grp_wb_z
set ouncf    = ${opref}_"${vname}"_unc

# ------------- Create uncorrected network connectivity maps ---------------
# creates uncorrected parameter statistic WB z map and cluster mask
# also provides text output of cluster report
3dClusterize                                \
    -inset ${iname}                         \
    -ithr 0                                 \
    -idat 0                                 \
    -NN 1                                   \
    -1sided RIGHT_TAIL p=${opvalunc}        \
    -pref_map ${ouncf}_mask.nii.gz          \
    -pref_dat ${ouncf}.nii.gz               \
    -abs_table_data > ${ouncf}.txt


# ------------- QC uncorrected network connectivity maps ---------------
@chauffeur_afni                         \
        -ulay  ${ianat}                 \
        -box_focus_slices ${ianat}      \
        -olay  ${ouncf}.nii.gz          \
        -cbar Reds_and_Blues_Inv        \
        -func_range 1                   \
        -opacity 6                      \
        -blowup 1                       \
        -save_ftype JPEG                \
        -prefix ${ouncf}                \
        -montx 3 -monty 2               \
        -set_xhairs OFF                 \
        -label_mode 1 -label_size 3     \
        -do_clean
exit 0