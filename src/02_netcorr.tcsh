#!/bin/tcsh

# Module to generate correlation matrix/map for set of ROIs

# Use 3dNetCorr to generate correlation matrix for set of ROIs from time series averages
# Also create WB seed-based correlation map for each ROI


# Credit to PA Taylor (NIMH, NIH)
# =================================================================

echo "++ Running 02_netcorr.tcsh"

# configuration
set vsub    = `cat subname.txt`

# define infiles
set vepi    = errts."${vsub}".anaticor+tlrc
set vanatss = anat_final."${vsub}"+tlrc

# output ROI map volume
set opref     = final_roi_map
set omap      = ${opref}.nii.gz
set olt       = ${opref}.niml.lt

set ocorr     = NETCORR

# ------------- network correlation ---------------

# Calculate Pearson correlation of average times series within each
# ROI, and the final three option lines lead to: 
# 1) also calculating the Fisher-Z transforms of those Pearson 'r's,
# 2) generating a WB (Fisher-Z transformed) correlation map of each
#    ROI average time series,
# 3) and outputting the average time series themselves in a simple
#    text file (called *.netts).
3dNetCorr                                       \
    -echo_edu                                   \
    -inset   ${vepi}                            \
    -in_rois ${omap}                            \
    -prefix  ${ocorr}                           \
    -fish_z                                     \
    -ts_wb_Z  -nifti                            \
    -ts_out

# make image of correlation matrix (Fisher-Z transform) of average ROI
# time series
fat_mat_sel.py                                  \
    -m ${ocorr}_000.netcc                       \
    -P 'FZ' --A_plotmin=-1 --B_plotmax=1        \
    --Tight_layout_on -x 10 --dpi=200           \
    -M RdYlBu_r

cd ${ocorr}*INDIV

foreach ff ( `ls WB*nii.gz` )
    set pp = `3dinfo -prefix_noext ${ff}`

    @chauffeur_afni                             \
        -ulay  ../${vanatss}                      \
        -box_focus_slices ../${vanatss}         \
        -olay  ${ff}                            \
        -thr_olay 0.3                           \
        -cbar Reds_and_Blues_Inv                \
        -func_range 1                           \
        -opacity 6                              \
        -blowup 1                               \
        -save_ftype JPEG                        \
        -prefix   "${pp}"                       \
        -pbar_saveim "${pp}_pbar.jpg"           \
        -montx 3 -monty 2                       \
        -set_xhairs OFF                         \
        -label_mode 1 -label_size 3             \
        -do_clean

end

cd ../

echo "++ 02_netcorr.tcsh DONE!"
exit 0