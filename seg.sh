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

if ! command -v antsRegistration &> /dev/null
then
    echo "antsRegistration command not found. Please make sure ANTs is installed and set up correctly."
    exit 1
fi

if ! command -v antsApplyTransforms &> /dev/null
then
    echo "antsApplyTransforms command not found. Please make sure ANTs is installed and set up correctly."
    exit 1
fi

if ! command -v ImageMath &> /dev/null
then
    echo "ImageMath command not found. Please make sure ANTs is installed and set up correctly."
    exit 1
fi

if ! command -v ThresholdImage &> /dev/null
then
    echo "ThresholdImage command not found. Please make sure ANTs is installed and set up correctly."
    exit 1
fi

args=()
# Path to the directory containing the atlas and mask images
atlas_dir="./atlas"
# Type of transform to use in registration
transform="SyNQuick"
# Preprocessing: skull stripping and N4 bias correction
skullstrip=true
n4=true
# Threads to use
threads=1

usage() {
    echo
    echo "Atlas-based pituitary segmentation using ANTs."
    echo
    echo "Usage: $0 <input> <output> [-a atlas_dir] [-t transform] [-s] [-n] [-m threads] [-h]"
    echo
    echo "Options:"
    echo "  <input>         Input image filename."
    echo "  <output>        Output image filename."
    echo "  -a atlas_dir    Path to the directory containing the atlas and mask images. Default: ./atlas."
    echo "  -t transform    Type of transform to use in registration. Default: SyNQuick. Currently supported: Affine, SyN, SyNQuick."
    echo "  -s              Supply this flag to SKIP skull stripping on the input image."
    echo "  -n              Supply this flag to SKIP N4 bias correction to the input image."
    echo "  -m threads      Number of threads to use. Default: 1. Increase this value to speed up the registration process."
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
    if getopts a:t:snm:h option
    then
        case $option
        in
            a) atlas_dir="$OPTARG";;
            t) transform="$OPTARG";;
            s) skullstrip=false;;
            n) n4=false;;
            m) threads="$OPTARG";;
            h) usage;;
        esac
    else
        args+=("${!OPTIND}")
        ((OPTIND++))
    fi
done

input="${args[0]}"
output="${args[1]}"
atlas_lst=("$atlas_dir"/{01..10}_t1_strip_n4.nii.gz)
mask_lst=("$atlas_dir"/{01..10}_m_resampled.nii.gz)

if [ "$transform" != "Affine" ] && [ "$transform" != "SyN" ] && [ "$transform" != "SyNQuick" ]
then
    echo "Unsupported transform type $transform. Exiting..."
    exit 1
fi

if [ "$threads" -lt 1 ]
then
    echo "Number of threads must be at least 1. Exiting..."
    exit 1
fi

echo "============================================================"
echo "Input:                        $input"
echo "Output:                       $output"
echo "Atlas directory:              $atlas_dir"
echo "Transform:                    $transform"
echo "Skull stripping:              $skullstrip"
echo "N4 bias correction:           $n4"
echo "Threads:                      $threads"
echo "============================================================"

# Skull stripping
if [ "$skullstrip" = true ]
then
    echo "Skull stripping $input..."
    time \
    mri_watershed -atlas \
                  "$input" \
                  "${input%.nii.gz}_strip.nii.gz" > /dev/null
    echo
    echo "Done skull stripping $input."
    echo "------------------------------------------------------------"
    input="${input%.nii.gz}_strip.nii.gz"
else
    echo "Skipping skull stripping..."
    echo "------------------------------------------------------------"
fi

# N4 bias correction
if [ "$n4" = true ]
then
    echo "Performing N4 bias correction on $input..."
    time \
    N4BiasFieldCorrection -d 3 \
                          -i "$input" \
                          -o "${input%.nii.gz}_n4.nii.gz" > /dev/null
    echo
    echo "Done N4 bias correction on $input."
    echo "------------------------------------------------------------"
    input="${input%.nii.gz}_n4.nii.gz"
else
    echo "Skipping N4 bias correction..."
    echo "------------------------------------------------------------"
fi

# Register the atlas to the input image
for i in {0..9}
do
    echo "Registering atlas ${atlas_lst[$i]} to the input image..."
    if [ "$transform" = "Affine" ]
    then
        echo "Performing affine registration..."
        time \
        antsRegistrationSyN.sh -d 3 \
                               -f "${input}" \
                               -m "${atlas_lst[$i]}" \
                               -o "${input%.nii.gz}_atlas_${i}_" \
                               -t a \
                               -n "$threads" > /dev/null
    elif [ "$transform" = "SyN" ]
    then
        echo "Performing SyN registration..."
        time \
        antsRegistrationSyN.sh -d 3 \
                               -f "${input}" \
                               -m "${atlas_lst[$i]}" \
                               -o "${input%.nii.gz}_atlas_${i}_" \
                               -t s \
                               -n "$threads" > /dev/null
    elif [ "$transform" = "SyNQuick" ]
    then
        echo "Performing SyNQuick registration..."
        time \
        antsRegistrationSyNQuick.sh -d 3 \
                                    -f "${input}" \
                                    -m "${atlas_lst[$i]}" \
                                    -o "${input%.nii.gz}_atlas_${i}_" \
                                    -t s \
                                    -n "$threads" > /dev/null
    else
        echo "Unsupported transform type $transform. Exiting..."
        exit 1
    fi
    echo
    echo "Done registering atlas ${atlas_lst[$i]} to the input image."
    echo "------------------------------------------------------------"

    echo "Applying transformation to the mask ${mask_lst[$i]}..."
    if [ "$transform" = "Affine" ]
    then
        time \
        antsApplyTransforms -d 3 \
                            -i "${mask_lst[$i]}" \
                            -r "${input}" \
                            -o "${input%.nii.gz}_atlas_${i}_mask.nii.gz" \
                            -n GenericLabel \
                            -t "${input%.nii.gz}_atlas_${i}_0GenericAffine.mat" > /dev/null
    elif [ "$transform" = "SyN" ] || [ "$transform" = "SyNQuick" ]
    then
        time \
        antsApplyTransforms -d 3 \
                            -i "${mask_lst[$i]}" \
                            -r "${input}" \
                            -o "${input%.nii.gz}_atlas_${i}_mask.nii.gz" \
                            -n GenericLabel \
                            -t "${input%.nii.gz}_atlas_${i}_1Warp.nii.gz" \
                            -t "${input%.nii.gz}_atlas_${i}_0GenericAffine.mat" > /dev/null
    else
        echo "Unsupported transform type $transform. Exiting..."
        exit 1
    fi
    echo
    echo "Done applying transformation to the mask ${mask_lst[$i]}."
    echo "------------------------------------------------------------"
done

# Combine the transformed masks
echo "Combining the transformed masks..."
ImageMath 3 \
          "${output%.nii.gz}_all.nii.gz" \
          + \
          "${input%.nii.gz}_atlas_0_mask.nii.gz" \
          "${input%.nii.gz}_atlas_1_mask.nii.gz" > /dev/null
for i in {2..9}
do
    ImageMath 3 \
              "${output%.nii.gz}_all.nii.gz" \
              + \
              "${output%.nii.gz}_all.nii.gz" \
              "${input%.nii.gz}_atlas_${i}_mask.nii.gz" > /dev/null
done
echo
echo "Raw segmentation saved as ${output%.nii.gz}_all.nii.gz."
echo "------------------------------------------------------------"

# Apply thresholds
for i in {1..10}
do
    echo "Applying threshold $i..."
    time \
    ThresholdImage 3 \
                   "${output%.nii.gz}_all.nii.gz" \
                   "${output%.nii.gz}_threshold_${i}.nii.gz" \
                   "$i" \
                   10000 > /dev/null
    echo
    echo "Threshold $i segmentation saved as ${output%.nii.gz}_threshold_${i}.nii.gz."
    echo "------------------------------------------------------------"
done

# Clean up
echo "Cleaning up..."
rm "${input%.nii.gz}_atlas_"*
echo "Done."
echo "------------------------------------------------------------"

exit 0
