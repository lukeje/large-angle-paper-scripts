rootdir = fileparts(fileparts(mfilename('fullpath')));

% List of open inputs
% Make Directory: Parent Directory - cfg_files
% Create hMRI maps: B1 input - cfg_files
% Create hMRI maps: B0 input - cfg_files
% Create hMRI maps: PD images - cfg_files
% Create hMRI maps: T1 images - cfg_files
% Make Directory: Parent Directory - cfg_files
% Create hMRI maps: B1 input - cfg_files
% Create hMRI maps: B0 input - cfg_files
% Create hMRI maps: PD images - cfg_files
% Create hMRI maps: T1 images - cfg_files
nrun = 1; % enter the number of runs here
nses = 1;
jobfile = {fullfile(rootdir,'scripts','compute_mpm_job.m')};
jobs = repmat(jobfile, 1, nses*nrun);
inputs = cell(14, nses*nrun);
indir = fullfile(rootdir,'raw','nifti');
for sub = 1:nrun
    for ses = 1:nses
        outdir = fullfile(rootdir,'processed',sprintf('sub-%i',sub),sprintf('ses-%i',ses));
        [~,~] = mkdir(outdir);
        
        B1 = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','kp_seste_b1map_v2c_run01_0007'),'nii')); % Create B1 map: B1 input - cfg_files
        B0 = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','gre_field_mapping_2mm_lowFA_run01_????'),'nii')); % Create B1 map: B0 input - cfg_files
        assert(size(B1,1)==30)
        assert(size(B0,1)== 3)

        inputs{ 1, nses*(sub-1)+ses} = {outdir}; % Make Directory: Parent Directory - cfg_files
        inputs{ 2, nses*(sub-1)+ses} = {fullfile(rootdir,'scripts','hmri_sa_nospoilcorr_defaults.m')};
        inputs{ 3, nses*(sub-1)+ses} = B1; % Create hMRI maps: B1 input - cfg_files
        inputs{ 4, nses*(sub-1)+ses} = B0; % Create hMRI maps: B0 input - cfg_files
        inputs{ 5, nses*(sub-1)+ses} = {fullfile(rootdir,'scripts','hmri_b1_7T_defaults.m')};
        inputs{ 6, nses*(sub-1)+ses} = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','pdw_kp_mtflash3d_v1g_0p3_0033'),'nii')); % Create hMRI maps: PD images - cfg_files
        inputs{ 7, nses*(sub-1)+ses} = cellstr(spm_select('FPList',spm_select('FPList',indir,'dir','t1w_kp_mtflash3d_v1g_0p3_0024'),'nii')); % Create hMRI maps: T1 images - cfg_files
        assert(size(inputs{6, nses*(sub-1)+ses},1)==12)
        assert(size(inputs{7, nses*(sub-1)+ses},1)==12)

        inputs{ 8, nses*(sub-1)+ses} = inputs{1, nses*(sub-1)+ses}; % Make Directory: Parent Directory - cfg_files
        inputs{ 9, nses*(sub-1)+ses} = {fullfile(rootdir,'scripts','hmri_nosa_nospoilcorr_defaults.m')};
        inputs{10, nses*(sub-1)+ses} = inputs{3, nses*(sub-1)+ses}; % Create hMRI maps: B1 input - cfg_files
        inputs{11, nses*(sub-1)+ses} = inputs{4, nses*(sub-1)+ses}; % Create hMRI maps: B0 input - cfg_files
        inputs{12, nses*(sub-1)+ses} = inputs{5, nses*(sub-1)+ses};
        inputs{13, nses*(sub-1)+ses} = inputs{6, nses*(sub-1)+ses}; % Create hMRI maps: PD images - cfg_files
        inputs{14, nses*(sub-1)+ses} = inputs{7, nses*(sub-1)+ses}; % Create hMRI maps: T1 images - cfg_files
    end
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
