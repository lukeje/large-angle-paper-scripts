%-----------------------------------------------------------------------
% Job saved on 23-Jan-2024 17:15:45 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = '<UNDEFINED>';
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = 'b1map';
matlabbatch{2}.spm.tools.hmri.create_B1.subj.output.outdir(1) = cfg_dep('Make Directory: Make Directory ''b1map''', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
matlabbatch{2}.spm.tools.hmri.create_B1.subj.b1_type.i3D_EPI.b1input = '<UNDEFINED>';
matlabbatch{2}.spm.tools.hmri.create_B1.subj.b1_type.i3D_EPI.b0input = '<UNDEFINED>';
matlabbatch{2}.spm.tools.hmri.create_B1.subj.b1_type.i3D_EPI.b1parameters.b1defaults = '<UNDEFINED>';
matlabbatch{2}.spm.tools.hmri.create_B1.subj.popup = false;
matlabbatch{3}.spm.util.imcalc.input = '<UNDEFINED>';
matlabbatch{3}.spm.util.imcalc.output = 'meanPDw.nii';
matlabbatch{3}.spm.util.imcalc.outdir(1) = cfg_dep('Make Directory: Make Directory ''b1map''', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
matlabbatch{3}.spm.util.imcalc.expression = 'mean(X)';
matlabbatch{3}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{3}.spm.util.imcalc.options.dmtx = 1;
matlabbatch{3}.spm.util.imcalc.options.mask = 0;
matlabbatch{3}.spm.util.imcalc.options.interp = 0;
matlabbatch{3}.spm.util.imcalc.options.dtype = 16;
matlabbatch{4}.spm.spatial.coreg.estimate.ref(1) = cfg_dep('Image Calculator: ImCalc Computed Image: meanPDw.nii', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
matlabbatch{4}.spm.spatial.coreg.estimate.source(1) = cfg_dep('Create B1 map: B1ref_subj1', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','subj', '()',{1}, '.','B1ref', '()',{':'}));
matlabbatch{4}.spm.spatial.coreg.estimate.other(1) = cfg_dep('Create B1 map: B1map_subj1', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','subj', '()',{1}, '.','B1map', '()',{':'}));
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
matlabbatch{5}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = '<UNDEFINED>';
matlabbatch{5}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = 'sa';
matlabbatch{6}.spm.tools.hmri.hmri_config.hmri_setdef.customised = '<UNDEFINED>';
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.output.outdir(1) = cfg_dep('Make Directory: Make Directory ''sa''', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.sensitivity.RF_none = '-';
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.b1_type.pre_processed_B1.b1input(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.b1_type.pre_processed_B1.scafac = 1;
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.b1_type.pre_processed_B1.b1parameters.b1metadata = 'yes';
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.raw_mpm.MT = '';
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.raw_mpm.PD = '<UNDEFINED>';
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.raw_mpm.T1 = '<UNDEFINED>';
matlabbatch{7}.spm.tools.hmri.create_mpm.subj.popup = false;
matlabbatch{8}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = '<UNDEFINED>';
matlabbatch{8}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = 'nosa';
matlabbatch{9}.spm.tools.hmri.hmri_config.hmri_setdef.customised = '<UNDEFINED>';
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.output.outdir(1) = cfg_dep('Make Directory: Make Directory ''nosa''', substruct('.','val', '{}',{8}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.sensitivity.RF_none = '-';
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.b1_type.pre_processed_B1.b1input(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.b1_type.pre_processed_B1.scafac = 1;
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.b1_type.pre_processed_B1.b1parameters.b1metadata = 'yes';
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.raw_mpm.MT = '';
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.raw_mpm.PD = '<UNDEFINED>';
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.raw_mpm.T1 = '<UNDEFINED>';
matlabbatch{10}.spm.tools.hmri.create_mpm.subj.popup = false;
