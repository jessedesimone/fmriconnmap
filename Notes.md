## todo

### create group-averaged connectivity map
1. 3dmean on individual correlation maps - average z-score whole brain (3dMean -prefix ${out_dir}/mean_WB_Z_ROI_001.nii.gz ${out_dir}/_tmp_*_WB_Z_ROI_001.nii.gz)
2. 3dcalc to only retain positive voxels



3dcalc to only retain voxels with a average z-score greater than 0.3 (this is the positive correlation mask - uncorrected)
3dcalc with 3dMean outout and above 3dcalc output a*b (this is the masked z-score correlation map with actual values -uncorrected) - or you can do 3dNetCorr again by applying the above mask


clusterized thresholding
3dFWHMx -mask <mask from 3dcalc> -input <average WB z-score map> -acf
3dClustSim -mask <mask from 3dcalc> -acf <acf values from above> -athr 0.05 -pthr 0.001
create cluster thresholding corrected z-score correlation map using clustsim parameters using 3dClusterize; create binary file (mask) and stats file
