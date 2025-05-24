rootdir = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(fileparts(rootdir),'scripts','external','qMRLab'))
startup;

indir = fullfile(rootdir,'sub-phantom','anat');
files = dir(fullfile(indir,'sub-phantom_inv-*_part-mag_IRT1.nii'));

outdir = fullfile(rootdir,'derived','qMRLab','sub-phantom','anat');
[~,~] = mkdir(outdir);

TI = zeros(length(files),1);
TR = zeros(length(files),1);
IRdata = [];
for n = 1:length(files)
    file = fullfile(files(n).folder,files(n).name);

    % image data
    info = niftiinfo(file);
    nii  = info.MultiplicativeScaling*double(niftiread(file)) + info.AdditiveOffset;
    IRdata = cat(4,IRdata,nii);

    % acquisition metadata
    json = jsondecode(fileread(strrep(file,'.nii','.json')));
    TI(n) = json.InversionTime*1e3; % ms
    TR(n) = json.RepetitionTime*1e3; % ms
end

% sort data so that qMRILab plotting works properly
[TI,ord] = sort(TI);
IRdata = IRdata(:,:,:,ord);

Model = inversion_recovery;
Model.Prot.IRData.Mat = TI;
assert(all(TR==TR(1)), "TR was not equal for all acquisitions!");
Model.Prot.TimingTable.Mat = TR(1);

data.IRData = double(IRdata);

% simple thresholding
m = max(IRdata,[],4);
T = 200;
data.Mask = m>T;

FitResults = FitData(data,Model,0);

qMRshowOutput(FitResults,data,Model);

FitResultsSave_nii(FitResults, fullfile(files(1).folder,files(1).name), outdir);

T1 = median(FitResults.T1(:),'omitmissing');
disp(T1)

R1 = 1e3/T1; % 1/s

save(fullfile(fileparts(rootdir),'figures','phantom_IR_R1est.txt'),'R1','-ascii')
