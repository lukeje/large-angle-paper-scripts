scriptdir = fileparts(mfilename('fullpath'));

% List of open inputs
% Imperfect Spoiling Calc.: Output directory - cfg_files
jobs = {fullfile(scriptdir,'postmortem_spoiling_calc_job.m'),...
    fullfile(scriptdir,'postmortem_spoiling_calc_saapprox_job.m')};

nrun = length(jobfile); % enter the number of runs here
inputs = cell(3, nrun);
for crun = 1:nrun
    inputs{1, crun} = {scriptdir}; % Imperfect Spoiling Calc.: Output directory - cfg_files

    % gradient spoiling parameters
    amp = 0.9*42; % mT/m; 90% of fast gradient mode amplitude
    px = 300e-6; % m
    spperpx = 6*pi;
    gamma = 267.522; % rad/(ms mT)
    dur = spperpx/(px*gamma*amp);
    inputs{2, crun} = dur; % Imperfect Spoiling Calc.: Spoiler gradient duration (ms) - cfg_entry
    inputs{3, crun} = amp; % Imperfect Spoiling Calc.: Spoiler gradient amplitude (mT/m) - cfg_entry
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
