#!/bin/tcsh

# Module for creating group-level functional network connectivity maps
# Creates group-averaged z-score connectivity maps for each ROI center
# Creates mask file containing only voxels positively correlated with ROI
# Preserves positively correlated voxels only (removes anticorrelated voxels)

# =================================================================

echo "++ Running 05_group_connmap.tcsh to create group-level network connectivity maps for each ROI center"

# set the ROI number
set vname    = `cat _tmp_roiname.txt`

# set infile name
set ipref    = grp_wb_z
set iname    = ${ipref}_2_"${vname}"_mean_pos.nii.gz
set ianat    = MNI152_T1_2009c+tlrc

# set uncorrected and corrected p-values
set opvalunc = 0.01    #uncorrected p-value
set oathr    = 0.01     #corrected (whole volume) alpha-values
set opthr    = 0.001    #uncorrected (per voxel) p-values

# set outfile names
set opref    = grp_wb_z
set ouncf    = ${opref}_"${vname}"_unc_${opvalunc}
set ocorf    = ${opref}_"${vname}"_fwer_${oathr}

# ------------- Create uncorrected network connectivity maps ---------------
# creates uncorrected parameter statistic WB z map and cluster mask
# also provides text output of cluster report
3dClusterize                            \
    -inset ${iname}                     \
    -ithr 0                             \
    -idat 0                             \
    -NN 1                               \
    -1sided RIGHT_TAIL p=${opvalunc}    \
    -pref_map ${ouncf}_mask.nii.gz      \
    -pref_dat ${ouncf}.nii.gz           \
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

# ------------- Perform 3dClustSim to compute cluster-size threshold  ---------------
# for a given voxel-wise p-value threshold, such that the probability of anything surviving 
# the dual thresholds is at some given level (specified by the '-athr' option)

# Get ACF parameters for 3dClustSim
3dFWHMx -mask ${ouncf}_mask.nii.gz -input ${iname} > _tmp_acf_params.txt
awk 'NR==2' _tmp_acf_params.txt > _tmp_acf_params_2.txt

# extract acf parameters for input to 3dClustSim
set vacfpar     = `cat _tmp_acf_params_2.txt`
set vacf1       = $vacfpar[1]
set vacf2       = $vacfpar[2]
set vacf3       = $vacfpar[3]

echo "ACF parameters for 3dClustSim: $vacf1 $vacf2 $vacf3" 

# Run 3dClustSim to get the voxel-level cluster threshold
3dClustSim -mask ${ouncf}_mask.nii.gz -acf $vacf1 $vacf2 $vacf3 -athr ${oathr} -pthr ${opthr} -prefix ${opref}_clustsim 
awk 'NR==9' ${opref}_clustsim.NN3_bisided.1D > _tmp_clustsize.txt

set vclust      = `cat _tmp_clustsize.txt`
set vclustn     = $vclust[2]

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Corrected cluster size for alpha-level significance = $vclustn"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

# ------------- Create corrected network connectivity maps ---------------
3dClusterize                            \
    -inset ${iname}                     \
    -ithr 0                             \
    -idat 0                             \
    -NN 3                               \
    -clust_nvox ${vclustn}              \
    -1sided RIGHT_TAIL p=${opthr}       \
    -pref_map ${ocorf}_mask.nii.gz      \
    -pref_dat ${ocorf}.nii.gz           \
    -abs_table_data > ${ocorf}.txt

# ------------- QC uncorrected network connectivity maps ---------------
@chauffeur_afni                         \
        -ulay  ${ianat}                 \
        -box_focus_slices ${ianat}      \
        -olay  ${ocorf}.nii.gz          \
        -cbar Reds_and_Blues_Inv        \
        -func_range 1                   \
        -opacity 6                      \
        -blowup 1                       \
        -save_ftype JPEG                \
        -prefix ${ocorf}                \
        -montx 3 -monty 2               \
        -set_xhairs OFF                 \
        -label_mode 1 -label_size 3     \
        -do_clean

exit 0