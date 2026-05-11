function [MLong_TI1, MLong_TI2, Msig1, Msig2] = mp2rage_blochsim(alpha1, alpha2, N_VFA1, N_VFA2, TI1, TI2, T1, T2, TE, TR, df, inc)
%MP2RAGE_BLOCHSIM Bloch simulation of the MP2RAGE sequence.
% params: Struct with the following fields:
%   alpha1: Flip angle (radians) for the first VFA block.
%   alpha2: Flip angle (radians) for the second VFA block.
%   N_VFA1: Number of excitations in the first VFA Block.
%   N_VFA2: Number of excitations in the second VFA Block.
%   TI1: Inversion time (ms) before the first VFA block.
%   TI2: Inversion time (ms) before the second VFA block.
%   T1: Longitudinal relaxation time (ms).
%   T2: Transverse relaxation time (ms).
%   TE: Echo time (ms).
%   TR: Repetition time (ms).
%   df: Off-resonance frequency of spins relative to excitation pulse (in Hz)
%   inc: Phase spoiling increment in degrees.
%
% Outputs:
%   MLong_TI1: Longitudinal magnetization (Mz) just before the first VFA block (at TI1).
%   MLong_TI2: Longitudinal magnetization (Mz) just before the second VFA block (at TI2).
%   Msig1: Complex transverse magnetization signal (Mxy) at each TE for the first VFA block.
%   Msig2: Complex transverse magnetization signal (Mxy) at each TE for the second VFA block.

%% Set up spin properties
Nf = 100;  % Number of spins simulated
M = [zeros(2,Nf); ones(1,Nf)]; % Initial magnetization [0;0;1]
on = ones(1,Nf); % Vector to ensure matrix size consistency

Rfph = 0;       % Rf phase
Rfinc = inc; 

MLong_TI1 = 0; % Stores Mz before first VFA block (at TI1).
MLong_TI2 = 0; % Stores Mz before second VFA block (at TI2).
Msig1 = zeros(1, N_VFA1); % Stores Mxy signals at each TE for first VFA block
Msig2 = zeros(1, N_VFA2); % Stores Mxy signals at each TE for second VFA block

%% Inversion Pulse
M = th_rot(pi, Rfph) * M; % Inversion Pulse
    
[Ati1, Bti1] = free_precess(TI1, T1, T2, df); % Decay/regrow until TI1
M = Ati1 * M + Bti1 * on;
MLong_TI1 = mean(M(3, :)); % Longitudinal magnetization just before first VFA Block
    
%% First VFA Block
for k = 1:N_VFA1 
    A = th_rot(alpha1, Rfph); % Alpha1 pulse

    [Ate, Bte] = free_precess(TE, T1, T2, df); % Decay/regrow until TE
    M = Ate * (A * M) + Bte * on;

    Msig1(1, k) = sum(squeeze(M(1,:)+1i*M(2,:))) / Nf; % Store transverse signal
    Rfph = Rfph + Rfinc; % RF phase increment

    [Ate, Bte] = free_precess(TE, T1, T2, df); % Decay/regrow until next Alpha1 pulse
    M = Ate * (A * M) + Bte * on;
end

%% Decay/regrow until second VFA Block
delay_TI2 = TI2 - TI1 - N_VFA1 * 2 * TE; % Time delay between the end of the first VFA Block and the start of the second VFA Block
if delay_TI2 > 0
    [Ati2, Bti2] = free_precess(delay_TI2, T1, T2, df);
    M = Ati2 * M + Bti2 * on;
end
MLong_TI2 = mean(M(3, :)); % Longitudinal magnetization just before second VFA Block

%% Second VFA Block
for k = 1:N_VFA2 
    A = th_rot(alpha2, Rfph); % Alpha2 pulse

    [Ate, Bte] = free_precess(TE, T1, T2, df); % Decay/regrow until TE
    M = Ate * (A * M) + Bte * on;

    Msig2(1, k) = sum(squeeze(M(1,:)+1i*M(2,:))) / Nf; % Store transverse signal
    Rfph = Rfph + Rfinc; % RF phase increment

    [Ate, Bte] = free_precess(TE, T1, T2, df); % Decay/regrow until next Alpha2 pulse
    M = Ate * (A * M) + Bte * on;
end

%% Decay/regrow until TR   
delay_TR = TR - TI2 - N_VFA2 * 2 * TE; % Time delay between the end of the second VFA Block and TR
if delay_TR > 0
    [Atr, Btr] = free_precess(delay_TR, T1, T2, df);
    M = Atr * M + Btr * on;
end

end
