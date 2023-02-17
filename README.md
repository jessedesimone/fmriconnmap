# fmriconnmap
- This package has two primary functions:
### Function 1
- Create individual subject-level functional connectivity z-score maps/masks for a specified list of ROI coordinate centers
- These files can later be used for second-level group analyses on the associated parameter statistic maps
## Function 2
- Create group functional connectivity maps/masks using the average of the z-score individual subject-level z-score maps
- This can be used for visual purposes or statistical purposes (i.e., restricting statistical tests to a masked region wher you are most likely to find effects)
- This feature creates an uncorrected map/mask thresholded at 0.01 and uses 3dClustSim to compute a cluster-size threshold for a given voxel-wise p-value threshold (0.001) and alpha-level threshold of fwer=0.01

## Subject-level instructions
### Clone git repository 
- Fork repository to your GitHub account and clone repository to local machine git clone < git@github.com:*username*/afniconnmap.git >

### Configure python virtual environment
- This package includes python source code from afni 
- matplotlib package is required for 02_indiv_netcorr.tcsh
- For me, the terminal command is: > source env/bin/activate but yours may differ
- This is built into the driver.sh script configuration so update as needed
- The dependencies.sh script will check that matplotlib is installed and will exit if not

### Data preprocessing
- Required input file is error time series (e.g., errts.*+tlrc) file from standard afni_proc.py preproccing pipeline 
- I used the afni_proc.py anaticor option (Example 9b. Resting state analysis with ANATICOR) for data preprocessing so input files have the file name "errts.${sub}.anaticor+tlrc"
- Any error time series file from afni_proc.py or FSL FEAT should work, but user will need to update the scripts within this package with the correct file naming
- Error time series file should be aligned to standard MNI space (I used the MNI152_T1_2009c template)

### Data setup
- In the data directory, create a subdirectory for each subject 
- For each subject add errts.*.anaticor+tlrc (epi error time series) and standard space anatomical image to the respective subdirectory
- The anatomical file will be used for QC purposes
- Store MNI template used in the afni_proc.py registration/warping procedure in nifti directory; this will be used for QC purposes during the group-stage
- Create subject list using the following command: > touch data/id_subj
- Add each subject's unique identifier to the first column of id_subj

### Create and configure MNI mask file
- Create a mask of the anatomical template used during data preprocessing and store in nifti directory
- I used the MNI152_T1_2009c template in afni_proc.py but yours may be different
- Navigate to the nifti directory and type: > 3dcalc -a *MNI template image* -expr 'step(a)' -prefix *mask file*
- Resample the mask file to the resolution of the epi (and the ROIs that will be created) by typing > 3dresample -master *epi file* -rmode NN -prefix *mask file resampled* -inset *mask file*
- Update the naming convention of the mask file in driver_indiv.sh the default is "MNI152_T1_2009c_mask_r.nii"
- The mask file does not need to be used in this pipeline and you can optionally remove by uncommenting the mask option in 3dNetCor (02_indiv_netcorr.tcsh); I recommend using it to avoid noise outside of brain tissue

### ROI configuration
- Navigate to ROI directory
- Update 00_input_keys_values.txt: a text file with two columns: 1) integer values, and 2) string labels; there is one integer value plus string label pair for each ROI
- Update 00_list_of_all_roi_centers.txt; a list of (x,y,z) coordinates (MNI space, LPI orientation) for each of the ROIs in 00_input_keys_values.txt
- 00_setup.tcsh will create spherical ROIs using the locations specificies in the 00_list_of_all_roi_centers.txt file
- Default orientation is LPI
- Default ROI size radius is 6 mm
- If your epi/anat files are in a different orientation, update the 3dUndump command in 00_indiv_setup.tcsh

### Run 00_indiv_setup.tcsh and 01_indiv_roi_map.tcsh
- Navigate to src directory
- Type > ./driver.sh -s 
- Type > ./driver.sh -r 
- Option to run both sequentially using > ./driver.sh -sr 
- Type > ./driver.sh -h for help

### QC final_roi_map.nii.gz and final_roi_map.niml.lt
- Navigate to data and individual subject directories
- final_roi_map.nii.gz should contain the same number of ROIs and match the associated labels in final_roi_map.niml.lt
- Confirm appropriate size of each ROIs and that the labels are in the correct anatomical locations
- Individual ROI files are labelled as roi_mask_*.nii.gz
- See images/final_roi_map.*.jpg for example of final_roi_map.nii.gz

### Run 02_indiv_netcorr.tcsh 
- Navigate to src directory
- Type > ./driver.sh -n 
- Option to run sequentially with setup and roi_map scripts > ./driver.sh -srn
- Type > ./driver.sh -h for help

### QC NetCorr output files
- Output files
    - data/$sub/NETCORR_000_INDIV/: sub-directory that holds the whole brain correlation maps of each ROI’s average time series; there are also images of those volumes stored there.
    - NETCORR_000.netcc: matrices of properties of the network of ROIs: Pearson correlation coefficient (CC) and its Fisher-Z transform (FZ)
    - NETCORR_000_netcc_FZ.jpg: an image of the Fisher-Z transform (FZ) matrix
    - NETCORR_000.netts: text file containing the mean time series of each ROI
    - NETCORR_000.roidat: text file containing info of “how full” each ROI is– basically, a way to check if masking or other processing steps might have left null time series in any ROI mask.
    - WB_Z_ROI*.jpg: sets of images of the WB correlation maps of each ROI. Each ROI has 3 images (axi, cor and sag viewplanes), and there is also a “*_pbar.jpg” file of the colorbar used, and “*_pbar.txt” file that records the colorbar min, max and (optional) threshold value used.

## Group-level instructions

### Update ROI coordinate file in diver_group.sh
- The driver will use the dimensions from the roi/00_list_of_all_roi_centers.txt to determine the number of group-level maps to create
- This needs to be the very same file that you used to create the individual maps, or else the group-level map numbers will not correspond to the subject-level map numbers
- This file is defined in the driver_group.sh and 00_group_setup.tcsh so needs to be updated in both locations

### Specify uncorrected and corrected p-values in 02_group_connmap.tcsh
- These values will be used for statistical and cluster level thresholding; see 3dClustSim AFNI page for information on athr and pthr
    - set opvalunc (uncorrected p-value); default = 0.01
    - set oathr (corrected alpha-level threshold); default = 0.01
    - set opthr (uncorrected per voxel p-values); default = 0.001

### Run driver
- Navigate to the src directory
- Type > ./driver_group.sh
- Script will create output directory and subdirectory for each ROI coordinate center used in the individual processing
- Output files:
    - grp_wb_z_0_${roi}_mean.nii.gz: wb z-score map averaged across subjects for a given ROI
    - grp_wb_z_1_${roi}_pos_mask.nii.gz: binary mask of positive-only values from wb z-score map averaged across subjects for a given ROI
    - grp_wb_z_2_${roi}_mean_pos.nii.gz: product of grp_wb_z_0_${roi}_mean.nii.gz and grp_wb_z_1_${roi}_pos_mask.nii.gz (positive WB z-score correlation map - anticorrelated voxels removed)
    - grp_wb_z_${roi}_unc_0.01.nii.gz: grp_wb_z_2_${roi}_mean_pos.nii.gz thresholded at ${opvalunc} uncorrected; default is 0.01
    - grp_wb_z_${roi}_unc_0.01_mask.nii.gz: binary mask file of grp_wb_z_${roi}_unc_0.01.nii.gz



## References
- Please cite AFNI gurus when using source code from this package <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/published/citations.html#afni-software-package>
- PA Taylor (NIMH. NIH) authored much of the source code <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/tutorials/rois_corr_vis/cat_netcorr.html>
- Default ROI locations were derived from the CONN toolbox networks.txt and atlas.txt files <https://web.conn-toolbox.org/home>; if using any of the default ROIs, please cite CONN toolbox: 
    - Whitfield-Gabrieli, S., & Nieto-Castanon, A. (2012). Conn: A functional connectivity toolbox for correlated and anticorrelated brain networks. Brain connectivity, 2(3), 125-141
    - Nieto-Castanon, A. (2020). Handbook of functional connectivity Magnetic Resonance Imaging methods in CONN. Boston, MA: Hilbert Press

