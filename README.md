A complete pipeline for multi-atlas-based pituitary segmentation
================================================================

Dependencies
------------
- ANTs (https://github.com/ANTsX/ANTs)
- FreeSurfer (https://surfer.nmr.mgh.harvard.edu/)

Pipeline
--------
1. **Skull stripping** using FreeSurfer's `mri_watershed`.
2. **N4 bias correction** using ANTs' `N4BiasFieldCorrection`.
3. Registration of user-provided atlases to the input image using ANTs' `antsRegistration`.
4. Registered masks are combined, a threshold is optionally applied to generate a binary mask.

Usage
-----
```
Atlas-based pituitary segmentation using ANTs.

Usage: ./seg.sh <input> <output> [-a atlas_dir] [-t transform] [-s] [-n] [-m threads] [-h]

Options:
  <input>         Input image filename.
  <output>        Output image filename.
  -a atlas_dir    Path to the directory containing the atlas and mask images. Default: ./atlas.
  -t transform    Type of transform to use in registration. Default: SyNQuick. Currently supported: Affine, SyN, SyNQuick.
  -s              Supply this flag to SKIP skull stripping on the input image.
  -n              Supply this flag to SKIP N4 bias correction to the input image.
  -m threads      Number of threads to use. Default: 1. Increase this value to speed up the registration process.
  -h              Display this help message.
```

Example
-------
For this pipeline, a couple of things are required:
1. A directory `atlas_dir` (which is specified using the `-a` flag) containing the atlas and mask images.
    Currently, exactly 10 atlases and corresponding masks are required.
    They should be organized as follows:
    ```
    - atlas_dir
        - 01_t1_strip_n4.nii.gz
        - 01_m_resampled.nii.gz
        - 02_t1_strip_n4.nii.gz
        - 02_m_resampled.nii.gz
        - ...
        - 10_t1_strip_n4.nii.gz
        - 10_m_resampled.nii.gz 
    ```
2. The atlas images should be skull-stripped and N4 bias corrected.
    The script to be used for preprocessing atlases is provided in `preprocess.sh`.
    ```
    Preprocess an image for pituitary segmentation.
    
    Usage: ./preprocess.sh <input> [-h]
    
    Options:
      <input>         Input image filename.
      -h              Display this help message.
    ```
    For example, calling 
    ```
    ./preprocess.sh 01_t1.nii.gz
    ```
    will generate `01_t1_strip.nii.gz` and `01_t1_strip_n4.nii.gz`.
    One would then need to manually label the pituitary in `01_t1_strip_n4.nii.gz` and save the label as `01_m_resampled.nii.gz`.
3. Lastly, for an unprocessed image to be segmented, one would call the pipeline as follows:
    ```
    ./seg.sh input.nii.gz output.nii.gz -a atlas_dir
    ```
    The pipeline will then perform skull stripping, N4 bias correction, and atlas-based segmentation.
    The output will look like this:
    ```
    - input_strip.nii.gz
    - input_strip_n4.nii.gz
    - output_all.nii.gz
    - output_threshold_1.nii.gz
    - output_threshold_2.nii.gz
    - ...
    - output_threshold_10.nii.gz
    ```
    where `output_all.nii.gz` is the result of combining all registered masks, and `output_threshold_X.nii.gz` is the result of applying a threshold of `X` to the combined mask.
4. If the input image is already skull-stripped and N4 bias corrected, one can skip these steps by supplying the `-s` and `-n` flags, respectively.
    ```
    ./seg.sh input_strip_n4.nii.gz output.nii.gz -a atlas_dir -s -n
    ```
5. If unsatisfied with speed, one can increase the number of threads used by the pipeline.
    ```
    ./seg.sh input.nii.gz output.nii.gz -a atlas_dir -m 8
    ```

Different from `antsJointLabelFusion.sh`
----------------------------------------
- Additional (optional) pre-processing integrated into the pipeline.
- Option to use `SyNQuick` for faster registration.
- Does not contain Joint Label Fusion (JLF) step.
