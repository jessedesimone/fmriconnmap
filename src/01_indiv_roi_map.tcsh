#!/bin/tcsh

# Module to create a single ROI map

# Combine a bunch of ROI masks (volumetric ones in separate, 3D vols) into a single *map* of ROIs, where each one is comprised of voxels
# of a constant integer value: first ROI file in list gets 1s, next ROI file gets 2s, etc.  
# Each ROI will also get a string value - based on the input in roi/00_input_keys_values.txt
# roi/00_input_keys_values.txt should have a list of string values to match the ROI integer 'keys'

# Credit to PA Taylor (NIMH, NIH)
# =================================================================

echo "++ Running 01_indiv_roi_map.tcsh"

# configuration
set vsub    = `cat subname.txt`

#define infiles
set vepi    = errts."${vsub}".anaticor+tlrc
set vanatss = anat_final."${vsub}"+tlrc

# List of initial N ROI files to be combined. Each dset here should be
# a binary mask, with voxel values only 0 or 1
set irois    = `\ls roi_mask*gz`

# File of label+key values. Here, for N ROIs, the "keys" are integers,
# 1..N.  The order of labels should match the order of listing ${irois}
set ilabtxt  = 00_input_keys_values.txt

# ---------- output and supplementary files: made here ----------

# output ROI map volume
set opref     = final_roi_map
set omap      = ${opref}.nii.gz
set olt       = ${opref}.niml.lt

# temp files: made, then cleaned
set tpref    = _tmp
set tsum     = ${tpref}_0_roi_sum.nii.gz
set tcat     = ${tpref}_1_roi_cat.nii.gz

# Add up all ROI masks.  This has two purposes:
# 1) We will check this for overlaps of ROIs (which would likely be bad).
# 2) We will use this as a mask in combining the ROIs
3dMean                           \
    -sum                         \
    -prefix "${tsum}"            \
    ${irois}

# ------------- Check if there is ROI overlap --------------------

# is max($tsum) > 1? 
set sum_max = `3dinfo -dmax "${tsum}"`

if ( ${sum_max} > 1 ) then
    echo "** ERROR! overlapping ROI masks."
    exit 1
else    
    echo "++ OK: ROI masks don't appear to overlap"
endif

# ------------- Glue to 4D dset --------------------

# concatenate in order of 'ls'
3dTcat                       \
    -prefix ${tcat}          \
    ${irois}

# ------------- Make 3D ROI map --------------------

# Give each ROI a different integer: the ROI voxels in [0]th brick
# each get a value of 1, and, generally, those in the [i]th brick get
# get a value of i+1.
3dTstat                      \
    -argmax1                 \
    -mask   ${tsum}          \
    -prefix ${omap}          \
    ${tcat}

# ------------- Attach labeltable --------------------

# Provide a list of key values (i.e., the integer of each ROI) and
# each (string) label to attach.  We specify which column is which in
# the file, and ... that's about it:
@MakeLabelTable                  \
    -lab_file   ${ilabtxt} 1 0   \
    -labeltable ${olt}           \
    -dset       ${omap}

# ------------- Make QC images --------------------
@chauffeur_afni                             \
    -ulay  ${vanatss}                       \
    -olay  ${omap}                          \
    -box_focus_slices ${vanatss}            \
    -cbar ROI_i32                           \
    -func_range 32                          \
    -pbar_posonly                           \
    -opacity 9                              \
    -blowup 1                               \
    -save_ftype JPEG                        \
    -prefix   "${opref}"                    \
    -montx 6 -monty 3                       \
    -set_xhairs OFF                         \
    -label_mode 1 -label_size 3             \
    -do_clean

# ------------------ clean up --------------------------

\rm ${tpref}*

echo "++ 01_indiv_roi_map.tcsh DONE!"
exit 0