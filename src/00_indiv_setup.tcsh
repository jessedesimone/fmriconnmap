#!/bin/tcsh

# Module to create individual ROI masks

# Script will generate a series of ROI files based on the specified MNI coordinates in roi/00_list_of_all_roi_centers.txt
# The ROI files will ultiumately be combined into a single ROI map later
# The only condition is that the ROIs *cannot* overlap spatially

# Credit to PA Taylor (NIMH, NIH)
# =================================================================

echo "++ Running 00_indiv_setup.tcsh"

# configuration files
set vsub    = `cat subname.txt`
set ilist   = 00_list_of_all_roi_centers_test.txt

# define infiles
set vepi    = errts."${vsub}".anaticor+tlrc

# define outputs/temp files
set opref   = roi_mask
set tlist   = _tmp_roi_list.txt

# =================================================================
# get dimensions of ROI coordinate list
set dims = `1d_tool.py              \
                -show_rows_cols     \
                -verb 0             \
                -infile "${ilist}"`

echo "Dimensions of ROI coordinates list: "
echo "${dims}"

# loop through ROI coordinate list
foreach ii ( `seq 1 1 ${dims[1]}` )
    set iii = `printf "%03d" ${ii}`

    # make temp list of 1 ROI center
    sed -n ${ii}p ${ilist} > ${tlist}

    # create volumetric mask of a sphere at that ROI center
    # specified as LPI values and MNI space
    # radium = 6mm
    3dUndump                              \
        -overwrite                        \
        -xyz                              \
        -orient LPI                       \
        -prefix ${opref}_${iii}.nii.gz    \
        -master ${vepi}                   \
        -datum byte                       \
        -srad 6                           \
        ${tlist}  
end

#clean up
\rm ${tlist}

echo "++ 00_indiv_setup.tcsh DONE!"
exit 0