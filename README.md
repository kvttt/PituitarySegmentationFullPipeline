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

Different from `antsJointLabelFusion.sh`
----------------------------------------
- Additional (optional) pre-processing integrated into the pipeline.
- Option to use `SyNQuick` for faster registration.
- Does not contain Joint Label Fusion (JLF) step.
