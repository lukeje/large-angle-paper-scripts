% Sets the defaults for B1 bias correction, part of the hMRI toolbox.
% Consider this file as a template for local settings specifications. 
% Please read below for details.
%
% FORMAT hmri_b1_local_defaults
%__________________________________________________________________________
%
% PURPOSE
% To set user-defined (site- or protocol-specific) defaults parameters for
% B1 mapping. Applies to 3D EPI, 3D AFI and UNICORT protocols only. 
% Customized processing parameters can be defined, overwriting defaults
% from hmri_b1_standard_defaults. Acquisition parameters can be specified
% here as a fallback solution when no metadata are available. Note that the
% use of metadata is strongly recommended.  
%
% RECOMMENDATIONS
% Parameters defined in this file are identical, initially, to the ones
% defined in hMRI-Toolbox\config\hmri_b1_standard_defaults. It is
% recommended, when modifying this file, to remove all unchanged entries
% and SAVE THE MODIFIED FILE WITH A MEANINGFUL NAME. This will help you
% identifying the appropriate defaults to be used during map creation for
% B1 map calculation, and will improve the readability of the file by
% pointing to the modified parameters only. 
%
% WARNING
% Modification of the defaults parameters may impair the integrity of the
% toolbox, leading to unexpected behaviour. Only recommended for expert
% users. 
%
% HOW DOES IT WORK?
% The modified defaults file can be selected when specifying the B1 type in
% the "Create maps" branch of the hMRI-Toolbox.
%__________________________________________________________________________
% Written by E. Balteau, 2017.
% Cyclotron Research Centre, University of Liege, Belgium
%__________________________________________________________________________

% Global hmri_def variable used across the whole toolbox
global hmri_def

%--------------------------------------------------------------------------
% B1 mapping processing parameters 
%--------------------------------------------------------------------------
% Default parameters are set below for each type of B1 processing.
% For acquisition parameters, default values are a fallback solution for B1
% data processing when no metadata are available. Use of metadata is
% recommended to retrieve site- & protocol-specific parameters and ensure
% appropriate data handling and processing.
% See examples of local customization in the hMRI-Toolbox\local directory.

% 'i3D_EPI'
hmri_def.b1map.i3D_EPI.b1type = 'i3D_EPI'; 
hmri_def.b1map.i3D_EPI.b1avail = true; 
hmri_def.b1map.i3D_EPI.procreq = true; 
% b0&b1-processing
hmri_def.b1map.i3D_EPI.b1proc.T1 = 1633; % ms, 7T average of tissues from Rooney et al. (2007)
hmri_def.b1map.i3D_EPI.b1proc.eps = 0.0001;
hmri_def.b1map.i3D_EPI.b1proc.Nonominalvalues = 5;
hmri_def.b1map.i3D_EPI.b1proc.nAmbiguousAngles = 3;
hmri_def.b1map.i3D_EPI.b1proc.HZTHRESH = 250;
hmri_def.b1map.i3D_EPI.b1proc.SDTHRESH = 8;
hmri_def.b1map.i3D_EPI.b1proc.ERODEB1 = 1;
hmri_def.b1map.i3D_EPI.b1proc.PADB1 = 4;
hmri_def.b1map.i3D_EPI.b1proc.B1FWHM = 4; % For smoothing. FWHM in mm - i.e. it is divided by voxel resolution to get FWHM in voxels
% b1-validation
hmri_def.b1map.i3D_EPI.b1validation.checkTEs = false; % input validation using image TEs. Assumes SE has shorter TE than STE in metadata (qMRI-BIDS assumption). Disabled by default as this assumption is not valid for the metadata in the DICOMs from some sequences.
hmri_def.b1map.i3D_EPI.b1validation.useBidsFlipAngleField = false; % qMRI-BIDS support: read flip angles from BIDS metadata. Requires this metadata to be set appropriately!
% b1-acquisition
hmri_def.b1map.i3D_EPI.b1acq.beta = 165:-7.5:60;
hmri_def.b1map.i3D_EPI.b1acq.TM = 34.91;
hmri_def.b1map.i3D_EPI.b1acq.tert = 540e-3*24; % EchoSpacing * numberPElines
hmri_def.b1map.i3D_EPI.b1acq.blipDIR = 1;
% b0-acquisition
hmri_def.b1map.i3D_EPI.b0acq.shortTE = 10.00; % ms
hmri_def.b1map.i3D_EPI.b0acq.longTE = 11.02; % ms
hmri_def.b1map.i3D_EPI.b0acq.iformat = 'PM'; % ms
