#!/bin/bash
set -e

: 'module to check dependencies'
echo -n "checking dependencies >>>>>> "
command -v afni >/dev/null 2>&1 || { echo >&2 "afni is not installed.  Aborting."; exit 1; }
echo "good"