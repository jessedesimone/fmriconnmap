#!/bin/bash
: 'configure directories for data processing stage'
top=/Users/jessedesimone/DeSimone_Github                #parent directory
pkg_dir=${top}/fmriconnmap                              #package directory
data_dir=${pkg_dir}/data                                #data directory
src_dir=${pkg_dir}/src                                  #source code directory
log_dir=${pkg_dir}/logs; mkdir -p $log_dir              #log directory
roi_dir=${pkg_dir}/roi                                  #roi directory
nii_dir=${pkg_dir}/nifti                                #nifti directory
out_dir=${pkg_dir}/output                               #output directory


