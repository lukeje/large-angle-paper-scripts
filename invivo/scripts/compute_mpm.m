rootdir = fileparts(fileparts(mfilename('fullpath')));

% List of open inputs
% Make Directory: Parent Directory - cfg_files
% Create B1 map: B1 input - cfg_files
% Create B1 map: B0 input - cfg_files
% Image Calculator: Input Images - cfg_files
% Make Directory: Parent Directory - cfg_files
% Create hMRI maps: PD images - cfg_files
% Create hMRI maps: T1 images - cfg_files
% Make Directory: Parent Directory - cfg_files
% Create hMRI maps: PD images - cfg_files
% Create hMRI maps: T1 images - cfg_files
nrun = 6; % enter the number of runs here
jobfile = {fullfile(rootdir,'scripts','compute_mpm_job.m')};
jobs = repmat(jobfile, 1, 2*nrun);
inputs = cell(13, 2*nrun);
for sub = 1:nrun
    for ses = 1:2
        indir  = fullfile(rootdir,'raw',      sprintf('sub-%i',sub),sprintf('ses-%i',ses));
        outdir = fullfile(rootdir,'processed',sprintf('sub-%i',sub),sprintf('ses-%i',ses));
        [~,~] = mkdir(outdir);
        
        B1 = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','al_B1mapping_v2f_long_TM34910_????'))); % Create B1 map: B1 input - cfg_files
        B0 = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','gre_field_mapping_2mm_????'))); % Create B1 map: B0 input - cfg_files
        assert(size(B1,1)==30)
        assert(size(B0,1)== 3)

        PDw = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','PD_M'),'^2017'));
        T1w = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','T1_M'),'^2017'));
        assert(size(PDw,1)==8)
        assert(size(T1w,1)==8)

        % B1 map creation and registration
        inputs{ 1, 2*(sub-1)+ses} = {outdir}; % Make Directory: Parent Directory - cfg_files
        inputs{ 2, 2*(sub-1)+ses} = B1; % Create B1 map: B1 input - cfg_files
        inputs{ 3, 2*(sub-1)+ses} = B0; % Create B1 map: B0 input - cfg_files
        inputs{ 4, 2*(sub-1)+ses} = {fullfile(rootdir,'scripts','hmri_b1_7T_defaults.m')};
        inputs{ 5, 2*(sub-1)+ses} = PDw; % Image Calculator: Input Images - cfg_files
        
        % Small angle approximation
        inputs{ 6, 2*(sub-1)+ses} = {outdir}; % Make Directory: Parent Directory - cfg_files
        inputs{ 7, 2*(sub-1)+ses} = {fullfile(rootdir,'scripts','hmri_sa_nospoilcorr_defaults.m')};
        inputs{ 8, 2*(sub-1)+ses} = PDw; % Create hMRI maps: PD images - cfg_files
        inputs{ 9, 2*(sub-1)+ses} = T1w; % Create hMRI maps: T1 images - cfg_files

        % No small angle approximation
        inputs{10, 2*(sub-1)+ses} = {outdir}; % Make Directory: Parent Directory - cfg_files
        inputs{11, 2*(sub-1)+ses} = {fullfile(rootdir,'scripts','hmri_nosa_nospoilcorr_defaults.m')};
        inputs{12, 2*(sub-1)+ses} = PDw; % Create hMRI maps: PD images - cfg_files
        inputs{13, 2*(sub-1)+ses} = T1w; % Create hMRI maps: T1 images - cfg_files
    end
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
