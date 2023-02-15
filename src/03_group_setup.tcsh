#!/bin/tcsh

# Setup module for creating group-level connectivity maps 
# Creates tmp list of ROIs based on the specified MNI coordinates in roi/00_list_of_all_roi_centers.txt





# =================================================================

echo "++ Running 03_connmap.tcsh for setup"

# configuration files
set ilist   = 00_list_of_all_roi_centers_test.txt

# define outputs/temp files
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

    echo "${iii}" >> ${tlist}

end
exit 0