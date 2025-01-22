% Global hmri_def variable used across the whole toolbox
global hmri_def

hmri_7T_defaults;

%--------------------------------------------------------------------------
% Decide whether to use small angle approximation when computing R1 and PD
%--------------------------------------------------------------------------
hmri_def.small_angle_approx = true;

%--------------------------------------------------------------------------
% MPM acquisition parameters and RF spoiling correction parameters
%--------------------------------------------------------------------------

% IMPERFECT RF SPOILING CORRECTION PARAMETERS 
hmri_def.imperfectSpoilCorr.enabled = false;
