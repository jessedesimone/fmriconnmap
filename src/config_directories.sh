#!/bin/bash
: 'configure directories for data processing stage'
top=/Users/jessedesimone/DeSimone_Github                #parent directory
pkg_dir=${top}/fmriconnmap                              #package directory
data_dir=${pkg_dir}/data                                #data directory
src_dir=${code_dir}/src                                 #source code directory
log_dir=${top}/logs; mkdir -p $log_dir                  #log directory


