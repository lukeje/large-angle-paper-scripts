scriptdir = fileparts(mfilename('fullpath'));

% List of open inputs
% Imperfect Spoiling Calc.: Output directory - cfg_files
nrun = 1; % enter the number of runs here
jobfile = {fullfile(scriptdir,'invivo_spoiling_calc_job.m')};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(1, nrun);
for crun = 1:nrun
    inputs{1, crun} = {scriptdir}; % Imperfect Spoiling Calc.: Output directory - cfg_files

    % gradient spoiling parameters
    amp = 26; % mT/m
    px = 400e-6; % m
    spperpx = 6*pi;
    gamma = 267.522; % rad/(ms mT)
    dur = spperpx/(px*gamma*amp);
    inputs{2, crun} = dur; % Imperfect Spoiling Calc.: Spoiler gradient duration (ms) - cfg_entry
    inputs{3, crun} = amp; % Imperfect Spoiling Calc.: Spoiler gradient amplitude (mT/m) - cfg_entry
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
