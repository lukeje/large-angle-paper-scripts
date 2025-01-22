addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'scripts'))
rootdir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'processed');

for sub=1:1
    for ses=1:1
        indir  = fullfile(rootdir,"sub-"+sub,"ses-"+ses,"sa","Results","Supplementary");
        outdir = fullfile(rootdir,"sub-"+sub,"ses-"+ses,"exact","Results");
        [~,~] = mkdir(outdir);

        PDw   = dir(fullfile(indir,"*_PDw_OLSfit_TEzero.nii"));
        T1w   = dir(fullfile(indir,"*_T1w_OLSfit_TEzero.nii"));
        B1map = dir(fullfile(indir,"*_B1map.nii"));

        compute_A_R1(fullfile(PDw.folder,PDw.name),...
            fullfile(T1w.folder,T1w.name),...
            fullfile(B1map.folder,B1map.name),...
            outdir);
    end
end