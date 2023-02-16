#!/bin/tcsh

# Module for group-averaged z-score connectivity maps for each ROI center
# Creates mask file containing only voxels positively correlated with ROI
# Preserves positively correlated voxels only (removes anticorrelated voxels)

# =================================================================

echo "++ Running 04_group_WB_mean_maps.tcsh to create WB group-averaged z-score maps for each ROI center"

#set the ROI number
set vname    = `cat _tmp_roiname.txt`

# Set naming for individual z-score map files to be combined
set izmaps   = _tmp_*_WB_Z_ROI_"${vname}".nii.gz

# set outfile names
set opref    = grp_wb_z
set omean    = ${opref}_0_"${vname}"_mean.nii.gz
set oposm    = ${opref}_1_"${vname}"_pos_mask.nii.gz
set opos     = ${opref}_2_"${vname}"_mean_pos.nii.gz

#==========create group-averaged z-score map==========

#calculate mean WB zmap across subjects
3dMean -prefix $omean $izmaps      

#create a mask of voxels with positive z value only
3dcalc -a $omean -prefix $oposm -expr 'ispositive(a-0)'

#calculates postive-only mean WB z map
3dcalc -a $omean -b $oposm -prefix $opos -expr 'a*b'      

exit 0