#!/bin/tcsh

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
set opref    = grp_wb_z


 Get ACF parameters for 3dClustSim
3dFWHMx -mask ${ouncf}_mask.nii.gz -input ${iname} > _tmp_acf_params.txt
awk 'NR==2' _tmp_acf_params.txt > _tmp_acf_params_2.txt

# extract acf parameters for input to 3dClustSim
set vacfpar     = `cat _tmp_acf_params_2.txt`
set vacf1       = $vacfpar[1]
set vacf2       = $vacfpar[2]
set vacf3       = $vacfpar[3]

echo "ACF parameters for 3dClustSim: $vacf1 $vacf2 $vacf3" 

#3dClustSim -mask ${ouncf}_mask.nii.gz -acf $vacf1 $vacf2 $vacf3 -athr ${oathr} -pthr ${opthr} -prefix ${opref}_clustsim
#awk 'NR==9' ${opref}_clustsim.NN3_bisided.1D > _tmp_clustsize.txt

set vclust     = `cat _tmp_clustsize.txt`
set vclustn    = $vclust[2]
echo $vclustn


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Corrected cluster size for alpha-level significance = $vclustn"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

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


