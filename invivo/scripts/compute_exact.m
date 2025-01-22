rootdir = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(fileparts(rootdir),'scripts'))
inroot = fullfile(rootdir,'processed');

for sub=1:6
    for ses=1:2
        indir  = fullfile(inroot,"sub-"+sub,"ses-"+ses,"sa","Results","Supplementary");
        outdir = fullfile(inroot,"sub-"+sub,"ses-"+ses,"exact","Results");
        [~,~] = mkdir(outdir);

        PDw   = dir(fullfile(indir,"2017*_PDw_OLSfit_TEzero.nii"));
        T1w   = dir(fullfile(indir,"2017*_T1w_OLSfit_TEzero.nii"));
        B1map = dir(fullfile(indir,"s2017*_B1map.nii"));

        compute_A_R1(fullfile(PDw.folder,PDw.name),...
            fullfile(T1w.folder,T1w.name),...
            fullfile(B1map.folder,B1map.name),...
            outdir);
    end
end
