# Scripts for the paper *Analytical dual flip angle R1 calculation outside the small angle regime*

## Installation
The repository can be cloned using
```bash
git clone --recurse-submodules https://github.com/lukeje/large-angle-paper-scripts.git
```
or the equivalent `ssh` expression.

To run the matlab (SPM) scripts, the hMRI toolbox version provided in the `scripts/external` folder needs to be [installed in SPM](https://github.com/hMRI-group/hMRI-toolbox/wiki/GetStarted#install-the-toolbox).
The relevant paths are then added if the SPM folder is added to the path and `spm fmri` is run from the command line.

To run the julia scripts, the environment first needs to be prepared by running
```julia
using Pkg
Pkg.activate("scripts")
Pkg.instantiate()
```
in a julia terminal in order to install all the relevant packages.

## Requirements
- matlab
- SPM
- julia

## Data
For reasons of data protection the data used in the study cannot be distributed along with the scripts.
However it is hoped that these scripts may be helpful for people trying to do similar analyses and to help clarify any potential ambiguities in the description of the methods in the paper.
