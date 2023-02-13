#!/bin/tcsh

# Setup script
# Script will generate a series of ROI files based on the specified 
# MNI coordinates in roi/00_list_of_all_roi_centers.txt. ROI files 
# will ultimately be combined into a single ROI map. 

# The only condition on the ROIs here is that they *don't* overlap
# spatially.  While the other program can be designed with a minor
# change to deal with that situation, here we assume that overlap
# would be an unwanted thing and a sign of a mistake in processing, so
# it is in fact guarded against in the other scripts.

# =================================================================

echo "++ Running 00_setup.tcsh"

# define infiles
set vsub     = `cat subname.txt`
set ilist   = 00_list_of_all_roi_centers_test.txt
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

echo "++ 00_setup.tcsh DONE!"