scriptdir = fileparts(mfilename('fullpath'));

% List of open inputs
% Imperfect Spoiling Calc.: Output directory - cfg_files
nrun = 1; % enter the number of runs here
jobfile = {fullfile(scriptdir,'invivo_spoiling_calc_job.m')};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(1, nrun);
for crun = 1:nrun
    inputs{1, crun} = {scriptdir}; % Imperfect Spoiling Calc.: Output directory - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
