# fmriconnmap
- Create a group-averaged functional connectivity map/mask for specified seed regions-of-interest (ROIs)
- Output files can be used for visual purposes (i.e., visualizing an ROI-based functional network) or statistical purposes (i.e., restricting statistical tests to a masked region)

## instructions
### Clone git repository 
- Fork repository to your GitHub account
- Clone repository to local machine git clone < git@github.com:<username>/afniconnmap.git >

### Data preprocessing
- Required input file is error time series (e.g., errts.*+tlrc) file from standard afni_proc.py preproccing pipeline 
- I used the afni_proc.py anaticor option (Example 9b. Resting state analysis with ANATICOR) for data preprocessing so input files have the file name <errts.${sub}.anaticor+tlrc>
- Any error time series file from afni_proc.py or FSL FEAT should work, but user will need to update driver.sh file naming
- Error time series file should be warped to standard MNI space (e.g. MNI152_T1_2009c or another template)

### Data setup
- create a subfolder for each subject in data directory
- store errts.*.anaticor+tlrc for each subject in the associated data/$sub directory
- store MNI template used in the afni_proc.py registration/warping procedure in nifti directory
- Create subject list using the following command: touch data/id_subj
- Add each subject's unique identifier to id_subj to the first column (sub01 sub02 sub03 ... sub0n)

### ROI configuration
- navigate to ROI directory
- update 00_input_keys_values.txt: a text file with two columns: 1) integer values, and 2) string labels
- there is one integer value plus string label pair for each ROI
- update 00_list_of_all_roi_centers.txt
- a list of (x,y,z) coordinates (MNI space, LPI orientation) for each of the ROIs in 00_input_keys_values.txt
- 00_setup.tcsh will create spherical ROIs using the locations specificies in the 00_list_of_all_roi_centers.txt file
- Default orientation is LPI
- Default ROI size radius is 6 mm
- Default ROI locations were derived from the CONN toolbox networks.txt and atlas.txt files <https://web.conn-toolbox.org/home>





## References
- Please cite AFNI gurus when using source code from this package <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/published/citations.html#afni-software-package>
- PA Taylor (NIMH. NIH) authored much of the source code <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/tutorials/rois_corr_vis/cat_netcorr.html>
- If using any of the default ROIs, please cite CONN toolbox: 
    - Whitfield-Gabrieli, S., & Nieto-Castanon, A. (2012). Conn: A functional connectivity toolbox for correlated and anticorrelated brain networks. Brain connectivity, 2(3), 125-141
    - Nieto-Castanon, A. (2020). Handbook of functional connectivity Magnetic Resonance Imaging methods in CONN. Boston, MA: Hilbert Press

