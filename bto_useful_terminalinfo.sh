#! /bin/bash

### S Kashyap (2021-08)
echo " # ====== System Configuration ===================================== # "
echo "  CPU         : $(lscpu | grep 'Model name' | cut -f 2 -d ":" | awk '{$1=$1}1')"
echo "  OS          : $(lsb_release -sd)"
echo "  LINUX       : $(uname -r)"
echo "  NVIDIA      : $(nvidia-settings -q NvidiaDriverVersion | cut -f 4 -d ":" | sed 's/ //g' | sed -r '/^\s*$/d')"
echo "  CUDA        : $(nvcc --version | grep "release" | cut -f 2 -d "V")"
echo " # ====== Software Versions ======================================== # "
py3_ver=$(python3 -V)
echo "  Python      : ${py3_ver:7:8}"
r_ver=$(R --version | grep 'R version')
echo "  R           : ${r_ver:10:6}"

afni_ver=$(afni -ver)
echo "  AFNI        : ${afni_ver:65:8} "

export ANTSPATH=/home/sri/Data/opt/ANTs/bin
export PATH=${ANTSPATH}:$PATH
echo "  ANTs        : $(antsRegistration --version | grep "ANTs Version" | cut -f 2 -d ":" | cut -f 2 -d "v")"

export FREESURFER_HOME=/home/sri/Data/opt/freesurfer
export SUBJECTS_DIR=$FREESURFER_HOME/subjects
source $FREESURFER_HOME/SetUpFreeSurfer.sh
fs_ver=$(cat $FREESURFER_HOME/build-stamp.txt)
echo "  FreeSurfer  : ${fs_ver:33:25}"
export FSLDIR=/opt/fsl
echo "  FSL         : $(cat -v $FSLDIR/etc/fslversion)"
