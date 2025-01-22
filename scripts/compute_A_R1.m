% Assumes all the images have already been registered and that each has an
% associated json file containing acquisition parameters in hMRI toolbox
% format. Requires the SPM and hMRI toolbox root folders to be on the path.

function compute_A_R1(PDwNii,T1wNii,B1mapNii,outfolder)

Vref = spm_vol(PDwNii);
PDw = spm_read_vols(Vref);
PDw_acq = spm_jsonread(spm_file(PDwNii, 'ext','.json'));
PDw_fa = deg2rad(PDw_acq.acqpar.FlipAngle);
TR = 1e-3*PDw_acq.acqpar.RepetitionTime;

T1w = spm_read_vols(spm_vol(T1wNii));
T1w_acq = spm_jsonread(spm_file(T1wNii, 'ext','.json'));
T1w_fa = deg2rad(T1w_acq.acqpar.FlipAngle);
assert(1e-3*T1w_acq.acqpar.RepetitionTime==TR, 'Repetition times must match!')

VB1 = spm_vol(B1mapNii);

dims = Vref.dim;
A  = zeros(size(PDw));
R1 = zeros(size(PDw));
parfor s = 1:dims(3)
    % uses sinc interpolation to match 7T value
    B1 = 0.01*hmri_read_vols(VB1, Vref, s, 3);

    A(:,:,s) = PDwT1w2A(...
        struct('data',PDw(:,:,s),'fa',PDw_fa),...
        struct('data',T1w(:,:,s),'fa',T1w_fa),...
        'exact', B1);

    R1(:,:,s) = PDwT1w2R1(...
        struct('data',PDw(:,:,s),'fa',PDw_fa),...
        struct('data',T1w(:,:,s),'fa',T1w_fa),...
        TR, 'exact', B1);
end

Vout = Vref;
Vout.dt(1) = spm_type('float32');

Vout.fname = char(fullfile(outfolder, 'R1.nii'));
Vout.descrip = 'R1 map (1 / s)';
spm_write_vol(Vout,R1);

Vout.fname = char(fullfile(outfolder, 'A.nii'));
Vout.descrip = 'unnormalised PD map (a.u.)';
spm_write_vol(Vout,A);

end
