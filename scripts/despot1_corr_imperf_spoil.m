% Simulation of coefficients to correct T1 for imperfect spoiling
% in the PVP phantom DESPOT1 T1 measurement from
%   Pierpaoli et al. (2009) Proc. Intl. Soc. Mag. Reson. Med.
%   https://archive.ismrm.org/2009/1414.html
% Adapts the approach from
%   Preibisch and Deichmann (2009) Magn. Reson. Med. 
%   https://doi.org/10.1002/mrm.21776
% as implemented in the hMRI toolbox 
% (https://github.com/hMRI-group/hMRI-toolbox/blob/master/hmri_corr_imperf_spoil.m)

% We need to add the hMRI toolbox and EPG-X to the path
addpath(fullfile(fileparts(mfilename('fullpath')),'external','hMRI-toolbox'))
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'external','hMRI-toolbox','EPG_for_hmri_tbx')))

fprintf('\t--- Calculating Imperfect Spoiling Correction Coefficients ---\n');
%% ***********************************************%%
% 1./ Numerical simulations with EPG
%*************************************************%%
%%
% Get sequence parameters
FA      =   [30 19 10 2]; % Flip angles [deg]
TR      =   8.1;          % [ms]
Phi0    =   115.4;        % [deg]; GE default value (https://github.com/pulseq/pulseq/discussions/55#discussioncomment-10796364)
B1range =   0.7:0.1:1.3;  % such that 100% = 1

Gamp    =   40;    % [mT/m]; assume max used
px      = 1e-3;    % m; assume 1 mm voxels
spperpx = 2*pi;    % assume only 2*pi per pixel of spoiling
gamma   = 267.522; % rad/(ms mT)
Gdur    = spperpx/(px*gamma*Gamp); % ms

assert(length(Gdur) == length(Gamp), 'The vectors of gradient durations and amplitudes must have the same length!')
assert(all(sum(Gdur)<=TR), 'The total duration of the gradients cannot exceed TR!')

%% Get tissue parameters
T1range     = [800, 1000, 1200]; % [ms]
T2range     = 250;               % [ms]
D           = 0.8;               % [um^2/ms]

%% Build structure "diff" to account for diffusion effect
% Note we include any deadtime during each TR so that diffusion effects
% are calculated correctly
diff     = struct();
diff.D   = D*1e-9;
diff.G   = [Gamp(:);0];
diff.tau = [Gdur(:);TR-sum(Gdur)];

%% Run EPG simulation
nT1 = length(T1range);
nT2 = length(T2range);
nB1 = length(B1range);
nFA = length(FA);
S = zeros([nFA nT1 nT2 nB1]);
fprintf('\t-------- Simulating signals\n');
for T1val = 1:nT1 % loop over T1 values, can use parfor for speed

    T1 = T1range(T1val);
    npulse = floor(15*T1/min(TR));   % To ensure steady state signal

    for T2val = 1:nT2
        T2 = T2range(T2val);

        for B1val = 1:nB1  % loop over B1+ values
            B1eff = B1range(B1val);

            %%% make train of flip angles and their phases
            phi_train = RF_phase_cycle(npulse,Phi0); % phase of the RF pulses

            % Calculate signals via EPG:
            for n = 1:nFA
                alpha_train = d2r(FA(n).*B1eff)*ones([1 npulse]);
                F0 = EPG_GRE(alpha_train, phi_train, TR(1), T1, T2, 'diff', diff);
                S(n,T1val,T2val,B1val) = abs(F0(end));
            end
        end
    end
end


%% ***********************************************%%
% 2./ Fitting T1=A(B1eff)+B(B1eff)*T1app
%*************************************************%%
fprintf('\t-------- Determining Coefficients\n');
ABcoeff = zeros(2, nB1);
T1app = zeros(nB1, nT1, nT2);
for B1val = 1 : nB1

    B1eff = B1range(B1val);

    % Calculate DESPOT1 T1app following
    %   Deoni (2007), J. Magn. Reson. Imaging.
    %   https://doi.org/10.1002/jmri.21130
    for T1val = 1:nT1
        for T2val = 1:nT2
            y = S(:,T1val,T2val,B1val)./sind(B1eff*FA(:));
            x = [S(:,T1val,T2val,B1val)./tand(B1eff*FA(:)),ones(length(FA),1)];
            b = x\y;
            T1app(B1val,T1val,T2val) = -TR/log(b(1));
        end
    end

    % build matrix X with column of ones and column of T1app
    X = ones([nT1*nT2 2]);
    X(:,2) = T1app(B1val,:);
    ABcoeff(:, B1val) = pinv(X)*repmat(T1range, [1 nT2]).';

end

polyCoeffA = polyfit(B1range, ABcoeff(1,:), 2) %#ok<NOPTS>
polyCoeffB = polyfit(B1range, ABcoeff(2,:), 2) %#ok<NOPTS>


%% *********************************************************%%
% 4./ Compute RMSE on T1app and T1
%***********************************************************%%
fprintf('\t-------- Calculating errors\n');
T1app = T1app(:,:);
T1_App_Err = (T1app - repmat(T1range, [nB1 nT2]))./repmat(T1range, [nB1 nT2])*100;
RMSE_App  = sqrt(mean(T1_App_Err(:).^2)) %#ok<NOPTS>

T1corr = repmat(polyval(polyCoeffA, B1range).',[1 nT1*nT2])+ repmat(polyval(polyCoeffB, B1range).',[1 nT1*nT2]).*T1app;
T1_Corr_Err = (T1corr - repmat(T1range, [nB1 nT2]))./repmat(T1range, [nB1 nT2])*100;
RMSE_Corr = sqrt(mean(T1_Corr_Err(:).^2)) %#ok<NOPTS>

fprintf('\t-------- Testing one example\n');
fT = 1;
R1est = 1 %#ok<NOPTS> 1/s
R1corr = R1est/(sum(polyCoeffA.*fT.^(2:-1:0))*1e-3*R1est+sum(polyCoeffB)) %#ok<NOPTS>
