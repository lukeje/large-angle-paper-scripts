rootdir = fileparts(fileparts(mfilename('fullpath')));
outdir = fullfile(rootdir,'derived','spm','sub-phantom');
[~,~] = mkdir(outdir);

%-----------------------------------------------------------------------
% Job saved on 21-Mar-2025 16:22:31 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.util.imcalc.input = {fullfile(rootdir,'sub-phantom','anat','sub-phantom_acq-PDopt_echo-01_flip-1_mt-off_MPM.nii')};
matlabbatch{1}.spm.util.imcalc.output = 'mask';
matlabbatch{1}.spm.util.imcalc.outdir = {outdir};
matlabbatch{1}.spm.util.imcalc.expression = 'i1 > 100';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 0;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);