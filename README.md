# fmriconnmap
- Create a group-averaged functional connectivity map/mask for specified seed regions-of-interest (ROIs)
- Output files can be used for visual purposes (i.e., visualizing an ROI-based functional network) or statistical purposes (i.e., restricting statistical tests to a masked region)

## instructions
### Clone git repository 
- Fork repository to your GitHub account and clone repository to local machine git clone < git@github.com:<username>/afniconnmap.git >
- If running on local machine, source you python environment from the terminal
- For me, the command is: > source env/bin/activate but yours may differ

### Data preprocessing
- Required input file is error time series (e.g., errts.*+tlrc) file from standard afni_proc.py preproccing pipeline 
- I used the afni_proc.py anaticor option (Example 9b. Resting state analysis with ANATICOR) for data preprocessing so input files have the file name "errts.${sub}.anaticor+tlrc"
- Any error time series file from afni_proc.py or FSL FEAT should work, but user will need to update the scripts within this package with the correct file naming
- Error time series file should be aligned to standard MNI space (e.g. MNI152_T1_2009c or another template)

### Data setup
- In the data directory, create a subdirectory for each subject 
- For each subject add errts.*.anaticor+tlrc (epi error time series) and standard space anatomical image to the respective subdirectory
- The anatomical file will be used for QC
- Store MNI template used in the afni_proc.py registration/warping procedure in nifti directory; this is not used either, but nice to have
- Create subject list using the following command: touch data/id_subj
- Add each subject's unique identifier to the first column of id_subj

# Create and configure MNI mask file
- Create a mask of the anatomical template used during data preprocessing and store in nifti directory
- I used the MNI152_T1_2009c template in afni_proc.py but yours may be different
- Navigate to the nifti directory and type: > 3dcalc -a <MNI template image> -expr 'step(a)' -prefix <mask file>
- Resample the mask file to the resolution of the epi (and the ROIs that will be created) by typing > 3dresample -master <epi file> -rmode NN -prefix <mask file resampled> -inset <mask file>
- Update the naming convention of the mask file in driver.sh line 86
- The mask file does not need to be used in this pipeline and you can optionally remove by uncommenting the mask option in 3dNetCor (02_netcorr.tcsh)

### ROI configuration
- Navigate to ROI directory
- Update 00_input_keys_values.txt: a text file with two columns: 1) integer values, and 2) string labels; there is one integer value plus string label pair for each ROI
- Update 00_list_of_all_roi_centers.txt; a list of (x,y,z) coordinates (MNI space, LPI orientation) for each of the ROIs in 00_input_keys_values.txt
- 00_setup.tcsh will create spherical ROIs using the locations specificies in the 00_list_of_all_roi_centers.txt file
- Default orientation is LPI
- Default ROI size radius is 6 mm

### run 00_setup.tcsh and 01_make_single_roi_map.tcsh
- Navigate to src directory
- Type > ./driver.sh -s 
- Type > ./driver.sh -r 
- Option to run both concurruently using > ./driver.sh -sr 

### QC final_roi_map.nii.gz and final_roi_map.niml.lt
- final_roi_map.nii.gz should contain the same number of ROIs and match the associated labels in final_roi_map.niml.lt
- Confirm appropriate size of each ROIs and that the labels are in the correct anatomical locations
- Individual ROI files labled as roi_mask_*.nii.gz
- See final_roi_map.*.jpg for example of final_roi_map.nii.gz

### run 02netcorr.tcsh 
- Navigate to src directory
- Type > ./driver.sh -n 
- Option to run concurruently with setup and roi_map scripts < ./driver.sh -srn >

### QC NetCorr output files
- Output files
    - NETCORR_000.netcc: matrices of properties of the network of ROIs: Pearson correlation coefficient (CC) and its Fisher-Z transform (FZ)
    - NETCORR_000_netcc_FZ.jpg: an image of the Fisher-Z transform (FZ) matrix
    - NETCORR_000.netts: text file containing the mean time series of each ROI
    - NETCORR_000.roidat: text file containing info of “how full” each ROI is– basically, a way to check if masking or other processing steps might have left null time series in any ROI mask.
    - NETCORR_000_INDIV/: sub-directory that holds the whole brain correlation maps of each ROI’s average time series; there are also images of those volumes stored there.
    - WB_Z_ROI*.jpg: sets of images of the WB correlation maps of each ROI. Each ROI has 3 images (axi, cor and sag viewplanes), and there is also a “*_pbar.jpg” file of the colorbar used, and “*_pbar.txt” file that records the colorbar min, max and (optional) threshold value used.





## References
- Please cite AFNI gurus when using source code from this package <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/published/citations.html#afni-software-package>
- PA Taylor (NIMH. NIH) authored much of the source code <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/tutorials/rois_corr_vis/cat_netcorr.html>
- Default ROI locations were derived from the CONN toolbox networks.txt and atlas.txt files <https://web.conn-toolbox.org/home>; if using any of the default ROIs, please cite CONN toolbox: 
    - Whitfield-Gabrieli, S., & Nieto-Castanon, A. (2012). Conn: A functional connectivity toolbox for correlated and anticorrelated brain networks. Brain connectivity, 2(3), 125-141
    - Nieto-Castanon, A. (2020). Handbook of functional connectivity Magnetic Resonance Imaging methods in CONN. Boston, MA: Hilbert Press

