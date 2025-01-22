rootdir = fileparts(fileparts(mfilename('fullpath')));

% List of open inputs
% Segment: Volumes - cfg_files
% Segment: Volumes - cfg_files
nrun = 1; % enter the number of runs here
jobfile = {fullfile(rootdir,'scripts','segment_job.m')};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(2, nrun);
indir = fullfile(rootdir,'processed');
for crun = 1:nrun
    inputs{1, crun} = cellstr(spm_select('FPListRec',indir,'^2017.*PDw_OLSfit_TEzero\.nii')); % Segment: Volumes - cfg_files
    inputs{2, crun} = cellstr(spm_select('FPListRec',indir,'^2017.*T1w_OLSfit_TEzero\.nii')); % Segment: Volumes - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
