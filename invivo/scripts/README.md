# In vivo scripts

## Requirements
The scripts use Matlab and SPM12, along with the hMRI toolbox. The appropriate hMRI toolbox version can be found in `../scripts/external/hMRI-toolbox`

## How to run
Open Matlab, and then run
```matlab
% add SPM12 with hMRI toolbox installed to path

% navigate to invivo/scripts

% run all steps
compute_maps;
register;
segment;
compute_exact;
```