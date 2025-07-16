%-----------------------------------------------------------------------
% Job saved on 04-Apr-2025 09:58:46 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = '<UNDEFINED>';
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = 'pdw_snr';
matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'PDw';
matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {'<UNDEFINED>'};
matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'PDw0';
matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {'<UNDEFINED>'};
matlabbatch{4}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'R2star';
matlabbatch{4}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {'<UNDEFINED>'};
matlabbatch{5}.spm.util.imcalc.input(1) = cfg_dep('Named File Selector: PDw(1) - Files', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{5}.spm.util.imcalc.input(2) = cfg_dep('Named File Selector: PDw0(1) - Files', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{5}.spm.util.imcalc.input(3) = cfg_dep('Named File Selector: R2star(1) - Files', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{5}.spm.util.imcalc.output = 'sigma_PDw';
matlabbatch{5}.spm.util.imcalc.outdir(1) = cfg_dep('Make Directory: Make Directory ''PDwSNR''', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
matlabbatch{5}.spm.util.imcalc.expression = '<UNDEFINED>';
matlabbatch{5}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{5}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{5}.spm.util.imcalc.options.mask = 0;
matlabbatch{5}.spm.util.imcalc.options.interp = 0;
matlabbatch{5}.spm.util.imcalc.options.dtype = 16;
matlabbatch{6}.spm.util.imcalc.input(1) = cfg_dep('Named File Selector: PDw0(1) - Files', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{6}.spm.util.imcalc.input(2) = cfg_dep('Image Calculator: ImCalc Computed Image: sigma_PDw', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
matlabbatch{6}.spm.util.imcalc.output = 'PDw0SNR';
matlabbatch{6}.spm.util.imcalc.outdir(1) = cfg_dep('Make Directory: Make Directory ''PDwSNR''', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
matlabbatch{6}.spm.util.imcalc.expression = 'i1./i2';
matlabbatch{6}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{6}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{6}.spm.util.imcalc.options.mask = 0;
matlabbatch{6}.spm.util.imcalc.options.interp = 0;
matlabbatch{6}.spm.util.imcalc.options.dtype = 16;
