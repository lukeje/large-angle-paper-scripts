rootdir = fileparts(fileparts(mfilename('fullpath')));

% List of open inputs
% Make Directory: Parent Directory - cfg_files
% Image Calculator: Input Images - cfg_files
% Image Calculator: Expression - cfg_entry
% Named File Selector: File Set - cfg_files
nsub = 1;
nses = 1;
jobfile = {fullfile(rootdir,'scripts','compute_snr_job.m')};
jobs = repmat(jobfile, 1, nsub*nses);
inputs = cell(5, nsub*nses);
for sub = 1:nsub
    for ses = 1:nses
        rawdir  = fullfile(rootdir,'raw', 'nifti');
        procdir = fullfile(rootdir,'processed',sprintf('sub-%i',sub),sprintf('ses-%i',ses));
        mpmdir  = fullfile(procdir,'sa');
        
        inputs{1, sub+nsub*(ses-1)} = {fullfile(procdir)}; % Make Directory: Parent Directory - cfg_files

        PDw = cellstr(spm_select('FPList',spm_select('FPList',rawdir,'dir','pdw_kp_mtflash3d_v1g_0p3_0033'),'nii'));
        assert(size(PDw,1)==12)
        inputs{2, sub+nsub*(ses-1)} = PDw; % Named File Selector: File Set - cfg_files

        V = spm_vol(PDw);
        TE = nan(size(V));
        for v = 1:length(V)
            params = regexp(V{v}.descrip,'TR=(?<tr>.+)ms/TE=(?<te>.+)ms/FA=(?<fa>.+)deg','names');
            TE(v) = str2double(params.te);
        end

        PDw0 = cellstr(spm_select('FPList',spm_select('FPList',fullfile(mpmdir,'Results'),'dir','Supplementary'),'PDw_OLSfit_TEzero.nii'));
        assert(size(PDw0,1)==1)
        inputs{3, sub+nsub*(ses-1)} = PDw0; % Named File Selector: File Set - cfg_files
        ipdw0 = length(TE)+1;

        R2s = cellstr(spm_select('FPList',spm_select('FPList',mpmdir,'dir','Results'),'R2s_OLS.nii'));
        assert(size(R2s,1)==1)
        inputs{4, sub+nsub*(ses-1)} = R2s; % Named File Selector: File Set - cfg_files
        ir2s = length(TE)+2;

        expr = "sqrt((";
        for i =1:length(V)
            expr = expr+sprintf("+(i%i.*exp(-i%i*%d*1e-3)-i%i).^2",ipdw0,ir2s,TE(i),i);
        end
        expr = expr+sprintf(")/%i)",length(V));
        inputs{5, sub+nsub*(ses-1)} = char(expr); % Image Calculator: Expression - cfg_entry

    end
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
