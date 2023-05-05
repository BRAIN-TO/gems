# Miscellaneous scripts
Repository for scripts that are too small for their own repo, but useful enough for sharing.

## bto_dualecho_fieldmap.sh
Example:
``` bash
bto_dualecho_fieldmap.sh --mag1=sub-01_ses-01_acq-GRE_run-1_echo-1_part-mag_T2starw.nii.gz --mag2=sub-01_ses-01_acq-GRE_run-1_echo-2_part-mag_T2starw.nii.gz --phs1=sub-01_ses-01_acq-GRE_run-1_echo-1_part-phase_T2starw.nii.gz --phs2=sub-01_ses-01_acq-GRE_run-1_echo-2_part-phase_T2starw.nii.gz --out=sub-01_ses-01_acq-GRE_run-1_Fieldmap_in_Radians.nii.gz
```

## bto_dualecho_fieldmap_fsl.sh
Same script as bto_dualecho_fieldmap.sh except using [bet](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/BET/UserGuide) instead of [mri_synthstrip](https://surfer.nmr.mgh.harvard.edu/docs/synthstrip/) to get the brain mask so that all steps are adapted from FSL tools.
Example:
``` bash
bto_dualecho_fieldmap_fsl.sh --mag1=sub-01_ses-01_acq-GRE_run-1_echo-1_part-mag_T2starw.nii.gz --mag2=sub-01_ses-01_acq-GRE_run-1_echo-2_part-mag_T2starw.nii.gz --phs1=sub-01_ses-01_acq-GRE_run-1_echo-1_part-phase_T2starw.nii.gz --phs2=sub-01_ses-01_acq-GRE_run-1_echo-2_part-phase_T2starw.nii.gz --out=sub-01_ses-01_acq-GRE_run-1_Fieldmap_in_Radians.nii.gz
```
