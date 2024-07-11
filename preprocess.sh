#!/bin/bash

if ! command -v mri_watershed &> /dev/null
then
    echo "mri_watershed command not found. Please make sure FreeSurfer is installed and set up correctly."
    exit 1
fi

if ! command -v N4BiasFieldCorrection &> /dev/null
then
    echo "N4BiasFieldCorrection command not found. Please make sure ANTs is installed and set up correctly."
    exit 1
fi

args=()
# Threads to use
threads=1

usage() {
    echo
    echo "Preprocess an image for pituitary segmentation."
    echo
    echo "Usage: $0 <input> [-h]"
    echo
    echo "Options:"
    echo "  <input>         Input image filename."
    echo "  -h              Display this help message."
    echo
    echo "------------------------------------------------------------"
    echo "Script written by:"
    echo "------------------------------------------------------------"
    echo "Kaibo Tang"
    echo "Department of Radiology and Biomedical Research Imaging Center (BRIC)"
    echo "University of North Carolina at Chapel Hill"
    echo "Contact: ktang@unc.edu"
    echo "------------------------------------------------------------"
    echo
    exit 0
}

if [ "$#" -lt 2 ]
then
    usage
fi

while [ $OPTIND -le "$#" ]
do
    if getopts h option
    then
        case $option
        in
            h) usage;;
        esac
    else
        args+=("${!OPTIND}")
        ((OPTIND++))
    fi
done

input="${args[0]}"

if [ ! -f "$input" ]
then
    echo "Input file $input not found. Exiting..."
    exit 1
fi

if [ "$threads" -lt 1 ]
then
    echo "Number of threads must be at least 1. Exiting..."
    exit 1
fi

echo "============================================================"
echo "Input:                        $input"
echo "============================================================"

# Skull stripping
echo "Skull stripping $input..."
time mri_watershed -atlas "$input" "${input%.nii.gz}_strip.nii.gz" > /dev/null
echo
echo "Done skull stripping $input."
echo "------------------------------------------------------------"
input="${input%.nii.gz}_strip.nii.gz"

# N4 bias field correction
echo "Applying N4 bias correction to $input..."
time N4BiasFieldCorrection -d 3 -i "$input" -o "${input%.nii.gz}_n4.nii.gz" > /dev/null
echo
echo "Done N4 bias correction on $input."
echo "------------------------------------------------------------"



