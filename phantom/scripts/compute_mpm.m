rootdir = fileparts(fileparts(mfilename('fullpath')));

% List of open inputs
% Create B1 map: Output directory - cfg_files
% Create B1 map: B1 input - cfg_files
% Create B1 map: B0 input - cfg_files
% Create B1 map: Customised B1 defaults file - cfg_files
% Create B1 map: Output directory - cfg_files
% Create B1 map: B1 input - cfg_files
% Create B1 map: Customised B1 defaults file - cfg_files
% Configure toolbox: Customised - cfg_files
% Create hMRI maps: Output directory - cfg_files
% Create hMRI maps: PD images - cfg_files
% Create hMRI maps: T1 images - cfg_files
% Create hMRI maps: Output directory - cfg_files
% Create hMRI maps: PD images - cfg_files
% Create hMRI maps: T1 images - cfg_files
nrun = 1; % enter the number of runs here
jobfile = {fullfile(rootdir,'scripts','compute_mpm_job.m')};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(34, nrun);
for crun = 1:nrun
    %% B1 mapping
    inputs{1, crun} = {fullfile(rootdir,'scripts','hmri_phantom_nocleanup_defaults.m')}; % Configure toolbox: Customised - cfg_files

    indir   = fullfile(rootdir,'sub-phantom','fmap');
    outroot = fullfile(rootdir,'derived','hmri','sub-phantom','fmap');

    % seste
    outdir = fullfile(outroot,'seste');
    [~,~] = mkdir(outdir);
    inputs{2, crun} = {outdir}; % Create B1 map: Output directory - cfg_files
    inputs{3, crun} = cellstr(spm_select('FPList',indir,'_TB1EPI.nii$')); % Create B1 map: B1 input - cfg_files
    inputs{4, crun} = [cellstr(spm_select('FPList',indir,'_magnitude[12].nii$')); cellstr(spm_select('FPList',indir,'_phasediff.nii$'))]; % Create B1 map: B0 input - cfg_files
    inputs{5, crun} = {fullfile(rootdir,'scripts','hmri_b1_phantom_defaults.m')}; % Create B1 map: Customised B1 defaults file - cfg_files

    % afi
    outdir = fullfile(outroot,'afi');
    [~,~] = mkdir(outdir);
    inputs{6, crun} = {outdir}; % Create B1 map: Output directory - cfg_files
    inputs{7, crun} = cellstr(spm_select('FPList',indir,'_TB1AFI.nii$')); % Create B1 map: B1 input - cfg_files
    inputs{8, crun} = inputs{5, crun}; % Create B1 map: Customised B1 defaults file - cfg_files
    
    %% MPM
    indir   = fullfile(rootdir,'sub-phantom','anat');
    outroot = fullfile(rootdir,'derived','hmri','sub-phantom','anat');

    % sa
    inputs{9, crun} = {fullfile(rootdir,'scripts','hmri_sa_nospoilcorr_defaults.m')}; % Configure toolbox: Customised - cfg_files

    % R1 opt
    % seste
    outdir = fullfile(outroot,'seste','R1opt','sa');
    [~,~] = mkdir(outdir);
    inputs{10, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{11, crun} = cellstr(spm_select('FPList',indir,'acq-R1opt_echo-0?1_flip-1_.*_MPM.nii$')); % Create hMRI maps: PD images - cfg_files
    inputs{12, crun} = cellstr(spm_select('FPList',indir,'acq-R1opt_echo-0?1_flip-2_.*_MPM.nii$')); % Create hMRI maps: T1 images - cfg_files

    % afi
    outdir = fullfile(outroot,'afi','R1opt','sa');
    [~,~] = mkdir(outdir);
    inputs{13, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{14, crun} = inputs{11, crun}; % Create hMRI maps: PD images - cfg_files
    inputs{15, crun} = inputs{12, crun}; % Create hMRI maps: T1 images - cfg_files

    % PD opt
    % seste
    outdir = fullfile(outroot,'seste','PDopt','sa');
    [~,~] = mkdir(outdir);
    inputs{16, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{17, crun} = cellstr(spm_select('FPList',indir,'acq-PDopt_echo-0?1_flip-1_.*_MPM.nii$')); % Create hMRI maps: PD images - cfg_files
    inputs{18, crun} = cellstr(spm_select('FPList',indir,'acq-PDopt_echo-0?1_flip-2_.*_MPM.nii$')); % Create hMRI maps: T1 images - cfg_files

    % afi
    outdir = fullfile(outroot,'afi','PDopt','sa');
    [~,~] = mkdir(outdir);
    inputs{19, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{20, crun} = inputs{17, crun}; % Create hMRI maps: PD images - cfg_files
    inputs{21, crun} = inputs{18, crun}; % Create hMRI maps: T1 images - cfg_files

    % nosa
    inputs{22, crun} = {fullfile(rootdir,'scripts','hmri_nosa_nospoilcorr_defaults.m')}; % Configure toolbox: Customised - cfg_files

    % R1 opt
    % seste
    outdir = fullfile(outroot,'seste','R1opt','nosa');
    [~,~] = mkdir(outdir);
    inputs{23, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{24, crun} = inputs{11, crun}; % Create hMRI maps: PD images - cfg_files
    inputs{25, crun} = inputs{12, crun}; % Create hMRI maps: T1 images - cfg_files

    % afi
    outdir = fullfile(outroot,'afi','R1opt','nosa');
    [~,~] = mkdir(outdir);
    inputs{26, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{27, crun} = inputs{11, crun}; % Create hMRI maps: PD images - cfg_files
    inputs{28, crun} = inputs{12, crun}; % Create hMRI maps: T1 images - cfg_files

    % PD opt
    % seste
    outdir = fullfile(outroot,'seste','PDopt','nosa');
    [~,~] = mkdir(outdir);
    inputs{29, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{30, crun} = inputs{17, crun}; % Create hMRI maps: PD images - cfg_files
    inputs{31, crun} = inputs{18, crun}; % Create hMRI maps: T1 images - cfg_files

    % afi
    outdir = fullfile(outroot,'afi','PDopt','nosa');
    [~,~] = mkdir(outdir);
    inputs{32, crun} = {outdir}; % Create hMRI maps: Output directory - cfg_files
    inputs{33, crun} = inputs{17, crun}; % Create hMRI maps: PD images - cfg_files
    inputs{34, crun} = inputs{18, crun}; % Create hMRI maps: T1 images - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
