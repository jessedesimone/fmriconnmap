# fmriconnmap

<img src="images/default_mode_full_view.jpg" alt="Alt text" title="Optional title">

## Functions
### Function 1 - Create subject-level seed-based functional connectivity maps
- Create individual subject-level functional connectivity z-score maps/masks for a specified list of ROI coordinate centers
- These files can later be used for second-level (group-wise) analyses (e.g., ttest, anova, etc.)

### Function 2 - Create an group-level seed-based connectivity map/mask using subject-level z-score maps 
- Create group functional connectivity maps/masks using the average of the z-score individual subject-level z-score maps
- This can be used for visual purposes (i.e., QC the functional network associated with a given ROI) or statistical purposes (i.e., restricting statistical tests to a masked region)
- This feature creates a FWER-corrected group-level map/mask based on the cluster-size threshold for a given voxel-wise p-value (0.001) and alpha-level threshold (0.01); see 3dClustSim in AFNI for more details.

## Subject-level instructions
### Clone git repository & configure directories
- Fork repository to your GitHub account and clone repository to local machine git clone < git@github.com:*username*/afniconnmap.git >
- Navigate to src and open config_directories.sh
- Update the paths to your package; you should really only need to update the top directory (i.e., location where you downloaded the fmriconnmap package)

### Configure python virtual environment
- This package includes python source code from afni 
- matplotlib package is required for 02_indiv_netcorr.tcsh
- For me, the terminal command is: > source env/bin/activate but yours may differ
- This is built into the driver.sh script configuration so update as needed; If getting an error, try uncommenting this line of code in the driver
- The dependencies.sh script will check that matplotlib is installed and will exit if not

### Data preprocessing
- Required input file is error time series (e.g., errts.*+tlrc) file from standard afni_proc.py preproccing pipeline 
- I used the afni_proc.py anaticor option (Example 9b. Resting state analysis with ANATICOR) for data preprocessing so input files have the file name "errts.*subj*.anaticor+tlrc"
- Any error time series file from afni_proc.py or FSL FEAT should work, but user will need to update the scripts within this package with the correct file naming
- Error time series file should be aligned to standard MNI space (I used the MNI152_T1_2009c template)

### Data setup
- In the data directory, create a subdirectory for each subject 
- For each subject add errts.*.anaticor+tlrc (epi error time series) and standard space anatomical image to the respective subdirectory
- The anatomical file will be used for QC purposes
- Store MNI template used in the afni_proc.py registration/warping procedure in nifti directory; this will be used for QC purposes during the group-stage
- Create subject list using the following command: > touch data/id_subj
- Add each subject's unique identifier to the first column of id_subj

### ROI configuration
- Navigate to ROI directory
- Update 00_input_keys_values.txt: a text file with two columns: 1) integer values, and 2) string labels; there is one integer value plus string label pair for each ROI
- Update 00_list_of_all_roi_centers.txt; a list of (x,y,z) coordinates (MNI space, LPI orientation) for each of the ROIs in 00_input_keys_values.txt
- 00_indiv_setup.tcsh will create spherical ROIs using the locations specificied in the 00_list_of_all_roi_centers.txt file
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
- Navigate to data/*subj* directories
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
    - data/*subj*/NETCORR_000_INDIV/: sub-directory that holds the whole brain correlation maps of each ROI’s average time series; there are also images of those volumes stored there.
    - NETCORR_000.netcc: matrices of properties of the network of ROIs: Pearson correlation coefficient (CC) and its Fisher-Z transform (FZ)
    - NETCORR_000_netcc_FZ.jpg: an image of the Fisher-Z transform (FZ) matrix
    - NETCORR_000.netts: text file containing the mean time series of each ROI
    - NETCORR_000.roidat: text file containing info of “how full” each ROI is– basically, a way to check if masking or other processing steps might have left null time series in any ROI mask.
    - wb_z_*roi*.*view*.jpg: sets of images of the WB correlation maps of each ROI. Each ROI has 3 images (axi, cor and sag viewplanes), and there is also a “*_pbar.jpg” file of the colorbar used, and “*_pbar.txt” file that records the colorbar min, max and (optional) threshold value used.

## Group-level instructions

### Update ROI coordinate file in diver_group.sh
- driver_group.sh will use the dimensions from the roi/00_list_of_all_roi_centers.txt to determine the number of group-level maps to create
- This needs to be the very same file that you used to create the individual maps, or else the group-level map numbers will not correspond to the subject-level map numbers

### Specify uncorrected and corrected p-values in 02_group_connmap.tcsh
- These values will be used for statistical and cluster level thresholding; see 3dClustSim AFNI page for information on athr and pthr
    - set opvalunc (uncorrected p-value); default = 0.05
    - set oathr (corrected alpha-level threshold); default = 0.05
    - set opthr (uncorrected per voxel p-values); default = 0.005

### Run 00_group_setup.tcsh and 01_group_WB_mean_maps.tcsh
- This will create an output directory and subdirectory for each ROI coordinate center used in the individual processing
- Navigate to the src directory
- Type > ./driver_group.sh -sm
- Option to specify the name of the output subdirectory > ./driver_group.sh -smo < output subdirectory >
- If running options sequentially, make sure you are specifying the same output directory
- If -o is not specified, results will be stored in directory with name "output"
- Output files (for each ROI coordinate center):
    - grp_wb_z_0_001_mean.nii.gz: group-averaged z-score map
    - grp_wb_z_1_001_pos_mask.nii.gz: binary mask file of voxels with positive z-score values
    - grp_wb_z_2_001_mean_pos.nii.gz: group-averaged z-score map with only positive voxels retains (removes anticorrelated voxels)
- Type > ./driver_group.sh -h for help

### Run 00_group_connmap.tcsh
- This will create a FWER-corrected group-level map/mask based on the cluster-size threshold for the voxel-wise p-value and alpha-level threshold specified above
- This will also create a series of jpeg images for QC purposes
- Navigate to the src directory
- Type > ./driver_group.sh -c
- Option to run sequentially with [-s] and [-m] arguments > ./driver_group.sh -smc
- If running options sequentially, make sure you are specifying the same output directory
- Output files (for each ROI coordinate center):
    - grp_wb_z_*roi*_unc.*view*.jpg: axial, sagital, and coronal images of the uncorrected group-level connectivity maps
    - grp_wb_z_*roi*_unc.txt: cluster report for uncorrected group-level connectivity map
    - grp_wb_z_*roi*_unc.nii.gz: group-level connectivity map (uncorrected)
    - grp_wb_z_*roi*_unc_mask.nii.gz: binary mask of group-level connectivity map
    - grp_wb_z_clustsim.NN*n*_*n*sided.1D: cluster-size threshold for specified -athr and -pthr
    - grp_wb_z_*roi*_fwer.*view*.jpg: axial, sagital, and coronal images of the fwer-corrected group-level connectivity maps
    - grp_wb_z_*roi*_fwer.txt: cluster report for fwer-corrected group-level connectivity map
    - grp_wb_z_001_fwer.nii.gz: group-level connectivity map (fwer-corrected)
    - grp_wb_z_*roi*_fwer_mask.nii.gz: binary mask file of group-level connectivity map (fwer-corrected)

### QC 
- Naviagate to output/*roi* directories
- Review grp_wb_z_*roi*_fwer.*view* jpeg files to confirm expected network-level connectivity for each of the ROI coordinate centers

## References
- Please cite AFNI gurus when using source code from this package <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/published/citations.html#afni-software-package>
- PA Taylor (NIMH. NIH) authored much of the source code <https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/tutorials/rois_corr_vis/cat_netcorr.html>
- Default ROI locations were derived from the CONN toolbox networks.txt and atlas.txt files <https://web.conn-toolbox.org/home>; if using any of the default ROIs, please cite CONN toolbox: 
    - Whitfield-Gabrieli, S., & Nieto-Castanon, A. (2012). Conn: A functional connectivity toolbox for correlated and anticorrelated brain networks. Brain connectivity, 2(3), 125-141
    - Nieto-Castanon, A. (2020). Handbook of functional connectivity Magnetic Resonance Imaging methods in CONN. Boston, MA: Hilbert Press