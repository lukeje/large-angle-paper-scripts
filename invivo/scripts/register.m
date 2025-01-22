rootdir = fileparts(fileparts(mfilename('fullpath')));

% List of open inputs
% Coregister: Estimate: Reference Image - cfg_files
% Coregister: Estimate: Source Image - cfg_files
inroot = fullfile(rootdir,'processed');
nsub = 6; % enter the number of runs here
jobfile = {fullfile(rootdir,'scripts','register_job.m')};
jobs = repmat(jobfile, 1, nsub);
inputs = cell(2, nsub);
for sub = 1:nsub
    % make register directory
    outdir = fullfile(inroot,sprintf('sub-%i',sub),'reg');
    [~,~] = mkdir(outdir);

    % copy PDw (T1w) data so we don't overwrite original data
    refses = 1;
    reffile = fullfile(outdir,sprintf('ses-%i_ref.nii',refses));
    indir  = fullfile(inroot,sprintf('sub-%i',sub),sprintf('ses-%i',refses),'sa');
    [~,~] = copyfile(spm_select('FPListRec',indir,'^2017.*PDw_OLSfit_TEzero\.nii'),reffile);

    movses = 2;
    movfile = fullfile(outdir,sprintf('ses-%i_mov.nii',movses));
    indir = fullfile(inroot,sprintf('sub-%i',sub),sprintf('ses-%i',movses),'sa');
    [~,~] = copyfile(spm_select('FPListRec',indir,'^2017.*PDw_OLSfit_TEzero\.nii'),movfile);

    inputs{1, sub} = {reffile}; % Coregister: Estimate: Reference Image - cfg_files
    inputs{2, sub} = {movfile}; % Coregister: Estimate: Source Image - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
